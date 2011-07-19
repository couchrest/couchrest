require File.expand_path("../../spec_helper", __FILE__)

class Video < CouchRest::Document; end

describe CouchRest::Document do
  
  before(:all) do
    @couch = CouchRest.new
    @db    = @couch.database!(TESTDB)
  end

  describe "#new" do
    it "should not be a Hash" do
      @doc = CouchRest::Document.new
      @doc.class.should eql(CouchRest::Document)
      @doc.is_a?(Hash).should be_false
    end

    it "should be possible to initialize a new Document with attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar', :test => 'foo')
      @doc['foo'].should eql('bar')
      @doc['test'].should eql('foo')
    end

    it "should accept new with _id" do
      @doc = CouchRest::Document.new('_id' => 'sample', 'foo' => 'bar')
      @doc['_id'].should eql('sample')
      @doc['foo'].should eql('bar')
    end

    context "replacing initalize" do
      it "should not raise error" do
        klass = Class.new(CouchRest::Document)
        klass.class_eval do
          def initialize; end # don't do anything, just overwrite
        end
        expect {
          @doc = klass.new
          @doc['test'] = 'sample'
        }.to_not raise_error
      end
    end
  end


  describe "hash methods" do
    it "should respond to forwarded hash methods" do
      @doc = CouchRest::Document.new(:foo => 'bar')
      [:to_a, :==, :eql?, :keys, :values, :each, :reject, :reject!, :empty?,
        :clear, :merge, :merge!, :encode_json, :as_json, :to_json, :frozen?].each do |call|
        @doc.should respond_to(call)
      end
    end
  end

  describe "[]=" do
    before(:each) do
      @doc = CouchRest::Document.new
    end
    it "should work" do
      @doc["enamel"].should == nil
      @doc["enamel"] = "Strong"
      @doc["enamel"].should == "Strong"
    end
    it "[]= should convert to string" do
      @doc["enamel"].should == nil
      @doc[:enamel] = "Strong"
      @doc["enamel"].should == "Strong"
    end
    it "should read as a string" do
      @doc[:enamel] = "Strong"
      @doc[:enamel].should == "Strong"
    end
  end

  describe "#has_key?" do
    before :each do
      @doc = CouchRest::Document.new
    end
    it "should confirm existance of key" do
      @doc[:test] = 'example'
      @doc.has_key?('test').should be_true
      @doc.has_key?(:test).should be_true
    end
    it "should deny existance of key" do
      @doc.has_key?(:bardom).should be_false
      @doc.has_key?('bardom').should be_false
    end
  end

  describe "#dup" do
    it "should also clone the attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc2 = @doc.dup
      @doc2.delete('foo')
      @doc2['foo'].should be_nil
      @doc['foo'].should eql('bar')
    end
  end

  describe "#clone" do
    it "should also clone the attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc2 = @doc.clone
      @doc2.delete('foo')
      @doc2['foo'].should be_nil
      @doc['foo'].should eql('bar')
    end
  end

  describe "#freeze" do
    it "should freeze the attributes, but not actual model" do
      klass = Class.new(CouchRest::Document)
      klass.class_eval { attr_accessor :test_attr }
      @doc = klass.new('foo' => 'bar')
      @doc.freeze
      lambda { @doc['foo'] = 'bar2' }.should raise_error(/frozen/)
      lambda { @doc.test_attr = "bar3" }.should_not raise_error
    end
  end

  describe "#as_couch_json" do
    it "should provide a hash of data from normal document" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      h = @doc.as_couch_json
      h.should be_a(Hash)
      h['foo'].should eql('bar')
    end

    it "should handle nested documents" do
      @doc = CouchRest::Document.new('foo' => 'bar', 'doc' => CouchRest::Document.new('foo2' => 'bar2'))
      h = @doc.as_couch_json
      h['doc'].should be_a(Hash)
      h['doc']['foo2'].should eql('bar2')
    end
  end

  describe "#inspect" do
    it "should provide a string of keys and values of the Response" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc.inspect.should eql("#<CouchRest::Document foo: \"bar\">")
    end
  end

  describe "responding to Hash methods" do
    it "should delegate requests" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc.keys.should eql(['foo'])
      @doc.values.should eql(['bar'])
    end
  end

  describe  "default database" do
    before(:each) do
      Video.use_database nil
    end
    it "should be set using use_database on the model" do
      Video.new.database.should be_nil
      Video.use_database @db
      Video.new.database.should == @db
      Video.use_database nil
    end
    
    it "should be overwritten by instance" do
      db = @couch.database('test')
      article = Video.new
      article.database.should be_nil
      article.database = db
      article.database.should_not be_nil
      article.database.should == db
    end
  end

  describe  "new" do
    before(:each) do
      @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")    
    end
    it "should create itself from a Hash" do
      @doc["key"].should == [1,2,3]
      @doc["more"].should == "values"
    end
    it "should not have rev and id" do
      @doc.rev.should be_nil
      @doc.id.should be_nil
    end
    it "should be possible to set id" do
      @doc.id = 1
      @doc.id.should eql(1)
    end
    
    it "should freak out when saving without a database" do
      lambda{@doc.save}.should raise_error(ArgumentError)
    end
    
  end

  # move to database spec
  describe  "saving using a database" do
    before(:all) do
      @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")    
      @db = reset_test_db!    
      @resp = @db.save_doc(@doc)
    end
    it "should apply the database" do
      @doc.database.should == @db    
    end
    it "should get id and rev" do
      @doc.id.should == @resp["id"]
      @doc.rev.should == @resp["rev"]
    end
    it "should generate a correct URI" do
      @doc.uri.should == "#{@db.root}/#{@doc.id}"
      URI.parse(@doc.uri).to_s.should == @doc.uri
    end
    it "should generate a correct URI with revision" do
      @doc.uri(true).should == "#{@db.root}/#{@doc.id}?rev=#{@doc.rev}"
      URI.parse(@doc.uri(true)).to_s.should == @doc.uri(true)
    end
  end

  describe  "bulk saving" do
    before :all do
      @db = reset_test_db!
    end

    it "should use the document bulk save cache" do
      doc = CouchRest::Document.new({"_id" => "bulkdoc", "val" => 3})
      doc.database = @db
      doc.save(true)
      lambda { doc.database.get(doc["_id"]) }.should raise_error(RestClient::ResourceNotFound)
      doc.database.bulk_save
      doc.database.get(doc["_id"])["val"].should == doc["val"]
    end
  end

  describe "getting from a database" do
    before(:all) do
      @db = reset_test_db!
      @resp = @db.save_doc({
        "key" => "value"
      })
      @doc = @db.get @resp['id']
    end
    it "should return a document" do
      @doc.should be_an_instance_of(CouchRest::Document)
    end
    it "should have a database" do
      @doc.database.should == @db
    end
    it "should be saveable and resavable" do
      @doc["more"] = "keys"
      @doc.save
      @db.get(@resp['id'])["more"].should == "keys"
      @doc["more"] = "these keys"    
      @doc.save
      @db.get(@resp['id'])["more"].should == "these keys"
    end
  end

  describe "destroying a document from a db" do
    before(:all) do
      @db = reset_test_db!
      @resp = @db.save_doc({
        "key" => "value"
      })
      @doc = @db.get @resp['id']
    end
    it "should make it disappear" do
      @doc.destroy
      lambda{@db.get @resp['id']}.should raise_error
    end
    it "should error when there's no db" do
      @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")    
      lambda{@doc.destroy}.should raise_error(ArgumentError)
    end
  end


  describe "destroying a document from a db using bulk save" do
    before(:all) do
      @db = reset_test_db!
      @resp = @db.save_doc({
        "key" => "value"
      })
      @doc = @db.get @resp['id']
    end
    it "should defer actual deletion" do
      @doc.destroy(true)
      @doc['_id'].should == nil
      @doc['_rev'].should == nil
      lambda{@db.get @resp['id']}.should_not raise_error
      @db.bulk_save
      lambda{@db.get @resp['id']}.should raise_error
    end
  end

  describe "copying a document" do
    before :each do
      @db = reset_test_db!
      @resp = @db.save_doc({'key' => 'value'})
      @docid = 'new-location'
      @doc = @db.get(@resp['id'])
    end
    describe "to a new location" do
      it "should work" do
        @doc.copy @docid
        newdoc = @db.get(@docid)
        newdoc['key'].should == 'value'
      end
      it "should fail without a database" do
        lambda{CouchRest::Document.new({"not"=>"a real doc"}).copy}.should raise_error(ArgumentError)
      end
    end
    describe "to an existing location" do
      before :each do
        @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      end
      it "should fail without a rev" do
        lambda{@doc.copy @docid}.should raise_error(RestClient::RequestFailed)
      end
      it "should succeed with a rev" do
        @to_be_overwritten = @db.get(@docid)
        @doc.copy "#{@docid}?rev=#{@to_be_overwritten['_rev']}"
        newdoc = @db.get(@docid)
        newdoc['key'].should == 'value'
      end
      it "should succeed given the doc to overwrite" do
        @to_be_overwritten = @db.get(@docid)
        @doc.copy @to_be_overwritten
        newdoc = @db.get(@docid)
        newdoc['key'].should == 'value'
      end
    end
  end
