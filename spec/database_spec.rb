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
  
  describe "POST (adding bulk documents)" do
    it "should add them without ids" do
      rs = @db.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs['results'].each do |r|
        @db.get(r['id'])
      end
    end
    it "should add them with uniq ids" do
      rs = @db.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs['results'].each do |r|
        @db.get(r['id'])
      end
    end
    it "should with one bad id should save the ones it can" do
      @r = @db.save({'lemons' => 'from texas', 'and' => 'how', "_id" => "oneB"})
      
      rs = @db.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
        
      # should save the new document
      newid = @db.documents['rows'].reject do |d|
        ['oneB','twoB'].include?(d['id'])
      end.first['id']
      newdoc = @db.get(newid)
      newdoc["another"][2].should == 'keys'

      # should save the ok id
      @db.get('twoB')['mild'].should == "yet local"

      # should confict on the duplicate id
      oneB = @db.get('oneB')
      oneB['wild'].should be_nil
      oneB['lemons'].should == 'from texas'
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
  
  describe "PUT (existing document with rev)" do
    before(:each) do
      @db.save({'_id' => 'my-doc', 'will-exist' => 'here'})
      @doc = @db.get('my-doc')
    end
    it "should start with the document" do
      @doc['will-exist'].should == 'here'
    end
    it "should update the document" do
      @doc['them-keys'] = 'huge'
      @db.save(@doc)
      now = @db.get('my-doc')
      now['them-keys'].should == 'huge'
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
    it "should work with uri id" do
      doc = @db.get(@docid)
      @db.delete doc
      lambda{@db.get @docid}.should raise_error
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