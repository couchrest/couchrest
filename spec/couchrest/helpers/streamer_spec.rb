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
    header = @streamer.get("#{@db.root}/_all_docs") do |row|
      count += 1
    end
    count.should == 1001
    header.should == {"total_rows" => 1001, "offset" => 0}
  end

  it "should GET each row in a view with params" do
    count = 0
    header = @streamer.get("#{@db.root}/_all_docs?include_docs=true&limit=5") do |row|
      count += 1
    end
    count.should == 5
    header.should == {"total_rows" => 1001, "offset" => 0}
  end

  it "should GET no rows in a view with limit=0" do
    count = 0
    header = @streamer.get("#{@db.root}/_all_docs?include_docs=true&limit=0") do |row|
      count += 1
    end
    count.should == 0
    header.should == {"total_rows" => 1001, "offset" => 0}
  end

  it "should raise an exception receives malformed data" do
    IO.stub(:popen) do |cmd, block|
      class F
        def initialize
          @lines = [
            '{"total_rows": 123, "offset": "0", "rows": [',
            '{"foo": 1},',
            '{"foo": 2},',
          ]
        end

        def gets
          @lines.shift
        end
      end

      f = F.new
      block.call f

      IO.unstub(:popen)
      IO.popen 'true' do; end
    end

    count = 0
    expect do
      @streamer.get("#{@db.root}/_all_docs?include_docs=true&limit=0") do |row|
        count += 1
      end
    end.should raise_error(MultiJson::DecodeError)
  end

  it "should raise an exception if the couch connection fails" do
    IO.stub(:popen) do |cmd, block|
      class F
        def initialize
          @lines = [
            '{"total_rows": 123, "offset": "0", "rows": [',
            '{"foo": 1},',
            '{"foo": 2},',
          ]
        end

        def gets
          @lines.shift
        end
      end

      block.call F.new

      IO.unstub(:popen)
      IO.popen 'false' do; end
    end

    count = 0

    expect do
      @streamer.get("#{@db.root}/_all_docs?include_docs=true&limit=0") do |row|
        count += 1
      end
    end.should raise_error(RestClient::ServerBrokeConnection)

    count.should == 2
  end

  it "should POST for each row in a view" do
    # First grab a pair of IDs
    ids = []
    @streamer.get("#{@db.root}/_design/first/_view/test?limit=2") do |row|
      ids << row['id']
    end
    ids.should have(2).items
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
