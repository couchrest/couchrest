require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

# check the following file to see how to use the spec'd features.
require File.join(FIXTURE_PATH, 'more', 'card')

describe "ExtendedDocument properties" do
  
  before(:each) do
    @card = Card.new(:first_name => "matt")
  end
  
  it "should be accessible from the object" do
    @card.properties.should be_an_instance_of(Array)
    @card.properties.map{|p| p.name}.should include("first_name")
  end
  
  it "should let you access a property value (getter)" do
    @card.first_name.should == "matt"
  end
  
  it "should let you set a property value (setter)" do
    @card.last_name = "Aimonetti"
    @card.last_name.should == "Aimonetti"
  end
  
  it "should not let you set a property value if it's read only" do
    lambda{@card.read_only_value = "test"}.should raise_error
  end
  
  it "should let you use an alias for an attribute" do
    @card.last_name = "Aimonetti"
    @card.family_name.should == "Aimonetti"
    @card.family_name.should == @card.last_name
  end
  
  it "should be able to be validated" do
    pending("need to add validation") do
      @card.should be_valid
    end
    #Card.property(:company, :required => true)
  end
  
end