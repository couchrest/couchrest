require "rubygems"
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

# set the following global variable to test couchrest
# using different http lib.
HTTP_LAYER = (ENV['HTTP_LIB'] || 'RestClient') unless Object.const_defined?(:HTTP_LAYER)

require File.join(File.dirname(__FILE__), '..','lib','couchrest')
::HttpAbstraction.use_adapter(HTTP_LAYER)

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  COUCHHOST = "http://127.0.0.1:5984"
  TESTDB    = 'couchrest-test'
  TEST_SERVER    = CouchRest.new
  TEST_SERVER.default_database = TESTDB
  DB = TEST_SERVER.database(TESTDB)
  DB.compact!
end

class Basic < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
end

def reset_test_db!
  DB.recreate! rescue nil
  DB
end

Spec::Runner.configure do |config|
  config.before(:all) { reset_test_db!}
  
  # config.after(:all) do
  #   cr = TEST_SERVER
  #   test_dbs = cr.databases.select { |db| db =~ /^#{TESTDB}/ }
  #   test_dbs.each do |db|
  #     cr.database(db).delete! rescue nil
  #   end
  # end  
end