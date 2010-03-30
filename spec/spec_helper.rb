require "rubygems"
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

require File.join(File.dirname(__FILE__), '..','lib','couchrest')
# check the following file to see how to use the spec'd features.

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  COUCHHOST = "http://127.0.0.1:5984"
  TESTDB    = 'couchrest-test'
  REPLICATIONDB = 'couchrest-test-replication'
  TEST_SERVER    = CouchRest.new
  TEST_SERVER.default_database = TESTDB
  DB = TEST_SERVER.database(TESTDB)
end

class Basic < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
end

def reset_test_db!
  DB.recreate! rescue nil 
  DB
end

Spec::Runner.configure do |config|
  config.before(:all) { reset_test_db! }
  
  config.after(:all) do
    cr = TEST_SERVER
    test_dbs = cr.databases.select { |db| db =~ /^#{TESTDB}/ }
    test_dbs.each do |db|
      cr.database(db).delete! rescue nil
    end
  end
end

def couchdb_lucene_available?
  lucene_path = "http://localhost:5985/"
  url = URI.parse(lucene_path)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  true
 rescue Exception => e
  false
end

