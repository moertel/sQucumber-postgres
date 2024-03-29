require 'json'

$feature_name ||= ''
$setup ||= false

Before do |scenario|
  current_scenario_name = scenario.feature.name rescue nil
  if current_scenario_name != $feature_name
    $feature_name = current_scenario_name
    $setup = false
  end
end

# Takes a path and then sequentially adds what's provided in `data`
# to be later executed in the step `the given SQL files are executed`
# +path+:: relative to root of project, e.g. "jobs/kpi/sales"
Given(/^the SQL files in the path "?([^"]*)"?:$/) do |path, data|
  @sql_file_path = path
  @sql_files_to_execute = data.hashes.map { |e| "#{@sql_file_path}/#{e['file']}" }
end

Given(/^the SQL file path "?([^\s"]+)"?$/) do |path|
  @sql_file_path = path
end

Given(/^Pending: (.*)/) { |reason| pending(reason) }

Given(/^their schema dependencies:$/) do |data|
  unless $setup
    schemas = data.hashes.map { |hash| hash['schema'] }.compact.uniq
    TESTING_DATABASE.setup(schemas)
  end
end

Given(/^their table dependencies:$/) do |data|
  if $setup
    silence_streams(STDERR) do
      TESTING_DATABASE.truncate_all_tables()
    end
  else
    tables = []
    schemas = []
    data.hashes.each do |hash|
      schema, table = hash['table'].split('.')
      schemas << schema
      tables << { schema => table }
    end
    silence_streams(STDERR) do
      TESTING_DATABASE.setup(schemas.compact.uniq)
      TESTING_DATABASE.copy_table_defs_from_prod(tables)
    end
    $setup = true
  end
end

Given(/^the following defaults for "?([^\s"]+)"? \(if not stated otherwise\):$/) do |table, data|
  @defaults ||= {}
  @defaults[table] = data.hashes[0]
end

Given(/^"([^\s"]+)" as null value$/) do |null_placeholder|
  @null ||= null_placeholder
end

Given(/a clean environment/) do
  silence_streams(STDERR) do
    TESTING_DATABASE.truncate_all_tables()
  end
end

Given(/^the existing table "?([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)"?( with date placeholders)?:$/) do |schema, table, placeholder, data|
  mock_data = data.hashes
  @defaults ||= {}
  defaults = @defaults["#{schema}.#{table}"]

  unless defaults.nil? or defaults.empty?
    mock_data.map! { |entry| defaults.merge(entry) }
  end

  mock_data = convert_mock_values(mock_data) if placeholder
  mock_data = convert_null_values(mock_data, @null) if @null

  TESTING_DATABASE.mock(
    Hash["#{schema}.#{table}", mock_data]
  )
end

When(/^the given SQL files are executed$/) do
  silence_streams(STDERR) do
    @sql_files_to_execute.each do |file|
      # This overwrites the result if multiple files are executed
      @result = TESTING_DATABASE.exec_file(file).map { |e| e }
    end
  end
end

When(/^the SQL file "?([^\s"]+)"? is executed/) do |file|
  silence_streams(STDERR) do
    # This overwrites the result if multiple files are executed
    @result = TESTING_DATABASE.exec_file("#{@sql_file_path}/#{file}").map { |e| e }
  end
end

When(/^the resulting table "?([^\s"]*)"? is queried(?:, ordered by "?([^"]*)"?)?/) do |table, sort_column|
  sort_statement = (sort_column.nil? or sort_column.empty?) ? '' : "order by #{sort_column}"
  @result = TESTING_DATABASE.query("select * from #{table} #{sort_statement};").map { |e| e }
end

When(/^the result is ordered by "?([^"]+)"?/) do |sort_columns_string|
  sort_columns = sort_columns_string.split(',').map { |sort_column| sort_column.strip }
  @result = @result.sort_by do |row|
    sort_columns.map { |sort_column| row[sort_column] }
  end
end

Then(/^the result( with date placeholders)? starts with.*$/) do |placeholder, data|
  actual = @result[0..(data.hashes.length - 1)] || []
  expected = data.hashes || []
  expected = convert_mock_values(expected) if placeholder
  expected = convert_null_values(expected, @null) if @null

  sanity_check_result(actual, expected)

  expected.each_with_index do |hash, i|
    raise("Does not start with expected result, got:\n#{format_error(data, actual)}") unless actual[i].all? do |key, value|
      values_match(value, hash[key], null=@null) # actual,expected
    end
  end
end

Then(/^the result( with date placeholders)? includes.*$/) do |placeholder, data|
  actual = @result || []
  expected = data.hashes || []
  expected = convert_mock_values(expected) if placeholder
  expected = convert_null_values(expected, @null) if @null

  sanity_check_result(actual, expected)

  expected.each do |hash|
    raise("Result is not included, got:\n#{format_error(data, actual)}") unless actual.any? do |row|
      row.all? do |key, value|
        values_match(value, hash[key], null=@null) # actual, expected
      end
    end
  end
end

Then(/^the result( with date placeholders)? does not include.*$/) do |placeholder, data|
  actual = @result || []
  expected = data.hashes || []
  expected = convert_mock_values(expected) if placeholder
  expected = convert_null_values(expected, @null) if @null

  sanity_check_result(actual, expected)

  expected.each do |hash|
    raise("Result is included, got:\n#{format_error(data, actual)}") if actual.any? do |row|
      row.all? do |key, value|
        values_match(value, hash[key], null=@null) # actual,expected
      end
    end
  end
end

Then(/^the result( with date placeholders)? exactly matches.*$/) do |placeholder, data|
  actual = @result || []
  expected = data.hashes || []
  expected = convert_mock_values(expected) if placeholder
  expected = convert_null_values(expected, @null) if @null

  sanity_check_result(actual, expected)

  raise("Does not match exactly, got:\n#{format_error(data, actual)}") if actual.length != expected.length

  actual.each_with_index do |row, i|
    raise("Does not match exactly, got:\n#{format_error(data, actual)}") unless (expected[i] || {}).all? do |key, value|
      values_match(row[key], value, null=@null) # actual,expected
    end
  end

  expected.each_with_index do |hash, i|
    raise("Does not match exactly, got:\n#{format_error(data, actual)}") unless (actual[i] || {}).all? do |key, value|
      values_match(value, hash[key], null=@null) # actual,expected
    end
  end
end

Then(/^the result is empty.*$/) do
  actual = @result || []
  raise("Result is not empty, got:\n#{format_error({}, actual)}") unless actual.length == 0
end
