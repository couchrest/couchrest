require File.dirname(__FILE__) + '/../../spec_helper'

describe CouchRest::Streamer do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @streamer = CouchRest::Streamer.new(@db)
    @docs = (1..1000).collect{|i| {:integer => i, :string => i.to_s}}
    @db.bulk_save(@docs)
  end
  
  it "should yield each row in a view" do
    count = 0
    sum = 0
    @streamer.view("_all_docs") do |row|
      count += 1
    end
    count.should == 1001
  end
  
end