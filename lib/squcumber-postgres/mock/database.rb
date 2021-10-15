require 'pg'

module Squcumber
  module Postgres
    module Mock
      class Database
        DELETE_DB_WHEN_FINISHED = ENV['KEEP_TEST_DB'].to_i == 1 ? false : true
        TEST_DB_NAME_OVERRIDE = ENV.fetch('TEST_DB_NAME_OVERRIDE', '')

        def initialize(production_database)
          @production_database = production_database or raise ArgumentError, 'No production database provided'

          test_db_name_postfix = TEST_DB_NAME_OVERRIDE.empty? ? rand(10000..99999) : TEST_DB_NAME_OVERRIDE
          @test_db_name = "test_env_#{test_db_name_postfix}"

          if @production_database.exec("select datname from pg_database where datname like '%#{@test_db_name}%'").num_tuples != 0
            @production_database.exec("drop database #{@test_db_name}")
          end
          @production_database.exec("create database #{@test_db_name}")

          @testing_database = PG.connect(
            host: ENV['DB_HOST'],
            port: ENV['DB_PORT'],
            dbname: @test_db_name,
            user: ENV['DB_USER'],
            password: ENV['DB_PASSWORD']
          )
        end

        def setup(schemas)
          schemas.each do |schema|
            exec("drop schema if exists #{schema} cascade")
            exec("create schema #{schema}")
          end
        end

        def truncate_all_tables
          @testing_database
            .exec("select schemaname || '.' || tablename as schema_and_table from pg_tables where tableowner = '#{ENV['DB_USER']}' and schemaname not in ('pg_catalog', 'information_schema')")
            .map { |row| row['schema_and_table'] }
            .each { |schema_and_table| exec("truncate table #{schema_and_table}") }
        end

        def exec(statement)
          @testing_database.exec(statement)
        end
        alias_method :query, :exec

        def exec_file(path)
          exec(File.read("#{path}"))
        end
        alias_method :query_file, :exec_file

        # Redshift does not allow to copy a table schema to another database, i.e.
        # `create table some_db.some_table (like another_db.some_table)` cannot be used.
        def copy_table_def_from_prod(schema, table)
          create_table_statement = _get_create_table_statement(schema, table)
          exec(create_table_statement)
        end

        def copy_table_defs_from_prod(tables)
          tables.each do |obj|
            obj.each { |schema, table| copy_table_def_from_prod(schema, table) }
          end
        end

        def mock(mock)
          mock.each do |schema_and_table, data|
            raise "Mock data for #{schema_and_table} is not correctly formatted: must be Array but was #{data.class}" unless data.is_a?(Array)
            data.each { |datum| insert_mock_values(schema_and_table, datum) }
          end
        end

        def insert_mock_values(schema_and_table, mock)
          schema, table = schema_and_table.split('.')
          keys = []
          vals = []
          mock.each do |key, value|
            unless value.nil?
              keys << key
              vals << (value.is_a?(String) ? "'#{value}'" : value)
            end
          end
          exec("insert into #{schema}.#{table} (#{keys.join(',')}) values (#{vals.join(',')})") unless vals.empty?
        end

        def destroy
          @testing_database.close()

          if DELETE_DB_WHEN_FINISHED
            attempts = 0
            begin
              attempts += 1
              @production_database.exec("drop database #{@test_db_name}")
            rescue PG::ObjectInUse
              sleep 5
              retry unless attempts >= 3
            end
          else
            puts "\nTest database has been kept alive: #{@test_db_name}"
          end

          @production_database.close()
        end

        private

        def _get_create_table_statement(schema, table)
          @production_database.exec("set search_path to '$user', #{schema};")
          table_schema = @production_database.query("select * from information_schema.columns where table_schema = '#{schema}' and table_name = '#{table}';")
          raise "Sorry, there is no table information for #{schema}.#{table}" if table_schema.num_tuples == 0

          definitions = _get_column_definitions(table_schema).join(',')

          "create table if not exists #{schema}.#{table} (#{definitions});"
        end

        def _get_column_definitions(table_definition)
          table_definition.map do |definition|
            schema_column_type = ''
            is_array = false
            if definition['data_type'].eql?('ARRAY')
                is_array = true
                schema_column_type = definition['udt_name'].gsub(/^\_/, '')
            else
                schema_column_type = definition['data_type']
            end

            # Deal with (var)chars
            if definition['character_maximum_length']
                schema_column_type = schema_column_type + "(#{definition['character_maximum_length'].to_s})"
            end

            # Deal with decimals
            if definition['udt_name'].eql?('numeric') and definition['numeric_precision'] and definition['numeric_scale']
                schema_column_type = schema_column_type + "(#{definition['numeric_precision'].to_s},#{definition['numeric_scale'].to_s})"
            end

            # Deal with arrays
            if is_array
                schema_column_type = schema_column_type + '[]'
            end

            "#{definition['column_name']} #{schema_column_type} default null"
          end
        end
      end
    end
  end
end
