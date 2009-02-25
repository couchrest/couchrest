require "rubygems"
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

require File.join(File.dirname(__FILE__), '..','lib','couchrest')
# check the following file to see how to use the spec'd features.

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  COUCHHOST = "http://127.0.0.1:5984"
  TESTDB    = 'couchrest-test'
  TEST_SERVER    = CouchRest.new
  TEST_SERVER.default_database = TESTDB
end

class Basic < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
end

def reset_test_db!
  cr = TEST_SERVER
  db = cr.database(TESTDB)
  db.recreate! rescue nil
  db
end