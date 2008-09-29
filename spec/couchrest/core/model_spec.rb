require File.dirname(__FILE__) + '/../../spec_helper'

class Basic
  include CouchRest::Model
end

class Article
  include CouchRest::Model
  use_database CouchRest.database!('http://localhost:5984/couchrest-model-test')
  uniq_id :slug
end

describe CouchRest::Model do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    CouchRest::Model.default_database = CouchRest.database!('http://localhost:5984/couchrest-test')
  end
  
  it "should use the default database" do
    Basic.database.info['db_name'].should == 'couchrest-test'
  end
  
  it "should override the default db" do
    Article.database.info['db_name'].should == 'couchrest-model-test'
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
    before(:all) do
      @art = Article.new
    end
    it "should require the slug" do
      lambda{@art.save}.should raise_error
      @art.slug = 'this-becomes-the-id'
      @art.save.should == true
    end
  end
end