require File.dirname(__FILE__) + '/../../spec_helper'

describe CouchRest::Document, "[]=" do
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

describe CouchRest::Document, "new" do
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
  it "should freak out when saving without a database" do
    lambda{@doc.save}.should raise_error(ArgumentError)
  end
end

# move to database spec
describe CouchRest::Document, "saving using a database" do
  before(:all) do
    @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")    
    @db = reset_test_db!    
    @resp = @db.save(@doc)
  end
  it "should apply the database" do
    @doc.database.should == @db    
  end
  it "should get id and rev" do
    @doc.id.should == @resp["id"]
    @doc.rev.should == @resp["rev"]
  end
end

describe "getting from a database" do
  before(:all) do
    @db = reset_test_db!
    @resp = @db.save({
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
    @resp = @db.save({
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