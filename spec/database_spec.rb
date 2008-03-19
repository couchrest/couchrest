require File.dirname(__FILE__) + '/../lib/couch_rest'

describe CouchRest::Database do
  before(:each) do
    @cr = CouchRest.new("http://local.grabb.it:5984")
    begin
      @db = @cr.create_db('couchrest-test')
    rescue RestClient::Request::RequestFailed
    end
  end
  
  after(:each) do
    begin
      @db.delete!
    rescue RestClient::Request::RequestFailed
    end
  end
    
  describe "GET (document by id) when the doc exists" do
    before(:each) do
      @r = @db.save({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should get the document" do
      doc = @db.get(@r['id'])
      doc['lemons'].should == 'from texas'
    end
    it "should work with a funky id" do
      @db.get(@docid)['will-exist'].should == 'here'
    end
  end
  
  describe "POST (new document without an id)" do
    it "should start without the document" do
      @db.documents.should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document and return the id" do
      r = @db.save({'lemons' => 'from texas', 'and' => 'spain'})
      # @db.documents.should include(r)
      lambda{@db.save({'_id' => r['id']})}.should raise_error(RestClient::Request::RequestFailed)
    end
  end

  describe "PUT (new document with url id)" do
    it "should create the document" do
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save({'_id' => @docid, 'will-exist' => 'here'})
      lambda{@db.save({'_id' => @docid})}.should raise_error(RestClient::Request::RequestFailed)
      @db.get(@docid)['will-exist'].should == 'here'
    end
  end
  
  describe "PUT (new document with id)" do
    it "should start without the document" do
      # r = @db.save({'lemons' => 'from texas', 'and' => 'spain'})
      @db.documents['rows'].each do |doc|
        doc['id'].should_not == 'my-doc'
      end
      # should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document" do
      @db.save({'_id' => 'my-doc', 'will-exist' => 'here'})
      lambda{@db.save({'_id' => 'my-doc'})}.should raise_error(RestClient::Request::RequestFailed)
    end
  end
  
  describe "DELETE existing document" do
    before(:each) do
      @r = @db.save({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should work" do
      doc = @db.get(@r['id'])
      doc['and'].should == 'spain'
      @db.delete doc
      lambda{@db.get @r['id']}.should raise_error
    end
  end
  
  it "should list documents" do
    5.times do
      @db.save({'another' => 'doc', 'will-exist' => 'anywhere'})
    end
    ds = @db.documents
    ds['rows'].should be_an_instance_of(Array)
    ds['rows'][0]['id'].should_not be_nil
    ds['total_rows'].should == 5
    # should I  use a View class?
    # ds.should be_an_instance_of(CouchRest::View)
    
    # ds.rows = []
    # ds.rows.include?(...)
    # ds.total_rows
  end
  
  describe "deleting a database" do
    it "should start with the test database" do
      @cr.databases.should include('couchrest-test')
    end
    it "should delete the database" do
      db = @cr.database('couchrest-test')
      # r = 
      db.delete!
      # r['ok'].should == true
      @cr.databases.should_not include('couchrest-test')
    end
  end


end