require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Server do
  
  describe "available databases" do
    before(:each) do
      @couch = CouchRest::Server.new
    end

    after(:each) do
      @couch.available_databases.each do |ref, db|
        db.delete!
      end
    end
    
    it "should let you add more databases" do
      @couch.available_databases.should be_empty
      @couch.define_available_database(:default, "cr-server-test-db")
      @couch.available_databases.keys.should include(:default)
    end
    
    it "should verify that a database is available" do
      @couch.define_available_database(:default, "cr-server-test-db")
      @couch.available_database?(:default).should be_true
      @couch.available_database?("cr-server-test-db").should be_true
      @couch.available_database?(:matt).should be_false
    end
    
    it "should let you set a default database" do
      @couch.default_database = 'cr-server-test-default-db'
      @couch.available_database?(:default).should be_true
    end
  end
  
end