require File.dirname(__FILE__) + '/spec_helper'

describe CouchRest::Pager do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    begin
      @cr.database(TESTDB).delete!
    rescue RestClient::Request::RequestFailed
    end
    begin
      @db = @cr.create_db(TESTDB)
    rescue RestClient::Request::RequestFailed
    end
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
  
  describe "Pager with a view and docs" do
    before(:all) do
      @docs = []
      100.times do |i|
        @docs << ({:number => (i % 10)})
      end
      @db.bulk_save(@docs)
      @db.save({
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
      @db.view('magic/number', :count => 10)['rows'][0]['key'].should == 0
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