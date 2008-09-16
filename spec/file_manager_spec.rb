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

describe CouchRest::FileManager, "generating an app" do
  before(:all) do
    @appdir = File.expand_path(File.dirname(__FILE__)) + '/fixtures/couchapp'
    `rm -rf #{@appdir}`
    `mkdir -p #{@appdir}`
    CouchRest::FileManager.generate_app(@appdir)
  end
  it "should create an attachments directory" do
    Dir["#{@appdir}/*"].select{|x|x =~ /attachments/}.length.should == 1  
  end
  it "should create a views directory" do
    Dir["#{@appdir}/*"].select{|x|x =~ /views/}.length.should == 1  
  end
  it "should create index.html" do
    html = File.open("#{@appdir}/attachments/index.html").read
    html.should match(/DOCTYPE/)
  end
  it "should create an example view" do
    map = File.open("#{@appdir}/views/example-map.js").read
    map.should match(/function\(doc\)/)
    reduce = File.open("#{@appdir}/views/example-reduce.js").read
    reduce.should match(/rereduce/)
  end
end

describe CouchRest::FileManager, "pushing an app" do
  before(:all) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue nil
    @db = @cr.create_db(TESTDB) rescue nil
    
    @appdir = File.expand_path(File.dirname(__FILE__)) + '/fixtures/couchapp'
    `rm -rf #{@appdir}`
    `mkdir -p #{@appdir}`
    CouchRest::FileManager.generate_app(@appdir)

    @fm = CouchRest::FileManager.new(TESTDB, COUCHHOST)
    r = @fm.push_app(@appdir, "couchapp")
  end
  it "should create a design document" do
    lambda{@db.get("_design/couchapp")}.should_not raise_error
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
  it "should not create extra design docs" do
    docs = @db.documents(:startkey => '_design', :endkey => '_design/ZZZZZZ')
    docs['total_rows'].should == 1
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