end

describe "dealing with attachments" do
  before do
    @db = reset_test_db!
    @attach = "<html><head><title>My Doc</title></head><body><p>Has words.</p></body></html>"
    response = @db.save_doc({'key' => 'value'})
    @doc = @db.get(response['id'])
  end

  def append_attachment(name='test.html', attach=@attach)
    @doc['_attachments'] ||= {}
    @doc['_attachments'][name] = {
      'type' => 'text/html',
      'data' => attach
    }
    @doc.save
    @rev = @doc['_rev']
  end

  describe "PUTing an attachment directly to the doc" do
    before do
      @doc.put_attachment('test.html', @attach)
    end

    it "is there" do
      @db.fetch_attachment(@doc, 'test.html').should == @attach
    end

    it "updates the revision" do
      @doc[:_rev].should_not == @rev
    end

    it "updates attachments" do
      @attach2 = "<html><head><title>My Doc</title></head><body><p>Is Different.</p></body></html>"
      @doc.put_attachment('test.html', @attach2)
      @db.fetch_attachment(@doc, 'test.html').should == @attach2
    end
  end

  describe "fetching an attachment from a doc directly" do
    before do
      append_attachment
    end

    it "pulls the attachment" do
      @doc.fetch_attachment('test.html').should == @attach
    end
  end

  describe "deleting an attachment from a doc directly" do
    before do
      append_attachment
      @doc.delete_attachment('test.html')
    end

    it "removes it" do
      lambda { @db.fetch_attachment(@doc, 'test.html').should }.should raise_error(RestClient::ResourceNotFound)
    end

    it "updates the revision" do
      @doc[:_rev].should_not == @rev
    end
  end

end
