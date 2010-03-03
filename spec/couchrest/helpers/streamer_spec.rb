require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Streamer do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @streamer = CouchRest::Streamer.new(@db)
    @docs = (1..1000).collect{|i| {:integer => i, :string => i.to_s}}
    @db.bulk_save(@docs)
    @db.save_doc({
      "_id" => "_design/first",
      :views => {
        :test => {
	  :map => "function(doc){for(var w in doc){ if(!w.match(/^_/))emit(w,doc[w])}}"
        }
      }
    })
  end
  
  it "should yield each row in a view" do
    count = 0
    sum = 0
    @streamer.view("_all_docs") do |row|
      count += 1
    end
    count.should == 1001
  end

  it "should accept several params" do
    count = 0
    @streamer.view("_design/first/_view/test", :include_docs => true, :limit => 5) do |row|
      count += 1
    end
    count.should == 5
  end

  it "should accept both view formats" do
    count = 0
    @streamer.view("_design/first/_view/test") do |row|
      count += 1
    end
    count.should == 2000
    count = 0
    @streamer.view("first/test") do |row|
      count += 1
    end
    count.should == 2000
  end

end
