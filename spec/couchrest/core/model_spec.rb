require File.dirname(__FILE__) + '/../../spec_helper'

class Basic
  include CouchRest::Model
end

class Article
  include CouchRest::Model
  use_database CouchRest.database!('http://localhost:5984/couchrest-model-test')
  uniq_id :slug
  
  key_accessor :title
  key_reader :slug, :created_at, :updated_at
  before(:create, :generate_slug_from_title)

  timestamps!
  
  def generate_slug_from_title
    doc['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'')
  end

  key_writer :date
  
  view_by :date
end

describe CouchRest::Model do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    @adb = @cr.database('couchrest-model-test')
    @adb.delete! rescue nil
    CouchRest.database!('http://localhost:5984/couchrest-model-test')
    CouchRest::Model.default_database = CouchRest.database!('http://localhost:5984/couchrest-test')
  end
  
  it "should use the default database" do
    Basic.database.info['db_name'].should == 'couchrest-test'
  end
  
  it "should override the default db" do
    Article.database.info['db_name'].should == 'couchrest-model-test'
  end
  
  describe "a new model" do
    it "should be a new_record" do
      @obj = Basic.new
      @obj.should be_a_new_record
    end
  end
  
  describe "a model with key_accessors" do
    it "should allow reading keys" do
      @art = Article.new
      @art.doc['title'] = 'My Article Title'
      @art.title.should == 'My Article Title'
    end
    it "should allow setting keys" do
      @art = Article.new
      @art.title = 'My Article Title'
      @art.doc['title'].should == 'My Article Title'
    end
  end
  
  describe "a model with key_writers" do
    it "should allow setting keys" do
      @art = Article.new
      t = Time.now
      @art.date = t
      @art.doc['date'].should == t
    end
    it "should not allow reading keys" do
      @art = Article.new
      t = Time.now
      @art.date = t
      lambda{@art.date}.should raise_error
    end
  end
  
  describe "a model with key_readers" do
    it "should allow reading keys" do
      @art = Article.new
      @art.doc['slug'] = 'my-slug'
      @art.slug.should == 'my-slug'
    end
    it "should not allow setting keys" do
      @art = Article.new
      lambda{@art.slug = 'My Article Title'}.should raise_error
    end
  end
  
  describe "getting a model" do
    before(:all) do
      @art = Article.new(:title => 'All About Getting')
      @art.save
    end
    it "should load and instantiate it" do
      foundart = Article.get @art.id
      foundart.title.should == "All About Getting"
    end
  end

  describe "saving a model" do
    before(:all) do
      @obj = Basic.new
      @obj.save.should == true
    end
    
    it "should save the doc" do
      doc = @obj.database.get @obj.id
      doc['_id'].should == @obj.id
    end
    
    it "should be set for resaving" do
      rev = @obj.rev
      @obj.doc['another-key'] = "some value"
      @obj.save
      @obj.rev.should_not == rev
    end
    
    it "should set the id" do
      @obj.id.should be_an_instance_of String
    end
    
    it "should set the type" do
      @obj.doc['type'].should == 'Basic'
    end
  end

  describe "saving a model with a uniq_id configured" do
    before(:each) do
      @art = Article.new
      @old = Article.database.get('this-is-the-title') rescue nil
      Article.database.delete(@old) if @old
    end
    
    it "should require the title" do
      lambda{@art.save}.should raise_error
      @art.title = 'This is the title'
      @art.save.should == true
    end
    
    it "should not change the slug on update" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.title = 'new title'
      @art.save.should == true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should raise an error when the slug is taken" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art2 = Article.new(:title => 'This is the title!')
      lambda{@art2.save}.should raise_error
    end
    
    it "should set the slug" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should set the id" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.id.should == 'this-is-the-title'
    end
  end

  describe "a model with timestamps" do
    before(:all) do
      @art = Article.new(:title => "Saving this")
      @art.save
    end
    it "should set the time on create" do
      (Time.now - @art.created_at).should < 2
      foundart = Article.get @art.id
      foundart.created_at.should == foundart.updated_at
    end
    it "should set the time on update" do
      @art.save
      @art.created_at.should < @art.updated_at
    end
  end

  describe "a model with simple views" do
    before(:all) do
      written_at = Time.now - 24 * 3600 * 7
      ["this and that", "also interesting", "more fun", "some junk"].each do |title|
        a = Article.new(:title => title)
        a.date = written_at
        a.save
        written_at += 24 * 3600
      end
    end
    
    it "should create the design doc" do
      Article.by_date
      doc = Article.database.get("_design/Article")
      doc['views']['by_date'].should_not be_nil
    end
    
    it "should return the matching view result" do
      view = Article.by_date :raw => true
      # view.should == 'x'
      # view['rows'].should == 4
    end
    
    
  end
end