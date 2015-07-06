require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Server do
  
  describe "available databases" do
    before(:each) do
      @couch = CouchRest::Server.new COUCHHOST
    end

    after(:each) do
      @couch.available_databases.each do |ref, db|
        db.delete!
      end
    end
    
    it "should let you add more databases" do
      expect(@couch.available_databases).to be_empty
      @couch.define_available_database(:default, "cr-server-test-db")
      expect(@couch.available_databases.keys).to include(:default)
    end
    
    it "should verify that a database is available" do
      @couch.define_available_database(:default, "cr-server-test-db")
      expect(@couch.available_database?(:default)).to be_true
      expect(@couch.available_database?("cr-server-test-db")).to be_true
      expect(@couch.available_database?(:matt)).to be_false
    end
    
    it "should let you set a default database" do
      @couch.default_database = 'cr-server-test-default-db'
      expect(@couch.available_database?(:default)).to be_true
    end
  end
  
end
