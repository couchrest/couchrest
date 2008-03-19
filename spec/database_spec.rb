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
    
  describe "inserting documents without an id: POST" do
    it "should start without the document" do
      @db.documents.should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document" do
      r = @db.save({'lemons' => 'from texas', 'and' => 'spain'})
      @db.documents.should include(r)
    end
  end
  
  describe "with documents in it" do
    before(:each) do
      # @db.create_doc()
    end
    it "should list them" do
      ds = @db.documents
      ds['rows'].should be_an_instance_of(Array)
      # ds[:total_rows].should be_greater_than 0
      # should I  use a View class?
      ds.should be_an_instance_of(CouchRest::View)
      
      # ds.rows = []
      # ds.rows.include?(...)
      # ds.total_rows
    end
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