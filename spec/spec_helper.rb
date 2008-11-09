require File.dirname(__FILE__) + '/../lib/couchrest'

FIXTURE_PATH = File.dirname(__FILE__) + '/fixtures'

COUCHHOST = "http://localhost:5984"
TESTDB = 'couchrest-test'

def reset_test_db!
  cr = CouchRest.new(COUCHHOST)
  db = cr.database(TESTDB)
  db.delete! rescue nil
  db = cr.create_db(TESTDB) rescue nin
  db
end