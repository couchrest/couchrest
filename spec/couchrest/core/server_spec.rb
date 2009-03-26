require File.dirname(__FILE__) + '/../../spec_helper'

describe CouchRest::Server do
  
  describe "named databases" do
    it "should generate database without prefix" do
      couch = CouchRest::Server.new "http://192.0.2.1:1234"
      db = couch.database("foo")
      db.name.should == "foo"
      db.uri.should == "http://192.0.2.1:1234/foo"
    end

    it "should generate database with prefix" do
      couch = CouchRest::Server.new "http://192.0.2.1:1234/dev"
      db = couch.database("foo")
      db.name.should == "devfoo"
      db.uri.should == "http://192.0.2.1:1234/devfoo"
    end

    it "should generate database with prefix and slash" do
      couch = CouchRest::Server.new "http://192.0.2.1:1234/dev/"
      db = couch.database("foo")
      db.name.should == "dev/foo"
      db.uri.should == "http://192.0.2.1:1234/dev%2Ffoo"
    end

    it "should generate database with slashes" do
      couch = CouchRest::Server.new "http://192.0.2.1:1234/dev/sample/"
      db = couch.database("foo/bar")
      db.name.should == "dev/sample/foo/bar"
      db.uri.should == "http://192.0.2.1:1234/dev%2Fsample%2Ffoo%2Fbar"
    end
  end

  describe "available databases" do
    before(:each) do
      @couch = CouchRest::Server.new
    end

    after(:each) do
      @couch.available_databases.each do |ref, db|
        db.delete!
      end
    end
    
    it "should let you add more databases" do
      @couch.available_databases.should be_empty
      @couch.define_available_database(:default, "cr-server-test-db")
      @couch.available_databases.keys.should include(:default)
    end
    
    it "should verify that a database is available" do
      @couch.define_available_database(:default, "cr-server-test-db")
      @couch.available_database?(:default).should be_true
      @couch.available_database?("cr-server-test-db").should be_true
      @couch.available_database?(:matt).should be_false
    end
    
    it "should let you set a default database" do
      @couch.default_database = 'cr-server-test-default-db'
      @couch.available_database?(:default).should be_true
    end
  end
  
end