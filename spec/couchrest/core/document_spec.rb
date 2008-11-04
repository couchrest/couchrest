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
  it "should create itself from a Hash" do
    @doc = CouchRest::Document.new("key" => [1,2,3], :more => "values")
    @doc["key"].should == [1,2,3]
    @doc["more"].should == "values"
  end
end