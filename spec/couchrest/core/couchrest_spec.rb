require File.expand_path("../../../spec_helper", __FILE__)

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
  
  it "should restart" do
    @cr.restart!
  end

  it "should provide one-time access to uuids" do
    @cr.next_uuid.should_not be_nil
  end

  describe "initializing a database" do
    it "should return a db" do
      db = @cr.database(TESTDB)
      db.should be_an_instance_of(CouchRest::Database)
      db.host.should == @cr.uri
    end
  end

  describe "parsing urls" do
    it "should parse just a dbname" do
      db = CouchRest.parse "my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5984"
    end
    it "should parse a host and db" do
      db = CouchRest.parse "127.0.0.1/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1"
    end
    it "should parse a host and db with http" do
      db = CouchRest.parse "https://127.0.0.1/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1"
    end
    it "should parse a host with a port and db" do
      db = CouchRest.parse "127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse a host with a port and db with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse a host with a port and db with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host" do
      db = CouchRest.parse "http://127.0.0.1:5555/"
      db[:database].should be_nil
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/"
      db[:database].should be_nil
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host no slash" do
      db = CouchRest.parse "http://127.0.0.1:5555"
      db[:host].should == "127.0.0.1:5555"
      db[:database].should be_nil
    end
    it "should parse just a host no slash and https" do
      db = CouchRest.parse "https://127.0.0.1:5555"
      db[:host].should == "127.0.0.1:5555"
      db[:database].should be_nil
    end
    it "should get docid" do
      db = CouchRest.parse "127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
    it "should get docid with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
    it "should get docid with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
    it "should parse a host and db" do
      db = CouchRest.parse "127.0.0.1/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1"
    end
    it "should parse a host and db with http" do
      db = CouchRest.parse "http://127.0.0.1/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1"
    end
    it "should parse a host and db with https" do
      db = CouchRest.parse "https://127.0.0.1/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1"
    end
    it "should parse a host with a port and db" do
      db = CouchRest.parse "127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse a host with a port and db with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse a host with a port and db with https" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host" do
      db = CouchRest.parse "http://127.0.0.1:5555/"
      db[:database].should be_nil
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/"
      db[:database].should be_nil
      db[:host].should == "127.0.0.1:5555"
    end
    it "should parse just a host no slash" do
      db = CouchRest.parse "http://127.0.0.1:5555"
      db[:host].should == "127.0.0.1:5555"
      db[:database].should be_nil
    end
    it "should parse just a host no slash and https" do
      db = CouchRest.parse "https://127.0.0.1:5555"
      db[:host].should == "127.0.0.1:5555"
      db[:database].should be_nil
    end
    it "should get docid" do
      db = CouchRest.parse "127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
    it "should get docid with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
    it "should get docid with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/my-db/my-doc"
      db[:database].should == "my-db"
      db[:host].should == "127.0.0.1:5555"
      db[:doc].should == "my-doc"
    end
  end

  describe "easy initializing a database adapter" do
    it "should be possible without an explicit CouchRest instantiation" do
      db = CouchRest.database "http://127.0.0.1:5984/couchrest-test"
      db.should be_an_instance_of(CouchRest::Database)
      db.host.should == "127.0.0.1:5984"
    end
    # TODO add https support (need test environment...)
    # it "should work with https" # do
    #      db = CouchRest.database "https://127.0.0.1:5984/couchrest-test"
    #      db.host.should == "https://127.0.0.1:5984"
    #    end
    it "should not create the database automatically" do
      db = CouchRest.database "http://127.0.0.1:5984/couchrest-test"
      lambda{db.info}.should raise_error(RestClient::ResourceNotFound)      
    end
  end

  describe "ensuring the db exists" do
    it "should be super easy" do
      db = CouchRest.database! "http://127.0.0.1:5984/couchrest-test-2"
      db.name.should == 'couchrest-test-2'
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

  describe "using a proxy for RestClient connections" do
    it "should set proxy url for RestClient" do
      CouchRest.proxy 'http://localhost:8888/'
      proxy_uri = URI.parse(HttpAbstraction.proxy)
      proxy_uri.host.should eql( 'localhost' )
      proxy_uri.port.should eql( 8888 )
      CouchRest.proxy nil
    end
  end

end