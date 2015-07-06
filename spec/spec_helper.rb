require "bundler/setup"
require "rubygems"
require "rspec"

require File.join(File.dirname(__FILE__), '..','lib','couchrest')
# check the following file to see how to use the spec'd features.

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  COUCHHOST = ENV['COUCHHOST'] || "http://127.0.0.1:5984"
  TESTDB    = 'couchrest-test'
  REPLICATIONDB = 'couchrest-test-replication'
  TEST_SERVER    = CouchRest.new COUCHHOST
  TEST_SERVER.default_database = TESTDB
  DB = TEST_SERVER.database(TESTDB)
end

def reset_test_db!
  DB.recreate! rescue nil 
  DB
end

RSpec.configure do |config|
  config.before(:all) { reset_test_db! }
  
  config.after(:all) do
    cr = TEST_SERVER
    test_dbs = cr.databases.select { |db| db =~ /^#{TESTDB}/ }
    test_dbs.each do |db|
      cr.database(db).delete! rescue nil
    end
  end
end

# Check if lucene server is running on port 5985 (not 5984)
def couchdb_lucene_available?
  url = URI "http://localhost:5985/"
  req = Net::HTTP::Get.new(url.path)
  Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  true
 rescue Exception
  false
end

