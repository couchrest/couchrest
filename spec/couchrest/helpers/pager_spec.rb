require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Pager do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @pager = CouchRest::Pager.new(@db)
    @docs = []
    100.times do |i|
      @docs << ({:number => (i % 10)})
    end
    @db.bulk_save(@docs)
  end
  
  after(:all) do
    begin
      @db.delete!
    rescue RestClient::Request::RequestFailed
    end
  end
  
  it "should store the db" do
    expect(@pager.db).to eql @db
  end
  
  describe "paging all docs" do
    it "should yield total_docs / limit times" do
      n = 0
      @pager.all_docs(10) do |doc|
        n += 1
      end
      expect(n).to eql 10
    end
    it "should yield each docrow group without duplicate docs" do
      docids = {}
      @pager.all_docs(10) do |docrows|
        docrows.each do |row|
          expect(docids[row['id']]).to be_nil
          docids[row['id']] = true
        end
      end      
      expect(docids.keys.length).to eql 100
    end
    it "should yield each docrow group" do
      @pager.all_docs(10) do |docrows|
        doc = @db.get(docrows[0]['id'])
        expect(doc['number'].class).to eql Fixnum
      end      
    end
  end
  
  describe "Pager with a view and docs" do
    before(:all) do
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
      expect(@docs.length).to eql 100
      expect(@db.documents['rows'].length).to eql 101
    end
    
    it "should have a view" do
      expect(@db.view('magic/number', :limit => 10)['rows'][0]['key']).to eql 0
    end
    
    it "should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 20) do |k,vs|
        results[k] = vs.length
      end
      expect(results[0]).to eql 10
      expect(results[3]).to eql 10
    end
    
    it "with a small step size should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 7) do |k,vs|
        results[k] = vs.length
      end
      expect(results[0]).to eql 10
      expect(results[3]).to eql 10
      expect(results[9]).to eql 10
    end
    it "with a large step size should yield once per key" do
      results = {}
      @pager.key_reduce('magic/number', 1000) do |k,vs|
        results[k] = vs.length
      end
      expect(results[0]).to eql 10
      expect(results[3]).to eql 10
      expect(results[9]).to eql 10
    end
    it "with a begin and end should only yield in the range (and leave out the lastkey)" do
      results = {}
      @pager.key_reduce('magic/number', 1000, 4, 7) do |k,vs|
        results[k] = vs.length
      end
      expect(results[0]).to be_nil
      expect(results[4]).to eql 10
      expect(results[6]).to eql 10
      expect(results[7]).to be_nil
      expect(results[8]).to be_nil
      expect(results[9]).to be_nil
    end
  end
end
