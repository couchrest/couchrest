require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Streamer do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @streamer = CouchRest::Streamer.new()
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

  it "should raise error on #view as depricated" do
    lambda { @streamer.view }.should raise_error(/depricated/)
  end

  it "should GET each row in a view" do
    count = 0
    @streamer.get("#{@db.root}/_all_docs") do |row|
      count += 1
    end
    count.should == 1001
  end

  it "should GET each row in a view with params" do
    count = 0
    @streamer.get("#{@db.root}/_all_docs?include_docs=true&limit=5") do |row|
      count += 1
    end
    count.should == 5
  end

  it "should POST for each row in a view" do
    # First grab a pair of IDs
    ids = []
    @streamer.get("#{@db.root}/_design/first/_view/test?limit=2") do |row|
      ids << row['id']
    end
    count = 0
    @streamer.post("#{@db.root}/_all_docs?include_docs=true", :keys => ids) do |row|
      count += 1
    end
    count.should == 2
  end

  it "should escape quotes" do
    @streamer.send(:escape_quotes, "keys: [\"sams's test\"]").should eql("keys: [\\\"sams's test\\\"]")
  end

end
