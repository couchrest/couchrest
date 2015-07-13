require File.expand_path("../../spec_helper", __FILE__)

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

  describe "version" do
    it "should be there" do
      expect(CouchRest::VERSION).to_not be_empty
    end
  end

  describe "getting info" do
    it "should list databases" do
      expect(@cr.databases).to be_an_instance_of(Array)
    end
    it "should get info" do
      expect(@cr.info["couchdb"]).to eq "Welcome"
      expect(@cr.info.class).to eq Hash   
    end
  end

  describe "initializing a database" do
    it "should return a db" do
      db = @cr.database(TESTDB)
      expect(db).to be_an_instance_of(CouchRest::Database)
      expect(db.uri).to eq(@cr.uri + TESTDB)
    end
  end

  describe "parsing urls" do
    it "should parse just a dbname" do
      db = CouchRest.parse "my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1:5984"
    end
    it "should parse a host and db" do
      db = CouchRest.parse "127.0.0.1/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1"
    end
    it "should parse a host and db with http" do
      db = CouchRest.parse "http://127.0.0.1/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1"
    end
    it "should parse a host and db with https" do
      db = CouchRest.parse "https://127.0.0.1/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "https://127.0.0.1"
    end
    it "should parse a host with a port and db" do
      db = CouchRest.parse "127.0.0.1:5555/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1:5555"
    end
    it "should parse a host with a port and db with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1:5555"
    end
    it "should parse a host with a port and db with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/my-db"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "https://127.0.0.1:5555"
    end
    it "should parse just a host" do
      db = CouchRest.parse "http://127.0.0.1:5555/"
      expect(db[:database]).to be_nil
      expect(db[:host]).to eq "http://127.0.0.1:5555"
    end
    it "should parse just a host with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/"
      expect(db[:database]).to be_nil
      expect(db[:host]).to eq "https://127.0.0.1:5555"
    end
    it "should parse just a host no slash" do
      db = CouchRest.parse "http://127.0.0.1:5555"
      expect(db[:host]).to eq "http://127.0.0.1:5555"
      expect(db[:database]).to be_nil
    end
    it "should parse just a host no slash and https" do
      db = CouchRest.parse "https://127.0.0.1:5555"
      expect(db[:host]).to eq "https://127.0.0.1:5555"
      expect(db[:database]).to be_nil
    end
    it "should get docid" do
      db = CouchRest.parse "127.0.0.1:5555/my-db/my-doc"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1:5555"
      expect(db[:doc]).to eq "my-doc"
    end
    it "should get docid with http" do
      db = CouchRest.parse "http://127.0.0.1:5555/my-db/my-doc"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "http://127.0.0.1:5555"
      expect(db[:doc]).to eq "my-doc"
    end
    it "should get docid with https" do
      db = CouchRest.parse "https://127.0.0.1:5555/my-db/my-doc"
      expect(db[:database]).to eq "my-db"
      expect(db[:host]).to eq "https://127.0.0.1:5555"
      expect(db[:doc]).to eq "my-doc"
    end
  end

  describe "easy initializing a database adapter" do
    it "should be possible without an explicit CouchRest instantiation" do
      db = CouchRest.database "http://127.0.0.1:5984/couchrest-test"
      expect(db).to be_an_instance_of(CouchRest::Database)
      expect(db.uri.to_s).to eq "http://127.0.0.1:5984/couchrest-test"
    end
    # TODO add https support (need test environment...)
    # it "should work with https" # do
    #      db = CouchRest.database "https://127.0.0.1:5984/couchrest-test"
    #      expect(db.host).to eq "https://127.0.0.1:5984"
    #    end
    it "should not create the database automatically" do
      db = CouchRest.database "http://127.0.0.1:5984/couchrest-test"
      expect(lambda{db.info}).to raise_error(CouchRest::NotFound)      
    end
  end

  describe "ensuring the db exists" do
    it "should be super easy" do
      db = CouchRest.database! "#{COUCHHOST}/couchrest-test-2"
      expect(db.name).to eq 'couchrest-test-2'
      expect(db.info["db_name"]).to eq 'couchrest-test-2'
    end
  end

  describe "successfully creating a database" do
    it "should start without a database" do
      expect(@cr.databases).not_to include(TESTDB)
    end
    it "should return the created database" do
      db = @cr.create_db(TESTDB)
      expect(db).to be_an_instance_of(CouchRest::Database)
    end
    it "should create the database" do
      db = @cr.create_db(TESTDB)
      expect(@cr.databases).to include(TESTDB)
    end
  end

  describe "failing to create a database because the name is taken" do
    before(:each) do
      db = @cr.create_db(TESTDB)
    end
    it "should start with the test database" do
      expect(@cr.databases).to include(TESTDB)
    end
    it "should PUT the database and raise an error" do
      expect {
        @cr.create_db(TESTDB)
      }.to raise_error(CouchRest::PreconditionFailed)
    end
  end

  describe "using a proxy for connections" do
    it "should set proxy url" do
      CouchRest.proxy 'http://localhost:8888/'
      proxy_uri = URI.parse(CouchRest::Connection.proxy)
      expect(proxy_uri.host).to eql( 'localhost' )
      expect(proxy_uri.port).to eql( 8888 )
      CouchRest.proxy nil
    end
  end

end
