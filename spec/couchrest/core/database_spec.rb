require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::Database do
  before(:each) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
  end

  describe "database name including slash" do
    it "should escape the name in the URI" do
      db = @cr.database("foo/bar")
      db.name.should == "foo/bar"
      db.root.should == "#{COUCHHOST}/foo%2Fbar"
      db.uri.should  == "/foo%2Fbar"
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
      rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length.should == 1
    end
    it "should work with a range" do
      rs = @db.temp_view(@temp_view, :startkey => "b", :endkey => "z")
      rs['rows'].length.should == 2
    end
    it "should work with a key" do
      rs = @db.temp_view(@temp_view, :key => "wild")
      rs['rows'].length.should == 1
    end
    it "should work with a limit" do
      rs = @db.temp_view(@temp_view, :limit => 1)
      rs['rows'].length.should == 1
    end
    it "should work with multi-keys" do
      rs = @db.temp_view(@temp_view, :keys => ["another", "wild"])
      rs['rows'].length.should == 2
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
      # rs.should == 'x'
      rs['rows'][0]['value'].should == 9
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
      r['total_rows'].should == 1
    end
    it "should round trip" do
      @db.get("_design/test")['views'].should == @view
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
      @db.get('_design/first')['views']['test']['map'].should include("for(var w in doc)")
    end
    it "should list from the view" do
      rs = @db.view('first/test')
      rs['rows'].select{|r|r['key'] == 'wild' && r['value'] == 'and random'}.length.should == 1
    end
    it "should work with a range" do
      rs = @db.view('first/test', :startkey => "b", :endkey => "z")
      rs['rows'].length.should == 2
    end
    it "should work with a key" do
      rs = @db.view('first/test', :key => "wild")
      rs['rows'].length.should == 1
    end
    it "should work with a limit" do
      rs = @db.view('first/test', :limit => 1)
      rs['rows'].length.should == 1
    end
    it "should work with multi-keys" do
      rs = @db.view('first/test', :keys => ["another", "wild"])
      rs['rows'].length.should == 2
    end
    it "should accept a block" do
      rows = []
      rs = @db.view('first/test', :include_docs => true) do |row|
        rows << row
      end
      rows.length.should == 3
      rs["total_rows"].should == 3
    end
    it "should accept a block with several params" do
      rows = []
      rs = @db.view('first/test', :include_docs => true, :limit => 2) do |row|
        rows << row
      end
      rows.length.should == 2
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
      rs.each do |r|
        @db.get(r['id']).rev.should == r["rev"]
      end
    end
    
    it "should use uuids when ids aren't provided" do
      @db.server.stub!(:next_uuid).and_return('asdf6sgadkfhgsdfusdf')
      
      docs = [{'key' => 'value'}, {'_id' => 'totally-uniq'}]
      id_docs = [{'key' => 'value', '_id' => 'asdf6sgadkfhgsdfusdf'}, {'_id' => 'totally-uniq'}]
      CouchRest.should_receive(:post).with("http://127.0.0.1:5984/couchrest-test/_bulk_docs", {:docs => id_docs})
      
      @db.bulk_save(docs)
    end
    
    it "should add them with uniq ids" do
      rs = @db.bulk_save([
          {"_id" => "oneB", "wild" => "and random"},
          {"_id" => "twoB", "mild" => "yet local"},
          {"another" => ["set","of","keys"]}
        ])
      rs.each do |r|
        @db.get(r['id']).rev.should == r["rev"]
      end
    end

    it "should empty the bulk save cache if no documents are given" do
      @db.save_doc({"_id" => "bulk_cache_1", "val" => "test"}, true)
      lambda do
        @db.get('bulk_cache_1')
      end.should raise_error(RestClient::ResourceNotFound)
      @db.bulk_save
      @db.get("bulk_cache_1")["val"].should == "test"
    end

    it "should raise an error that is useful for recovery" do
      @r = @db.save_doc({"_id" => "taken", "field" => "stuff"})
      begin
        rs = @db.bulk_save([
            {"_id" => "taken", "wild" => "and random"},
            {"_id" => "free", "mild" => "yet local"},
            {"another" => ["set","of","keys"]}
          ])
      rescue RestClient::RequestFailed => e
        # soon CouchDB will provide _which_ docs conflicted
        JSON.parse(e.response.body)['error'].should == 'conflict'
      end
    end
  end
  
  describe "new document without an id" do
    it "should start empty" do
      @db.documents["total_rows"].should == 0
    end
    it "should create the document and return the id" do
      r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      r2 = @db.get(r['id'])
      r2["lemons"].should == "from texas"
    end
    it "should use PUT with UUIDs" do
      CouchRest.should_receive(:put).and_return({"ok" => true, "id" => "100", "rev" => "55"})
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
    #   @db.fetch_attachment("mydocwithattachment", "test.html").should == @attach
    # end
    
    it "should get the attachment with the doc itself" do
      @db.fetch_attachment(@db.get('mydocwithattachment'), 'test.html').should == @attach
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
      r['ok'].should == true
      doc = @db.get("attach-this")
      attachment = @db.fetch_attachment(doc,"couchdb.png")
      if attachment.respond_to?(:net_http_res)  
        attachment.net_http_res.body.should == image
      else
        attachment.should == image
      end
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
      @doc['_attachments']['test.html']['length'].should == @attach.length
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"test.html")
      attachment.should == @attach
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
      doc['_rev'].should_not be_nil
      doc['field'] << 'another value'
      @db.save_doc(doc)["ok"].should be_true
    end
    
    it 'should be there' do
      doc = @db.get('mydocwithattachment')
      attachment = @db.fetch_attachment(doc, 'test.html')
      Base64.decode64(attachment).should == @attach
    end
  end

  describe "PUT document with multiple attachments" do
    before(:each) do
      @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
      @attach2 = "<html><head><title>Other Doc</title></head><body><p>Has more words.</p></body></html>"
      @doc = {
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
      @db.save_doc(@doc)
      @doc = @db.get("mydocwithattachment")
    end
    it "should save and be indicated" do
      @doc['_attachments']['test.html']['length'].should == @attach.length
      @doc['_attachments']['other.html']['length'].should == @attach2.length
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"test.html")
      attachment.should == @attach
    end
    it "should be there" do
      attachment = @db.fetch_attachment(@doc,"other.html")
      attachment.should == @attach2
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
      lambda { @db.fetch_attachment(@doc,'test.html') }.should_not raise_error
      @db.delete_attachment(@doc, "test.html")  
      @doc = @db.get('mydocwithattachment') # avoid getting a 409
      lambda{ @db.fetch_attachment(@doc,'test.html')}.should raise_error
    end
    
    it "should force a delete even if we get a 409" do
      @doc['new_attribute'] = 'something new'
      @db.put_attachment(@doc, 'test', File.open(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'attachments', 'test.html')).read)
      # at this point the revision number changed, if we try to save doc one more time
      # we would get a 409.
      lambda{ @db.save_doc(@doc) }.should raise_error
      lambda{ @db.delete_attachment(@doc, "test", true) }.should_not raise_error
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
      doc['_attachments']['http://example.com/stuff.cgi?things=and%20stuff']['length'].should == @attach.length
    end
    it "should be there" do
      doc = @db.get(@docid)
      attachment = @db.fetch_attachment(doc,"http://example.com/stuff.cgi?things=and%20stuff")
      attachment.should == @attach
    end
  end

  describe "PUT (new document with url id)" do
    it "should create the document" do
      @docid = "http://example.com/stuff.cgi?things=and%20stuff"
      @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      lambda{@db.save_doc({'_id' => @docid})}.should raise_error(RestClient::Request::RequestFailed)
      @db.get(@docid)['will-exist'].should == 'here'
    end
  end
  
  describe "PUT (new document with id)" do
    it "should start without the document" do
      # r = @db.save_doc({'lemons' => 'from texas', 'and' => 'spain'})
      @db.documents['rows'].each do |doc|
        doc['id'].should_not == 'my-doc'
      end
      # should_not include({'_id' => 'my-doc'})
      # this needs to be a loop over docs on content with the post
      # or instead make it return something with a fancy <=> method
    end
    it "should create the document" do
      @db.save_doc({'_id' => 'my-doc', 'will-exist' => 'here'})
      lambda{@db.save_doc({'_id' => 'my-doc'})}.should raise_error(RestClient::Request::RequestFailed)
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
      @doc['will-exist'].should == 'here'
      @db.get(@docid)['now'].should == 'save'
    end
    it "should save with url id" do
      doc = @db.get(@docid)
      doc['yaml'] = ['json', 'word.']
      @db.save_doc doc
      @db.get(@docid)['yaml'].should == ['json', 'word.']
    end
    it "should fail to resave without the rev" do
      @doc['them-keys'] = 'huge'
      @doc['_rev'] = 'wrong'
      # @db.save_doc(@doc)
      lambda {@db.save_doc(@doc)}.should raise_error
    end
    it "should update the document" do
      @doc['them-keys'] = 'huge'
      @db.save_doc(@doc)
      now = @db.get('my-doc')
      now['them-keys'].should == 'huge'
    end
  end

  describe "cached bulk save" do
    it "stores documents in a database-specific cache" do
      td = {"_id" => "btd1", "val" => "test"}
      @db.save_doc(td, true)
      @db.instance_variable_get("@bulk_save_cache").should == [td]
      
    end

    it "doesn't save to the database until the configured cache size is exceded" do
      @db.bulk_save_cache_limit = 3
      td1 = {"_id" => "td1", "val" => true}
      td2 = {"_id" => "td2", "val" => 4}
      @db.save_doc(td1, true)
      @db.save_doc(td2, true)
      lambda do
        @db.get(td1["_id"])
      end.should raise_error(RestClient::ResourceNotFound)
      lambda do
        @db.get(td2["_id"])
      end.should raise_error(RestClient::ResourceNotFound)
      td3 = {"_id" => "td3", "val" => "foo"}
      @db.save_doc(td3, true)
      @db.get(td1["_id"])["val"].should == td1["val"]
      @db.get(td2["_id"])["val"].should == td2["val"]
      @db.get(td3["_id"])["val"].should == td3["val"]
    end

    it "clears the bulk save cache the first time a non bulk save is requested" do
      td1 = {"_id" => "blah", "val" => true}
      td2 = {"_id" => "steve", "val" => 3}
      @db.bulk_save_cache_limit = 50
      @db.save_doc(td1, true)
      lambda do
        @db.get(td1["_id"])
      end.should raise_error(RestClient::ResourceNotFound)
      @db.save_doc(td2)
      @db.get(td1["_id"])["val"].should == td1["val"]
      @db.get(td2["_id"])["val"].should == td2["val"]
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
      doc['and'].should == 'spain'
      @db.delete_doc doc
      lambda{@db.get @r['id']}.should raise_error
    end
    it "should work with uri id" do
      doc = @db.get(@docid)
      @db.delete_doc doc
      lambda{@db.get @docid}.should raise_error
    end
    it "should fail without an _id" do
      lambda{@db.delete_doc({"not"=>"a real doc"})}.should raise_error(ArgumentError)
    end
    it "should defer actual deletion when using bulk save" do
      doc = @db.get(@docid)
      @db.delete_doc doc, true
      lambda{@db.get @docid}.should_not raise_error
      @db.bulk_save
      lambda{@db.get @docid}.should raise_error
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
        doc
      end
      @db.get(@id)['upvotes'].should == 11
    end
    it "should fail if update_limit is reached" do
      lambda do
        @db.update_doc @id do |doc|
          # modify and save the doc so that a collision happens
          conflicting_doc = @db.get @id
          conflicting_doc['upvotes'] += 1
          @db.save_doc conflicting_doc
        
          # then try saving it through the update
          doc['upvotes'] += 1
          doc
        end
      end.should raise_error(RestClient::RequestFailed)
    end
    it "should not fail if update_limit is not reached" do
      limit = 5
      lambda do
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
      end.should_not raise_error
      @db.get(@id)['upvotes'].should == 16
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
        newdoc['artist'].should == 'Zappa'
      end
      it "should fail without an _id" do
        lambda{@db.copy_doc({"not"=>"a real doc"})}.should raise_error(ArgumentError)
      end
    end
    describe "to an existing location" do
      before :each do
        @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      end
      it "should fail without a rev" do
        lambda{@db.copy_doc @doc, @docid}.should raise_error(RestClient::RequestFailed)
      end
      it "should succeed with a rev" do
        @to_be_overwritten = @db.get(@docid)
        @db.copy_doc @doc, "#{@docid}?rev=#{@to_be_overwritten['_rev']}"
        newdoc = @db.get(@docid)
        newdoc['artist'].should == 'Zappa'
      end
      it "should succeed given the doc to overwrite" do
        @to_be_overwritten = @db.get(@docid)
        @db.copy_doc @doc, @to_be_overwritten
        newdoc = @db.get(@docid)
        newdoc['artist'].should == 'Zappa'
      end
    end
  end
  
  
  it "should list documents" do
    5.times do
      @db.save_doc({'another' => 'doc', 'will-exist' => 'anywhere'})
    end
    ds = @db.documents
    ds['rows'].should be_an_instance_of(Array)
    ds['rows'][0]['id'].should_not be_nil
    ds['total_rows'].should == 5
  end
  
  describe "documents / _all_docs" do
    before(:each) do
      9.times do |i|
        @db.save_doc({'_id' => "doc#{i}",'another' => 'doc', 'will-exist' => 'here'})
      end
    end
    it "should list documents with keys and such" do
      ds = @db.documents
      ds['rows'].should be_an_instance_of(Array)
      ds['rows'][0]['id'].should == "doc0"
      ds['total_rows'].should == 9      
    end
    it "should take query params" do
      ds = @db.documents(:startkey => 'doc0', :endkey => 'doc3')
      ds['rows'].length.should == 4
      ds = @db.documents(:key => 'doc0')
      ds['rows'].length.should == 1
    end
    it "should work with multi-key" do
      rs = @db.documents :keys => ["doc0", "doc7"]
      rs['rows'].length.should == 2
    end
    it "should work with include_docs" do
      ds = @db.documents(:startkey => 'doc0', :endkey => 'doc3', :include_docs => true)
      ds['rows'][0]['doc']['another'].should == "doc"
    end
    it "should have the bulk_load macro" do
      rs = @db.bulk_load ["doc0", "doc7"]
      rs['rows'].length.should == 2
      rs['rows'][0]['doc']['another'].should == "doc"
    end
  end
  

  describe "compacting a database" do
    it "should compact the database" do
      db = @cr.database('couchrest-test')
      # r = 
      db.compact!
      # r['ok'].should == true
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
  
  describe "replicating a database" do
    before do
      @db.save_doc({'_id' => 'test_doc', 'some-value' => 'foo'})
      @other_db = @cr.database 'couchrest-test-replication'
      @other_db.delete! rescue nil
      @other_db = @cr.create_db 'couchrest-test-replication'
    end

    describe "via pulling" do
      before do
        @other_db.replicate_from @db
      end
      
      it "contains the document from the original database" do
        doc = @other_db.get('test_doc')
        doc['some-value'].should == 'foo'
      end
    end
    
    describe "via pushing" do
      before do
        @db.replicate_to @other_db
      end
      
      it "copies the document to the other database" do
        doc = @other_db.get('test_doc')
        doc['some-value'].should == 'foo'
      end
    end
  end

  describe "creating a database" do
    before(:each) do
      @db = @cr.database('couchrest-test-db_to_create')
      @db.delete! if @cr.databases.include?('couchrest-test-db_to_create')
    end
    
    it "should just work fine" do
      @cr.databases.should_not include('couchrest-test-db_to_create')
      @db.create!
      @cr.databases.should include('couchrest-test-db_to_create')
    end
  end
  
  describe "recreating a database" do
    before(:each) do
      @db = @cr.database('couchrest-test-db_to_create')
      @db2 = @cr.database('couchrest-test-db_to_recreate')
      @cr.databases.include?(@db.name) ? nil : @db.create!
      @cr.databases.include?(@db2.name) ? @db2.delete! : nil
    end
    
    it "should drop and recreate a database" do
       @cr.databases.should include(@db.name)
       @db.recreate!
       @cr.databases.should include(@db.name)
    end
    
    it "should recreate a db even tho it doesn't exist" do
      @cr.databases.should_not include(@db2.name)
      @db2.recreate!
      @cr.databases.should include(@db2.name)
    end
    
  end


end
