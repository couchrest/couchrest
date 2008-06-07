require File.dirname(__FILE__) + '/../lib/couch_rest'

describe CouchRest do

  before(:each) do
    @cr = CouchRest.new("http://localhost:5984")
    @db = @cr.database('couchrest-test')
    begin
      @db.delete! 
    rescue RestClient::Request::RequestFailed
    end
  end

  after(:each) do
    begin
      @db.delete!
    rescue RestClient::Request::RequestFailed
    end
  end

  describe "tested against the current CouchDB svn revision" do
    it "should be up to date" do
      v = @cr.info["version"]
      vi = v.split(/a/).pop.to_i
      vi.should be >= 661484 # versions older than this will likely fail many specs
      vi.should be <= 663797 # versions newer than this haven't been tried
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

  describe "initializing a database" do
    it "should return a db" do
      db = @cr.database('couchrest-test')
      db.should be_an_instance_of(CouchRest::Database)
      db.host.should == @cr.uri
    end
  end

  describe "successfully creating a database" do
    it "should start without a database" do
      @cr.databases.should_not include('couchrest-test')
    end
    it "should return the created database" do
      db = @cr.create_db('couchrest-test')
      db.should be_an_instance_of(CouchRest::Database)
    end
    it "should create the database" do
      db = @cr.create_db('couchrest-test')
      @cr.databases.should include('couchrest-test')
    end
  end

  describe "failing to create a database because the name is taken" do
    before(:each) do
      db = @cr.create_db('couchrest-test')
    end
    it "should start with the test database" do
      @cr.databases.should include('couchrest-test')
    end
    it "should PUT the database and raise an error" do
      lambda{
        @cr.create_db('couchrest-test')
      }.should raise_error(RestClient::Request::RequestFailed)
    end
  end

end