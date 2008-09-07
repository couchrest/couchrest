require File.dirname(__FILE__) + '/spec_helper'

describe CouchRest do

  before(:each) do
    @cr = CouchRest.new(COUCHHOST)
    begin
      @db = @cr.database(TESTDB)
      @db.delete! rescue nil      
    end
  end

  after(:each) do
    begin
      @db.delete! rescue nil
    end
  end

  describe "getting info" do
    it "should list databases" do
      @cr.databases.should be_an_instance_of(Array)
    end
    it "should get info" do
      @cr.info["couchdb"].should == "Welcome"
      @cr.info.class.should == Hash   
    end
  end
  
  describe "description" do
    it "should restart" do
      @cr.restart!
    end
  end

  describe "initializing a database" do
    it "should return a db" do
      db = @cr.database(TESTDB)
      db.should be_an_instance_of(CouchRest::Database)
      db.host.should == @cr.uri
    end
  end

  describe "easy initializing a database adapter" do
    it "should be possible without an explicit CouchRest instantiation" do
      db = CouchRest.database "http://localhost:5984/couchrest-test"
      db.should be_an_instance_of(CouchRest::Database)
      db.host.should == "http://localhost:5984"
    end
    it "should not create the database automatically" do
      db = CouchRest.database "http://localhost:5984/couchrest-test"
      lambda{db.info}.should raise_error(RestClient::ResourceNotFound)      
    end
  end

  describe "ensuring the db exists" do
    it "should be super easy" do
      db = CouchRest.database! "http://localhost:5984/couchrest-test-2"
      db.info["db_name"].should == 'couchrest-test-2'
    end
  end

  describe "successfully creating a database" do
    it "should start without a database" do
      @cr.databases.should_not include(TESTDB)
    end
    it "should return the created database" do
      db = @cr.create_db(TESTDB)
      db.should be_an_instance_of(CouchRest::Database)
    end
    it "should create the database" do
      db = @cr.create_db(TESTDB)
      @cr.databases.should include(TESTDB)
    end
  end

  describe "failing to create a database because the name is taken" do
    before(:each) do
      db = @cr.create_db(TESTDB)
    end
    it "should start with the test database" do
      @cr.databases.should include(TESTDB)
    end
    it "should PUT the database and raise an error" do
      lambda{
        @cr.create_db(TESTDB)
      }.should raise_error(RestClient::Request::RequestFailed)
    end
  end

end