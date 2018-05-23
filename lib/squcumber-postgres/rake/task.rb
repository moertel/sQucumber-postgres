require 'cucumber'
require 'cucumber/rake/task'
require 'rake'

module Squcumber
  module Postgres
    module Rake
      class Task
        include ::Rake::DSL if defined? ::Rake::DSL

        def install_tasks
          namespace :test do
            # Auto-generate Rake tasks for each feature and each of their parent directories
            @features_dir = File.join(FileUtils.pwd, 'features')
            features = Dir.glob("#{@features_dir}/**/*.feature")
            parent_directories = features.map { |f| f.split('/')[0..-2].join('/') }.uniq
            features.each do |feature|
              feature_name = feature.gsub(@features_dir + '/', '').gsub('.feature', '')
              task_name = feature_name.gsub('/', ':')
              desc "Run SQL tests for feature #{feature_name}"
              task "sql:#{task_name}".to_sym, [:scenario_line_number] do |_, args|
                cucumber_task_name = "cucumber_#{task_name}".to_sym
                ::Cucumber::Rake::Task.new(cucumber_task_name) do |t|
                  line_number = args[:scenario_line_number].nil? ? '' : ":#{args[:scenario_line_number]}"
                  output_dir = ENV['CUSTOM_OUTPUT_DIR'] ? ENV['CUSTOM_OUTPUT_DIR'] : '/tmp'
                  output_file = output_dir + '/' + feature_name.gsub('/', '_')
                  output_opts = "--format html --out #{output_file}.html --format json --out #{output_file}.json"
                  t.cucumber_opts = "#{feature}#{line_number} --format pretty #{output_opts} --require #{File.dirname(__FILE__)}/../support --require #{File.dirname(__FILE__)}/../step_definitions #{ENV['CUSTOM_STEPS_DIR'] ? '--require ' + ENV['CUSTOM_STEPS_DIR'] : ''}"
                end
                ::Rake::Task[cucumber_task_name].execute
              end
            end

            parent_directories.each do |feature|
              feature_name = feature.gsub(@features_dir + '/', '')
              task_name = feature_name.gsub('/', ':')
              if feature_name.eql?(@features_dir)
                feature_name = 'features'
                task_name = 'all'
              end
              desc "Run SQL tests for all features in /#{feature_name}"
              task "sql:#{task_name}".to_sym do
                cucumber_task_name = "cucumber_#{task_name}".to_sym
                ::Cucumber::Rake::Task.new(cucumber_task_name) do |t|
                  t.cucumber_opts = "#{feature} --format pretty #{output_opts} --require #{File.dirname(__FILE__)}/../support --require #{File.dirname(__FILE__)}/../step_definitions #{ENV['CUSTOM_STEPS_DIR'] ? '--require ' + ENV['CUSTOM_STEPS_DIR'] : ''}"
                end
                ::Rake::Task[cucumber_task_name].execute
              end
            end
          end
        end
      end
    end
  end
end

Squcumber::Postgres::Rake::Task.new.install_tasks
