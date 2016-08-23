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
      expect(@doc.class).to eql(CouchRest::Document)
      expect(@doc.is_a?(Hash)).to be_false
    end

    it "should be possible to initialize a new Document with attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar', :test => 'foo')
      expect(@doc['foo']).to eql('bar')
      expect(@doc['test']).to eql('foo')
    end

    it "should accept new with _id" do
      @doc = CouchRest::Document.new('_id' => 'sample', 'foo' => 'bar')
      expect(@doc['_id']).to eql('sample')
      expect(@doc['foo']).to eql('bar')
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
        expect(@doc).to respond_to(call)
      end
    end
  end

  describe "[]=" do
    before(:each) do
      @doc = CouchRest::Document.new
    end
    it "should work" do
      expect(@doc["enamel"]).to be_nil
      @doc["enamel"] = "Strong"
      expect(@doc["enamel"]).to eql "Strong"
    end
    it "[]= should convert to string" do
      expect(@doc["enamel"]).to be_nil
      @doc[:enamel] = "Strong"
      expect(@doc["enamel"]).to eql "Strong"
    end
    it "should read as a string" do
      @doc[:enamel] = "Strong"
      expect(@doc[:enamel]).to eql "Strong"
    end
  end

  describe "#key?" do
    before :each do
      @doc = CouchRest::Document.new
    end
    it "should confirm existance of key" do
      @doc[:test] = 'example'
      expect(@doc.key?('test')).to be_true
      expect(@doc.key?(:test)).to be_true
    end
    it "should deny existance of key" do
      expect(@doc.key?(:bardom)).to be_false
      expect(@doc.key?('bardom')).to be_false
    end
  end

  describe "#has_key?" do
    it 'calls #key?' do
      @doc = CouchRest::Document.new
      expect(@doc).to receive(:key?).with(:test)
      @doc.has_key? :test
    end
  end

  describe "#dup" do
    it "should also clone the attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc2 = @doc.dup
      @doc2.delete('foo')
      expect(@doc2['foo']).to be_nil
      expect(@doc['foo']).to eql('bar')
    end
  end

  describe "#clone" do
    it "should also clone the attributes" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      @doc2 = @doc.clone
      @doc2.delete('foo')
      expect(@doc2['foo']).to be_nil
      expect(@doc['foo']).to eql('bar')
    end
  end

  describe "#freeze" do
    it "should freeze the attributes, but not actual model" do
      klass = Class.new(CouchRest::Document)
      klass.class_eval { attr_accessor :test_attr }
      @doc = klass.new('foo' => 'bar')
      @doc.freeze
      expect(lambda { @doc['foo'] = 'bar2' }).to raise_error(/frozen/)
      expect(lambda { @doc.test_attr = "bar3" }).not_to raise_error
    end
  end

  describe "#as_couch_json" do
    it "should provide a hash of data from normal document" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      h = @doc.as_couch_json
      expect(h).to be_a(Hash)
      expect(h['foo']).to eql('bar')
    end

    it "should handle nested documents" do
      @doc = CouchRest::Document.new('foo' => 'bar', 'doc' => CouchRest::Document.new('foo2' => 'bar2'))
      h = @doc.as_couch_json
      expect(h['doc']).to be_a(Hash)
      expect(h['doc']['foo2']).to eql('bar2')
    end
  end

  describe "#inspect" do
    it "should provide a string of keys and values of the Response" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      expect(@doc.inspect).to eql("#<CouchRest::Document foo: \"bar\">")
    end
  end

  describe "responding to Hash methods" do
    it "should delegate requests" do
      @doc = CouchRest::Document.new('foo' => 'bar')
      expect(@doc.keys).to eql(['foo'])
      expect(@doc.values).to eql(['bar'])
    end
  end

  describe  "default database" do
    before(:each) do
      Video.use_database nil
    end
    it "should be set using use_database on the model" do
      expect(Video.new.database).to be_nil
      Video.use_database @db
      expect(Video.new.database).to eql @db
      Video.use_database nil
    end

    it "should be overwritten by instance" do
      db = @couch.database('test')
      article = Video.new
      expect(article.database).to be_nil
      article.database = db
      expect(article.database).not_to be_nil
      expect(article.database).to eql db
    end
  end

  describe  "new" do
    before(:each) do
      @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")
    end
    it "should create itself from a Hash" do
      expect(@doc["key"]).to eql [1,2,3]
      expect(@doc["more"]).to eql "values"
    end
    it "should not have rev and id" do
      expect(@doc.rev).to be_nil
      expect(@doc.id).to be_nil
    end
    it "should be possible to set id" do
      @doc.id = 1
      expect(@doc.id).to eql(1)
    end

    it "should freak out when saving without a database" do
      expect(lambda{@doc.save}).to raise_error(ArgumentError)
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
      expect(@doc.database).to eql @db
    end
    it "should get id and rev" do
      expect(@doc.id).to eql @resp["id"]
      expect(@doc.rev).to eql @resp["rev"]
    end
    it "should generate a correct URI" do
      expect(@doc.uri).to eql "#{@db.root}/#{@doc.id}"
      expect(URI.parse(@doc.uri).to_s).to eql @doc.uri
    end
    it "should generate a correct URI with revision" do
      expect(@doc.uri(true)).to eql "#{@db.root}/#{@doc.id}?rev=#{@doc.rev}"
      expect(URI.parse(@doc.uri(true)).to_s).to eql @doc.uri(true)
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
      expect(doc.database.get(doc["_id"])).to be_nil
      doc.database.bulk_save
      expect(doc.database.get(doc["_id"])["val"]).to eql doc["val"]
    end

    it "should update the revisions of the saved documents" do
      doc = CouchRest::Document.new({"_id" => "bulkdoc1", "val" => 3})
      doc.database = @db
      doc.save(true)
      doc.database.bulk_save
      expect(doc.database.get(doc["_id"])["_rev"]).to eql doc["_rev"]
    end

    it "should not update the revisions of documents that aren't saved successfully" do
      doc1 = CouchRest::Document.new({"_id" => "bulkdoc", "val" => 3})
      doc2 = CouchRest::Document.new({"_id" => "bulkdoc2", "val" => 3})
      doc1.database = @db
      doc2.database = @db
      doc1.save(true)
      doc2.save(true)
      @db.bulk_save
      expect(doc1["_rev"]).to be_nil
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
      expect(@doc).to be_an_instance_of(CouchRest::Document)
    end
    it "should have a database" do
      expect(@doc.database).to eql @db
    end
    it "should be saveable and resavable" do
      @doc["more"] = "keys"
      @doc.save
      expect(@db.get(@resp['id'])["more"]).to eql "keys"
      @doc["more"] = "these keys"
      @doc.save
      expect(@db.get(@resp['id'])["more"]).to eql "these keys"
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
      expect(@db.get @resp['id']).to be_nil
    end
    it "should error when there's no db" do
      @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")
      expect(lambda{@doc.destroy}).to raise_error(ArgumentError)
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
      expect(@doc['_id']).to be_nil
      expect(@doc['_rev']).to be_nil
      expect(@db.get @resp['id']).to_not be_nil
      @db.bulk_save
      expect(@db.get @resp['id']).to be_nil
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
        expect(newdoc['key']).to eql 'value'
      end
      it "should fail without a database" do
        expect(lambda{CouchRest::Document.new({"not"=>"a real doc"}).copy}).to raise_error(ArgumentError)
      end
    end
    describe "to an existing location" do
      before :each do
        @db.save_doc({'_id' => @docid, 'will-exist' => 'here'})
      end
      it "should fail without a rev" do
        expect(lambda{@doc.copy @docid}).to raise_error(CouchRest::RequestFailed)
      end
      it "should succeed with a rev" do
        @to_be_overwritten = @db.get(@docid)
        @doc.copy "#{@docid}?rev=#{@to_be_overwritten['_rev']}"
        newdoc = @db.get(@docid)
        expect(newdoc['key']).to eql 'value'
      end
      it "should succeed given the doc to overwrite" do
        @to_be_overwritten = @db.get(@docid)
        @doc.copy @to_be_overwritten
        newdoc = @db.get(@docid)
        expect(newdoc['key']).to eql 'value'
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
      expect(@db.fetch_attachment(@doc, 'test.html')).to eql @attach
    end

    it "updates the revision" do
      expect(@doc[:_rev]).not_to eql @rev
    end

    it "updates attachments" do
      @attach2 = "<html><head><title>My Doc</title></head><body><p>Is Different.</p></body></html>"
      @doc.put_attachment('test.html', @attach2)
      expect(@db.fetch_attachment(@doc, 'test.html')).to eql @attach2
    end
  end

  describe "fetching an attachment from a doc directly" do
    before do
      append_attachment
    end

    it "pulls the attachment" do
      expect(@doc.fetch_attachment('test.html')).to eql @attach
    end
  end

  describe "deleting an attachment from a doc directly" do
    before do
      append_attachment
      @doc.delete_attachment('test.html')
    end

    it "removes it" do
      expect {
        @db.fetch_attachment(@doc, 'test.html')
      }.to raise_error(CouchRest::NotFound)
    end

    it "updates the revision" do
      expect(@doc[:_rev]).not_to eql @rev
    end
  end

end
