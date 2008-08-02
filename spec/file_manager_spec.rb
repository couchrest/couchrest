require File.dirname(__FILE__) + '/spec_helper'

describe CouchRest::FileManager do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
  end
  it "should initialize" do
    @fm = CouchRest::FileManager.new(TESTDB)
    @fm.should_not be_nil
  end
  it "should require a db name" do
    lambda{CouchRest::FileManager.new}.should raise_error
  end
  it "should accept a db name" do
    @fm = CouchRest::FileManager.new(TESTDB, 'http://localhost')
    @fm.db.name.should == TESTDB
  end
  it "should default to localhost couchdb" do
    @fm = CouchRest::FileManager.new(TESTDB)
    @fm.db.host.should == 'http://localhost:5984'
  end
end

describe CouchRest::FileManager, "pushing views" do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    
    @fm = CouchRest::FileManager.new(TESTDB, COUCHHOST)
    @view_dir = File.dirname(__FILE__) + '/fixtures/views'
    ds = @fm.push_views(@view_dir)
    @design = @db.get("_design/test_view")
  end
  it "should create a design document for each folder" do
    @design["views"].should_not be_nil
  end
  it "should push a map and reduce view" do
    @design["views"]["test-map"].should_not be_nil
    @design["views"]["test-reduce"].should_not be_nil
  end
  it "should push a map only view" do
    @design["views"]["only-map"].should_not be_nil
    @design["views"]["only-reduce"].should be_nil
  end
  it "should include library files" do
    @design["views"]["only-map"]["map"].should include("globalLib")
    @design["views"]["only-map"]["map"].should include("justThisView")
  end
end

describe CouchRest::FileManager, "pushing a directory with id" do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    
    @fm = CouchRest::FileManager.new(TESTDB, COUCHHOST)
    @push_dir = File.dirname(__FILE__) + '/fixtures/attachments'
    ds = @fm.push_directory(@push_dir, 'attached')
  end
  it "should create a document for the folder" do
    @db.get("attached")
  end
  it "should make attachments" do
    doc = @db.get("attached")
    doc["_attachments"]["test.html"].should_not be_nil
  end
  it "should set the content type" do
    doc = @db.get("attached")
    doc["_attachments"]["test.html"]["content_type"].should == "text/html"
  end
end

describe CouchRest::FileManager, "pushing a directory without id" do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    
    @fm = CouchRest::FileManager.new(TESTDB, COUCHHOST)
    @push_dir = File.dirname(__FILE__) + '/fixtures/attachments'
    ds = @fm.push_directory(@push_dir)
  end
  it "should use the dirname" do
    doc = @db.get("attachments")
    doc["_attachments"]["test.html"].should_not be_nil
  end
end

describe CouchRest::FileManager, "pushing a directory/ without id" do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    
    @fm = CouchRest::FileManager.new(TESTDB, COUCHHOST)
    @push_dir = File.dirname(__FILE__) + '/fixtures/attachments/'
    ds = @fm.push_directory(@push_dir)
  end
  it "should use the dirname" do
    doc = @db.get("attachments")
    doc["_attachments"]["test.html"].should_not be_nil
  end
end