require File.dirname(__FILE__) + '/spec_helper'

describe "couchapp" do
  before(:all) do
    @fixdir = FIXTURE_PATH + '/couchapp-test'
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
    before(:all) do
      `#{@run} generate my-app`.should match(/generating/i)      
    end
    it "should create an app directory" do
      Dir["#{@fixdir}/*"].select{|x|x =~ /my-app/}.length.should == 1
    end
    it "should create a views directory" do
      Dir["#{@fixdir}/my-app/*"].select{|x|x =~ /views/}.length.should == 1
    end
    it "should create an _attachments directory" do
      Dir["#{@fixdir}/my-app/*"].select{|x|x =~ /_attachments/}.length.should == 1
      Dir["#{@fixdir}/my-app/_attachments/*"].select{|x|x =~ /index.html/}.length.should == 1
    end
    it "should create a forms directory" do
      Dir["#{@fixdir}/my-app/*"].select{|x|x =~ /forms/}.length.should == 1
    end
    it "should create a forms and libs" do
      Dir["#{@fixdir}/my-app/forms/*"].select{|x|x =~ /example-form.js/}.length.should == 1
      Dir["#{@fixdir}/my-app/lib/templates/*"].select{|x|x =~ /example.html/}.length.should == 1
    end
  end
  
  describe "push my-app #{TESTDB}" do
    before(:all) do
      @cr = CouchRest.new(COUCHHOST)
      @db = @cr.database(TESTDB)
      @db.delete! rescue nil
      @db = @cr.create_db(TESTDB) rescue nil
      `#{@run} generate my-app`
      `#{@run} push my-app #{TESTDB}`
      @doc = @db.get("_design/my-app")
    end
    it "should create the design document with the app name" do
      lambda{@db.get("_design/my-app")}.should_not raise_error
    end
    it "should create the views" do
      @doc['views']['example']['map'].should match(/function/)
    end
    it "should create the view libs" do
      @doc['views']['example']['map'].should match(/stddev/)
      @doc['forms']['example-form'].should_not match(/\"helpers\"/)
    end
    it "should create view for all the views" do
      `mkdir -p #{@fixdir}/my-app/views/more`
      `echo 'moremap' > #{@fixdir}/my-app/views/more/map.js`
      `#{@run} push my-app #{TESTDB}`
      doc = @db.get("_design/my-app")
      doc['views']['more']['map'].should match(/moremap/)
    end
    it "should create the index" do
      @doc['_attachments']['index.html']["content_type"].should == 'text/html'
    end
    it "should push the forms" do
      @doc['forms']['example-form'].should match(/Generated CouchApp Form Template/)
    end
    it "should allow deeper includes" do
      @doc['forms']['example-form'].should_not match(/\"helpers\"/)
    end
    it "deep requires" do
      @doc['forms']['example-form'].should_not match(/\"template\"/)
      @doc['forms']['example-form'].should match(/Resig/)
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

