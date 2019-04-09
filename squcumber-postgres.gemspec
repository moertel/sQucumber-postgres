Gem::Specification.new do |s|
  s.name               = 'squcumber-postgres'
  s.version            = '0.0.11'
  s.default_executable = 'squcumber-postgres'

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.0'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Stefanie Grunwald']
  s.date = %q{2019-04-09}
  s.email = %q{steffi@physics.org}
  s.files = [
    'Rakefile',
    'lib/squcumber-postgres.rb',
    'lib/squcumber-postgres/mock/database.rb',
    'lib/squcumber-postgres/step_definitions/common_steps.rb',
    'lib/squcumber-postgres/support/database.rb',
    'lib/squcumber-postgres/support/matchers.rb',
    'lib/squcumber-postgres/support/helpers.rb',
    'lib/squcumber-postgres/support/output.rb',
    'lib/squcumber-postgres/rake/task.rb'
  ]
  s.test_files = [
    'spec/spec_helper.rb',
    'spec/squcumber-postgres/mock/database_spec.rb'
  ]
  s.homepage = %q{https://github.com/moertel/sQucumber-postgres}
  s.require_paths = ['lib']
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Define and execute SQL integration tests for Postgres databases}

  s.add_runtime_dependency 'pg', ['>= 0.16', '< 1.0']
  s.add_runtime_dependency 'cucumber', ['>= 2.0', '< 3.0']
  s.add_runtime_dependency 'rake', ['>= 10.1', '< 12.0']

  s.add_development_dependency 'rspec', ['>= 3.1', '< 4.0']
  s.add_development_dependency 'rspec-collection_matchers', ['>= 1.1.2', '< 2.0']
  s.add_development_dependency 'codeclimate-test-reporter', ['>= 0.4.3', '< 1.0']

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.0.0') then
    else
    end
  else
  end
end
