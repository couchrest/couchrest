require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Pager do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @pager = CouchRest::Pager.new(@db)
  end
  
  after(:all) do
    begin
      @db.delete!
    rescue RestClient::Request::RequestFailed
    end
  end
  
  it "should store the db" do
    @pager.db.should == @db
  end
  
  describe "paging all docs" do
    before(:all) do
      @docs = []
      100.times do |i|
        @docs << ({:number => (i % 10)})
      end
      @db.bulk_save(@docs)
    end
    it "should yield total_docs / limit times" do
      n = 0
      @pager.all_docs(10) do |doc|
        n += 1
      end
      n.should == 10
    end
    it "should yield each docrow group without duplicate docs" do
      docids = {}
      @pager.all_docs(10) do |docrows|
        docrows.each do |row|
          docids[row['id']].should be_nil
          docids[row['id']] = true
        end
      end      
      docids.keys.length.should == 100
    end
    it "should yield each docrow group" do
      @pager.all_docs(10) do |docrows|
        doc = @db.get(docrows[0]['id'])
        doc['number'].class.should == Fixnum
      end      
    end
  end
  
  describe "Pager with a view and docs" do
    before(:all) do
      @docs = []
      100.times do |i|
        @docs << ({:number => (i % 10)})
      end
      @db.bulk_save(@docs)
      @db.save_doc({
        '_id' => '_design/magic',
        'views' => {
          'number' => {
            'map' => 'function(doc){emit(doc.number,null)}'
          }
        }
      })
    end
    
    it "should have docs" do
      @docs.length.should == 100
      @db.documents['rows'].length.should == 101
    end
    
    it "should have a view" do
      @db.view('magic/number', :limit => 10)['rows'][0]['key'].should == 0
    end
    
    it "should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 20) do |k,vs|
        results[k] = vs.length
      end
      results[0].should == 10
      results[3].should == 10
    end
    
    it "with a small step size should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 7) do |k,vs|
        results[k] = vs.length
      end
      results[0].should == 10
      results[3].should == 10
      results[9].should == 10
    end
    it "with a large step size should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 1000) do |k,vs|
        results[k] = vs.length
      end
      results[0].should == 10
      results[3].should == 10
      results[9].should == 10
    end
    it "with a begin and end should only yield in the range (and leave out the lastkey)" do
      results = {}
      @pager.key_reduce('magic/number', 1000, 4, 7) do |k,vs|
        results[k] = vs.length
      end
      results[0].should be_nil
      results[4].should == 10
      results[6].should == 10
      results[7].should be_nil
      results[8].should be_nil
      results[9].should be_nil
    end
  end
end