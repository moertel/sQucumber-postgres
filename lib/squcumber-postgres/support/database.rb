require_relative '../mock/database'

print 'Connect to production database...'
production_database = PG.connect(
  host: ENV['DB_HOST'],
  port: ENV['DB_PORT'],
  dbname: ENV['DB_NAME'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASSWORD']
)
puts 'DONE.'

TESTING_DATABASE ||= Squcumber::Postgres::Mock::Database.new(production_database)

at_exit do
  TESTING_DATABASE.destroy rescue nil
end
