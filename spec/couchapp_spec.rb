require File.dirname(__FILE__) + '/spec_helper'

describe "couchapp" do
  before(:all) do
    @fixdir = File.expand_path(File.dirname(__FILE__)) + '/fixtures/couchapp-test'
    @couchapp = File.expand_path(File.dirname(__FILE__)) + '/../bin/couchapp'
    `rm -rf #{@fixdir}`
    `mkdir -p #{@fixdir}`
    @run = "cd #{@fixdir} && #{@couchapp}"
    
  end

  describe "--help" do
    it "should output the opts" do
      `#{@run} --help`.should match(/Usage/)
    end
  end

  describe "generate my-app" do
    it "should create an app directory" do
      `#{@run} generate my-app`.should match(/generating/i)
      Dir["#{@fixdir}/*"].select{|x|x =~ /my-app/}.length.should == 1
    end
    it "should create a views directory" do
      `#{@run} generate my-app`.should match(/generating/i)
      Dir["#{@fixdir}/my-app/*"].select{|x|x =~ /views/}.length.should == 1
    end
  end
  
  describe "push my-app #{TESTDB}" do
    before(:all) do
      @cr = CouchRest.new(COUCHHOST)
      @db = @cr.database(TESTDB)
      @db.delete! rescue nil
      @db = @cr.create_db(TESTDB) rescue nil
      `#{@run} generate my-app`
    end
    it "should create the design document with the app name" do
      `#{@run} push my-app #{TESTDB}`
      lambda{@db.get("_design/my-app")}.should_not raise_error
    end
    it "should create the views" do
      `#{@run} push my-app #{TESTDB}`
      doc = @db.get("_design/my-app")
      doc['views']['example']['map'].should match(/function/)
    end
    it "should create the index" do
      `#{@run} push my-app #{TESTDB}`
      doc = @db.get("_design/my-app")
      doc['_attachments']['index.html']["content_type"].should == 'text/html'
    end
  end

  describe "push . #{TESTDB}" do
    before(:all) do
      @cr = CouchRest.new(COUCHHOST)
      @db = @cr.database(TESTDB)
      @db.delete! rescue nil
      @db = @cr.create_db(TESTDB) rescue nil
      `#{@run} generate my-app`
    end
    it "should create the design document" do
      `cd #{@fixdir}/my-app && #{@couchapp} push . #{TESTDB}`
      lambda{@db.get("_design/my-app")}.should_not raise_error
    end
  end
  
  describe "push my-app my-design #{TESTDB}" do
    before(:all) do
      @cr = CouchRest.new(COUCHHOST)
      @db = @cr.database(TESTDB)
      @db.delete! rescue nil
      @db = @cr.create_db(TESTDB) rescue nil
      `#{@run} generate my-app`
    end
    it "should create the design document" do
      `#{@run} push my-app my-design #{TESTDB}`
      lambda{@db.get("_design/my-design")}.should_not raise_error
    end
  end
end

