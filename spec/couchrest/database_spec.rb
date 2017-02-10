require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Database do
  before(:each) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue CouchRest::NotFound
    @db = @cr.create_db(TESTDB) # rescue nil
  end

  describe "#initialize" do
    describe "database name including slash" do
      it "should escape the name in the URI" do
        db = @cr.database("foo/bar some")
        expect(db.name).to eq "foo/bar some"
        expect(db.root).to eq URI("#{COUCHHOST}/foo%2Fbar+some")
        expect(db.uri).to eq URI("#{COUCHHOST}/foo%2Fbar+some")
        expect(db.to_s).to eq "#{COUCHHOST}/foo%2Fbar+some"
        expect(db.path).to eq "/foo%2Fbar+some"
      end
    end
  end

  describe "#info" do
    it "should request basic database data" do
      expect(@db.info['db_name']).to eql(TESTDB)
    end
  end

  describe "map query with _temp_view in Javascript" do
    before(:each) do
      @db.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      @temp_view = {:map => "function(doc){for(var w in doc){ if(!w.match(/^_/))emit(w,doc[w])}}"}
    end
    it "should return the result of the temporary function" do
      rs = @db.temp_view(@temp_view)
      expect(rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length).to eq 1
    end
    it "should work with a range" do
      rs = @db.temp_view(@temp_view, :startkey => "b", :endkey => "z")
      expect(rs['rows'].length).to eq 2
    end
    it "should work with a key" do
      rs = @db.temp_view(@temp_view, :key => "wild")
      expect(rs['rows'].length).to eq 1
    end
    it "should work with a limit" do
      rs = @db.temp_view(@temp_view, :limit => 1)
      expect(rs['rows'].length).to eq 1
    end
    it "should work with multi-keys" do
      rs = @db.temp_view(@temp_view, :keys => ["another", "wild"])
      expect(rs['rows'].length).to eq 2
    end
  end

  describe "map/reduce query with _temp_view in Javascript" do
    before(:each) do
      @db.bulk_save([
          {"beverage" => "beer", :count => 4},
          {"beverage" => "beer", :count => 2},
          {"beverage" => "tea", :count => 3}
        ])
    end
    it "should return the result of the temporary function" do
      rs = @db.temp_view(:map => "function(doc){emit(doc.beverage, doc.count)}", :reduce =>  "function(beverage,counts){return sum(counts)}")
      # expect(rs).to eq 'x'
      expect(rs['rows'][0]['value']).to eq 9
    end
  end
  
  describe "saving a view" do
    before(:each) do
      @view = {'test' => {'map' => <<-JS
        function(doc) {
          var reg = new RegExp("\\\\W");
          if (doc.word && !reg.test(doc.word)) {
            emit(doc.word,null);
          }
        }
      JS
      }}
      @db.save_doc({
        "_id" => "_design/test",
        :views => @view
      })
    end
    it "should work properly" do
      r = @db.bulk_save([
        {"word" => "once"},
        {"word" => "and again"}
      ])
      r = @db.view('test/test')
      expect(r['total_rows']).to eq 1
    end
    it "should round trip" do
      expect(@db.get("_design/test")['views']).to eq @view
    end
  end
  
  describe "select from an existing view" do
    before(:each) do
      r = @db.save_doc({
        "_id" => "_design/first", 
        :views => {
          :test => {
            :map => "function(doc){for(var w in doc){ if(!w.match(/^_/))emit(w,doc[w])}}"
            }
          }
        })
      @db.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
    end
    it "should have the view" do
      expect(@db.get('_design/first')['views']['test']['map']).to include("for(var w in doc)")
    end
    it "should list from the view" do
      rs = @db.view('first/test')
      expect(rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length).to eq 1
    end
    it "should work with a range" do
      rs = @db.view('first/test', :startkey => "b", :endkey => "z")
      expect(rs['rows'].length).to eq 2
    end
    it "should work with a key" do
      rs = @db.view('first/test', :key => "wild")
      expect(rs['rows'].length).to eq 1
    end
    it "should work with a limit" do
      rs = @db.view('first/test', :limit => 1)
      expect(rs['rows'].length).to eq 1
    end
    it "should work with multi-keys" do
      rs = @db.view('first/test', :keys => ["another", "wild"])
      expect(rs['rows'].length).to eq 2
    end
    it "should not modify given params" do
      original_params = {:keys => ["another", "wild"]}
      params = original_params.dup
      @db.view('first/test', params)
      expect(params).to eq original_params
    end
    it "should accept a block" do
      rows = []
      rs = @db.view('first/test', :include_docs => true) do |row|
        rows << row
      end
      expect(rows.length).to eq 3
      expect(rs["total_rows"]).to eq 3
    end
    it "should accept a block with several params" do
      rows = []
      rs = @db.view('first/test', :include_docs => true, :limit => 2) do |row|
        rows << row
      end
      expect(rows.length).to eq 2
    end
    it "should accept a payload" do
      rs = @db.view('first/test', {}, :keys => ["another", "wild"])
      expect(rs['rows'].length).to eq 2
    end
    it "should accept a payload with block" do
      rows = []
      rs = @db.view('first/test', {:include_docs => true}, :keys => ["another", "wild"]) do |row|
        rows << row
      end
      expect(rows.length).to eq 2
      expect(rows.first['doc']['another']).not_to be_empty
    end
    it "should accept a short design doc name" do
      res = { 'rows' => [] }
      db = CouchRest.new("http://mock").database('db')
      stub_request(:get, "http://mock/db/_design/a/_view/test")
        .to_return(:body => res.to_json)
      expect(db.view('a/test')).to eql(res)
    end
  end

  describe "#changes" do
    # uses standard view method, so not much testing required
    before(:each) do
      [ 
        {"wild" => "and random"},
        {"mild" => "yet local"},
        {"another" => ["set","of","keys"]}
      ].each do |d|
        @db.save_doc(d)
      end
    end

    it "should produce a basic list of changes" do
      c = @db.changes
      expect(c['results'].length).to eql(3)
    end

    it "should include all changes in continuous feed" do
      changes = []
      begin
        @db.changes("feed" => "continuous", "since" => "0") do |change|
          changes << change
          raise RuntimeError.new # escape from infinite loop
        end
      rescue RuntimeError
      end
      expect(changes.first["seq"].to_i).to eql(1)
    end

    it "should provide id of last document" do
      c = @db.changes
      doc = @db.get(c['results'].last['id'])
      expect(doc['another']).not_to be_empty
    end
  end

  describe "GET (document by id) when the doc exists" do
    before(:each) do
      @r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should get the document" do
      doc = @db.get(@r['id'])
      expect(doc['lemons']).to eq 'from texas'
    end
    it "should work with a funky id" do
      expect(@db.get(@docid)['will-exist']).to eq 'here'
    end
  end

  describe "GET (document by id) when the doc does not exist)" do
   it "should provide nil" do
      expect(@db.get('fooooobar')).to be_nil
    end
    it "should raise an exception" do
      expect do
        @db.get!('fooooobar')
      end.to raise_error(CouchRest::NotFound)
    end
  end
  
  describe "POST (adding bulk documents)" do
    it "should add them without ids" do
      rs = @db.bulk_save([
          {"wild" => "and random"},
          {"mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs.each do |r|
        expect(@db.get(r['id']).rev).to eq r["rev"]
      end
    end
    
    it "should use uuids when ids aren't provided" do
      @db.server.stub(:next_uuid).and_return('asdf6sgadkfhgsdfusdf')
      
      docs = [{'key' => 'value'}, {'_id' => 'totally-uniq'}]
      id_docs = [{'key' => 'value', '_id' => 'asdf6sgadkfhgsdfusdf'}, {'_id' => 'totally-uniq'}]

      expect(@db.connection).to receive(:post).with("/couchrest-test/_bulk_docs", {:docs => id_docs})
      
      @db.bulk_save(docs)
    end

    it "should allow UUID assignment to be disabled" do
      expect(@db.connection).to_not receive(:next_uuid)
      docs = [{'key' => 'value'}, {'_id' => 'totally-uniq'}]
      expect(@db.connection).to receive(:post).with("/couchrest-test/_bulk_docs", {:docs => docs})
      @db.bulk_save(docs, :use_uuids => false)
    end
    
    it "should add them with uniq ids" do
      rs = @db.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs.each do |r|
        expect(@db.get(r['id']).rev).to eq r["rev"]
      end
    end

    it "should empty the bulk save cache if no documents are given" do
      @db.save_doc({"_id" => "bulk_cache_1", "val" => "test"}, true)
      expect(@db.get('bulk_cache_1')).to be_nil
      @db.bulk_save
      expect(@db.get("bulk_cache_1")["val"]).to eq "test"
    end
    
    it "should make an atomic write when all_or_nothing is set" do
      docs = [{"_id" => "oneB", "wild" => "and random"}, {"_id" => "twoB", "mild" => "yet local"}]
      expect(@db.connection).to receive(:post).with("/couchrest-test/_bulk_docs", {:all_or_nothing => true, :docs => docs})
      
      @db.bulk_save(docs, :all_or_nothing => true)
    end

    it "should raise an error that is useful for recovery" do
      @r = @db.save_doc({"_id" => "taken", "field" => "stuff"})
      begin
        rs = @db.bulk_save([
            {"_id" => "taken", "wild" => "and random"},
            {"_id" => "free", "mild" => "yet local"},
            {"another" => ["set","of","keys"]}
          ])
      rescue CouchRest::RequestFailed => e
        # soon CouchDB will provide _which_ docs conflicted
        expect(MultiJson.decode(e.response.body)['error']).to eq 'conflict'
      end
    end
  end
  
  describe "new document without an id" do
    it "should start empty" do
      expect(@db.documents["total_rows"]).to eq 0
    end
    it "should create the document and return the id" do
      r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      r2 = @db.get(r['id'])
      expect(r2["lemons"]).to eq "from texas"
    end
    it "should use PUT with UUIDs" do
      expect(@db.connection).to receive(:put).and_return({"ok" => true, "id" => "100", "rev" => "55"})
      r = @db.save_doc({'just' => ['another document']})
    end
    
  end
  
  describe "fetch_attachment" do
    before do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      @doc = {
        "_id" => "mydocwithattachment",
        "field" => ["some value"],
        "_attachments" => {
          "test.html" => {
            "type" => "text/html",
            "data" => @attach
          }
        }
      }
      @db.save_doc(@doc)
    end
    
    # Depreacated
    # it "should get the attachment with the doc's _id" do
    #   expect(@db.fetch_attachment("mydocwithattachment", "test.html")).to eq @attach
    # end
    
    it "should get the attachment with the doc itself" do
      expect(@db.fetch_attachment(@db.get('mydocwithattachment'), 'test.html')).to eq @attach
    end
  end

  describe "PUT attachment from file" do
    before(:each) do
      filename = FIXTURE_PATH + '/attachments/couchdb.png'
      @file = File.open(filename, "rb")
    end
    after(:each) do
      @file.close
    end
    it "should save the attachment to a new doc" do
      r = @db.put_attachment({'_id' => 'attach-this'}, 'couchdb.png', image = @file.read, {:content_type => 'image/png'})
      expect(r['ok']).to be_true
      doc = @db.get("attach-this")
      attachment = @db.fetch_attachment(doc, "couchdb.png")
      expect((attachment == image)).to be_true
      #if attachment.respond_to?(:net_http_res)  
      #  expect(attachment.net_http_res.body).to eq image
      #end
    end
  end

  describe "PUT document with attachment" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      doc = {
        "_id" => "mydocwithattachment",
        "field" => ["some value"],
        "_attachments" => {
          "test.html" => {
            "type" => "text/html",
            "data" => @attach
          }
        }
      }
      @db.save_doc(doc)
      @doc = @db.get("mydocwithattachment")
    end
    it "should save and be indicated" do
      expect(@doc['_attachments']['test.html']['length']).to eq @attach.length
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"test.html")
      expect(attachment).to eq @attach
    end
  end
  
  describe "PUT document with attachment stub" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      doc = {
        '_id' => 'mydocwithattachment',
        'field' => ['some_value'],
        '_attachments' => {
          'test.html' => {
            'type' => 'text/html', 'data' => @attach
          }
        }
      }
      @db.save_doc(doc)
      expect(doc['_rev']).not_to be_nil
      doc['field'] << 'another value'
      expect(@db.save_doc(doc)["ok"]).to be_true
    end
    
    it 'should be there' do
      doc = @db.get('mydocwithattachment')
      attachment = @db.fetch_attachment(doc, 'test.html')
      expect(attachment).to eq @attach
    end
  end

  describe "PUT document with multiple attachments" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      @attach2 = "<html><head><title>Other Doc</title></head><body><p>Has more words.</p></body></html>"
      @data = {
        "_id" => "mydocwithattachment",
        "field" => ["some value"],
        "_attachments" => {
          "test.html" => {
            "type" => "text/html",
            "data" => @attach
          },
          "other.html" => {
            "type" => "text/html",
            "data" => @attach2
          }
        }
      }
      @db.save_doc(@data)
      @doc = @db.get("mydocwithattachment")
    end
    it "should save and be indicated" do
      expect(@doc['_attachments']['test.html']['length']).to eq @attach.length
      expect(@doc['_attachments']['other.html']['length']).to eq @attach2.length
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"test.html")
      expect(attachment).to eq @attach
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"other.html")
      expect(attachment).to eq @attach2
    end
    it "should not re-encode document" do
      @db.save_doc(@data)
      attachment = @db.fetch_attachment(@data,"test.html")
      expect(attachment).to eq @attach
    end
  end
  
  describe "DELETE an attachment directly from the database" do
    before(:each) do
      doc = {
        '_id' => 'mydocwithattachment',
        '_attachments' => {
          'test.html' => {
            'type' => 'text/html',
            'data' => "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
          }
        }
      }
      @db.save_doc(doc)
      @doc = @db.get('mydocwithattachment')
    end
    it "should delete the attachment" do
      expect(lambda { @db.fetch_attachment(@doc,'test.html') }).not_to raise_error
      @db.delete_attachment(@doc, "test.html")  
      @doc = @db.get('mydocwithattachment') # avoid getting a 409
      expect(lambda{ @db.fetch_attachment(@doc,'test.html')}).to raise_error
    end
    
    it "should force a delete even if we get a 409" do
      @doc['new_attribute'] = 'something new'
      @db.put_attachment(@doc, 'test', File.open(File.join(FIXTURE_PATH, 'attachments', 'test.html')).read)
      # at this point the revision number changed, if we try to save doc one more time
      # we would get a 409.
      expect(lambda{ @db.save_doc(@doc) }).to raise_error
      expect(lambda{ @db.delete_attachment(@doc, "test", true) }).not_to raise_error
    end
  end

  describe "POST document with attachment (with funky name)" do
    before(:each) do
      @attach = "<html><head><title>My Funky Doc</title></head><body><p>Has words.</p></body></html>"
      @doc = {
        "field" => ["some other value"],
        "_attachments" => {
          "http://example.com/stuff.cgi?things=and%20stuff" => {
            "type" => "text/html",
            "data" => @attach
          }
        }
      }
      @docid = @db.save_doc(@doc)['id']
    end
    it "should save and be indicated" do
      doc = @db.get(@docid)
      expect(doc['_attachments']['http://example.com/stuff.cgi?things=and%20stuff']['length']).to eq @attach.length
    end
    it "should be there" do
      doc = @db.get(@docid)
      attachment = @db.fetch_attachment(doc,"http://example.com/stuff.cgi?things=and%20stuff")
      expect(attachment).to eq @attach
    end
  end

  describe "PUT (new document with url id)" do
    it "should create the document" do
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      expect(lambda{@db.save_doc({'_id' => @docid})}).to raise_error(CouchRest::RequestFailed)
      expect(@db.get(@docid)['will-exist']).to eq 'here'
    end
  end
  
  describe "PUT (new document with id)" do
    it "should start without the document" do
      # r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      @db.documents['rows'].each do |doc|
        expect(doc['id']).not_to eq 'my-doc'
      end
      # should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document" do
      @db.save_doc({'_id' => 'my-doc', 'will-exist' => 'here'})
      expect(lambda{@db.save_doc({'_id' => 'my-doc'})}).to raise_error(CouchRest::RequestFailed)
    end
  end
  
  describe "PUT (existing document with rev)" do
    before(:each) do
      @db.save_doc({'_id' => 'my-doc', 'will-exist' => 'here'})
      @doc = @db.get('my-doc')
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save_doc({'_id' => @docid, 'now' => 'save'})
    end
    it "should start with the document" do
      expect(@doc['will-exist']).to eq 'here'
      expect(@db.get(@docid)['now']).to eq 'save'
    end
    it "should save with url id" do
      doc = @db.get(@docid)
      doc['yaml'] = ['json', 'word.']
      @db.save_doc doc
      expect(@db.get(@docid)['yaml']).to eq ['json', 'word.']
    end
    it "should fail to resave without the rev" do
      @doc['them-keys'] = 'huge'
      @doc['_rev'] = 'wrong'
      # @db.save_doc(@doc)
      expect(lambda {@db.save_doc(@doc)}).to raise_error
    end
    it "should update the document" do
      @doc['them-keys'] = 'huge'
      @db.save_doc(@doc)
      now = @db.get('my-doc')
      expect(now['them-keys']).to eq 'huge'
    end
  end

  describe "cached bulk save" do
    it "stores documents in a database-specific cache" do
      td = {"_id" => "btd1", "val" => "test"}
      @db.save_doc(td, true)
      expect(@db.instance_variable_get("@bulk_save_cache")).to eq [td]
      
    end

    it "doesn't save to the database until the configured cache size is exceded" do
      @db.bulk_save_cache_limit = 3
      td1 = {"_id" => "td1", "val" => true}
      td2 = {"_id" => "td2", "val" => 4}
      @db.save_doc(td1, true)
      @db.save_doc(td2, true)
      expect(@db.get(td1["_id"])).to be_nil
      expect(@db.get(td2["_id"])).to be_nil
      td3 = {"_id" => "td3", "val" => "foo"}
      @db.save_doc(td3, true)
      expect(@db.get(td1["_id"])["val"]).to eq td1["val"]
      expect(@db.get(td2["_id"])["val"]).to eq td2["val"]
      expect(@db.get(td3["_id"])["val"]).to eq td3["val"]
    end

    it "clears the bulk save cache the first time a non bulk save is requested" do
      td1 = {"_id" => "blah", "val" => true}
      td2 = {"_id" => "steve", "val" => 3}
      @db.bulk_save_cache_limit = 50
      @db.save_doc(td1, true)
      expect(@db.get(td1["_id"])).to be_nil
      @db.save_doc(td2)
      expect(@db.get(td1["_id"])["val"]).to eq td1["val"]
      expect(@db.get(td2["_id"])["val"]).to eq td2["val"]
    end
  end

  describe "DELETE existing document" do
    before(:each) do
      @r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
    end
    it "should work" do
      doc = @db.get(@r['id'])
      expect(doc['and']).to eq 'spain'
      @db.delete_doc doc
      expect(@db.get(@r['id'])).to be_nil 
    end
    it "should work with uri id" do
      doc = @db.get(@docid)
      @db.delete_doc doc
      expect(@db.get @docid).to be_nil
    end
    it "should fail without an _id" do
      expect(lambda{@db.delete_doc({"not"=>"a real doc"})}).to raise_error(ArgumentError)
    end
    it "should defer actual deletion when using bulk save" do
      doc = @db.get(@docid)
      @db.delete_doc doc, true
      expect(@db.get @docid).to_not be_nil
      @db.bulk_save
      expect(@db.get @docid).to be_nil
    end
    
  end
  
  describe  "UPDATE existing document" do
    before :each do
      @id = @db.save_doc({
          'article' => 'Pete Doherty Kicked Out For Nazi Anthem',
          'upvotes' => 10,
          'link' => 'http://beatcrave.com/2009-11-30/pete-doherty-kicked-out-for-nazi-anthem/'})['id']
    end
    it "should work under normal conditions" do
      @db.update_doc @id do |doc|
        doc['upvotes'] += 1
      end
      expect(@db.get(@id)['upvotes']).to eq 11
    end
    it "should fail if update_limit is reached" do
      expect do
        @db.update_doc @id do |doc|
          # modify and save the doc so that a collision happens
          conflicting_doc = @db.get @id
          conflicting_doc['upvotes'] += 1
          @db.save_doc conflicting_doc

          # then try saving it through the update
          doc['upvotes'] += 1
        end
      end.to raise_error(CouchRest::RequestFailed)
    end
    it "should not fail if update_limit is not reached" do
      limit = 5
      expect do
        @db.update_doc @id do |doc|
          # same as the last spec except we're only forcing 5 conflicts
          if limit > 0
            conflicting_doc = @db.get @id
            conflicting_doc['upvotes'] += 1
            @db.save_doc conflicting_doc
            limit -= 1
          end
          doc['upvotes'] += 1
          doc
        end
      end.not_to raise_error
      expect(@db.get(@id)['upvotes']).to eq 16
    end
  end
  
  describe "COPY existing document" do
    before :each do
      @r = @db.save_doc({'artist' => 'Zappa', 'title' => 'Muffin Man'})
      @docid = 'tracks/zappa/muffin-man'
      @doc = @db.get(@r['id'])
    end
    describe "to a new location" do
      it "should work" do
        @db.copy_doc @doc, @docid
        newdoc = @db.get(@docid)
        expect(newdoc['artist']).to eq 'Zappa'
      end
      it "should fail without an _id" do
        expect(lambda{@db.copy_doc({"not"=>"a real doc"})}).to raise_error(ArgumentError)
      end
    end
    describe "to an existing location" do
      before :each do
        @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      end
      it "should fail without a rev" do
        expect(lambda{@db.copy_doc @doc, @docid}).to raise_error(CouchRest::RequestFailed)
      end
      it "should succeed with a rev" do
        @to_be_overwritten = @db.get(@docid)
        @db.copy_doc @doc, "#{@docid}?rev=#{@to_be_overwritten['_rev']}"
        newdoc = @db.get(@docid)
        expect(newdoc['artist']).to eq 'Zappa'
      end
      it "should succeed given the doc to overwrite" do
        @to_be_overwritten = @db.get(@docid)
        @db.copy_doc @doc, @to_be_overwritten
        newdoc = @db.get(@docid)
        expect(newdoc['artist']).to eq 'Zappa'
      end
    end
  end
  
  
  it "should list documents" do
    5.times do
      @db.save_doc({'another' => 'doc', 'will-exist' => 'anywhere'})
    end
    ds = @db.documents
    expect(ds['rows']).to be_an_instance_of(Array)
    expect(ds['rows'][0]['id']).not_to be_nil
    expect(ds['total_rows']).to eq 5
  end
  
  # This is redundant with the latest view code, but left in place for prosterity.
  describe "documents / _all_docs" do
    before(:each) do
      9.times do |i|
        @db.save_doc({'_id' => "doc#{i}",'another' => 'doc', 'will-exist' => 'here'})
      end
    end
    it "should list documents with keys and such" do
      ds = @db.documents
      expect(ds['rows']).to be_an_instance_of(Array)
      expect(ds['rows'][0]['id']).to eq "doc0"
      expect(ds['total_rows']).to eq 9      
    end
    it "should take query params" do
      ds = @db.documents(:startkey => 'doc0', :endkey => 'doc3')
      expect(ds['rows'].length).to eq 4
      ds = @db.documents(:key => 'doc0')
      expect(ds['rows'].length).to eq 1
    end
    it "should work with multi-key" do
      rs = @db.documents :keys => ["doc0", "doc7"]
      expect(rs['rows'].length).to eq 2
    end
    it "should work with include_docs" do
      ds = @db.documents(:startkey => 'doc0', :endkey => 'doc3', :include_docs => true)
      expect(ds['rows'][0]['doc']['another']).to eq "doc"
    end
    it "should have the bulk_load macro" do
      rs = @db.bulk_load ["doc0", "doc7"]
      expect(rs['rows'].length).to eq 2
      expect(rs['rows'][0]['doc']['another']).to eq "doc"
    end
  end
  

  describe "#compact" do
    # Can cause failures in recent versions of CouchDB, just ensure
    # we actually send the right command.
    it "should compact the database" do
      db = @cr.database('couchrest-test')
      expect(db.connection).to receive(:post).with("/couchrest-test/_compact")
      db.compact!
    end
  end

  describe "deleting a database" do
    it "should start with the test database" do
      expect(@cr.databases).to include('couchrest-test')
    end
    it "should delete the database" do
      db = @cr.database('couchrest-test')
      r = db.delete!
      expect(r['ok']).to be_true
      expect(@cr.databases).not_to include('couchrest-test')
    end
  end

  #
  # Replicating databases is often a time consuming process, so instead of
  # trying to send commands to CouchDB, we just validate that the post
  # command contains the correct parameters.
  #

  describe "simply replicating a database" do
    before(:each) do
      @other_db = @cr.database(REPLICATIONDB)
    end

    it "should replicate via pulling" do
      expect(@other_db.connection).to receive(:post).with(
        include("_replicate"),
        include(
          :create_target => false,
          :continuous    => false,
          :source        => "#{@cr.uri}/#{@db.name}",
          :target        => @other_db.name
        )
      )
      @other_db.replicate_from @db
    end

    it "should replicate via pushing" do
      expect(@db.connection).to receive(:post).with(
        include("_replicate"),
        include(
          :create_target => false,
          :continuous    => false,
          :source        => @db.name,
          :target        => "#{@cr.uri}/#{@other_db.name}"
        )
      )
      @db.replicate_to @other_db
    end

    it "should replacicate with a specific doc" do
      expect(@db.connection).to receive(:post).with(
        include("_replicate"),
        include(
          :create_target => false,
          :continuous    => false,
          :doc_ids       => ['test_doc'],
          :source        => @db.name,
          :target        => "#{@cr.uri}/#{@other_db.name}"
        )
      )
      @db.replicate_to @other_db, false, false, ['test_doc']
    end

    describe "implicitly creating target" do
      it "should replicate via pulling" do
        expect(@other_db.connection).to receive(:post).with(
          include("_replicate"),
          include(
            :create_target => true,
            :continuous    => false
          )
        )
        @other_db.replicate_from(@db, false, true)
      end

      it "should replicate via pushing" do
        expect(@db.connection).to receive(:post).with(
          include("_replicate"),
          include(
            :create_target => true,
            :continuous    => false
          )
        )
        @db.replicate_to(@other_db, false, true)
      end
    end

    describe "continuous replication" do
      it "should replicate via pulling" do
        expect(@other_db.connection).to receive(:post).with(
          include("_replicate"),
          include(
            :create_target => false,
            :continuous    => true
          )
        )
        @other_db.replicate_from(@db, true)
      end

      it "should replicate via pushing" do
        expect(@db.connection).to receive(:post).with(
          include("_replicate"),
          include(
            :create_target => false,
            :continuous    => true
          )
        )
        @db.replicate_to(@other_db, true)
      end
    end
  end


  describe "#create!" do
    before(:each) do
      @db = @cr.database('couchrest-test-db_to_create')
      @db.delete! if @cr.databases.include?('couchrest-test-db_to_create')
    end

    it "should just work fine" do
      expect(@cr.databases).not_to include('couchrest-test-db_to_create')
      @db.create!
      expect(@cr.databases).to include('couchrest-test-db_to_create')
    end
  end

  describe "#recreate!" do
    before(:each) do
      @db = @cr.database('couchrest-test-db_to_create')
      @db2 = @cr.database('couchrest-test-db_to_recreate')
      @cr.databases.include?(@db.name) ? nil : @db.create!
      @cr.databases.include?(@db2.name) ? @db2.delete! : nil
    end

    it "should drop and recreate a database" do
       expect(@cr.databases).to include(@db.name)
       @db.recreate!
       expect(@cr.databases).to include(@db.name)
    end

    it "should recreate a db even though it doesn't exist" do
      expect(@cr.databases).not_to include(@db2.name)
      @db2.recreate!
      expect(@cr.databases).to include(@db2.name)
    end
  end

  describe "searching a database" do
    before(:each) do
      search_function = { 'defaults' => {'store' => 'no', 'index' => 'analyzed_no_norms'},
          'index' => "function(doc) { ret = new Document(); ret.add(doc['name'], {'field':'name'}); ret.add(doc['age'], {'field':'age'}); return ret; }" }
      @db.save_doc({'_id' => '_design/search', 'fulltext' => {'people' => search_function}})
      @db.save_doc({'_id' => 'john', 'name' => 'John', 'age' => '31'})
      @db.save_doc({'_id' => 'jack', 'name' => 'Jack', 'age' => '32'})
      @db.save_doc({'_id' => 'dave', 'name' => 'Dave', 'age' => '33'})
    end

    it "should be able to search a database using couchdb-lucene" do
      if couchdb_lucene_available?
        result = @db.search('search/people', :q => 'name:J*')
        doc_ids = result['rows'].collect{ |row| row['id'] }
        expect(doc_ids.size).to eq 2
        expect(doc_ids).to include('john')
        expect(doc_ids).to include('jack')
      end
    end
  end

end
