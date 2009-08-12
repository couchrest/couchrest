require File.expand_path("../../../spec_helper", __FILE__)
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'more', 'course')

# add a default value
Card.property :bg_color, :default => '#ccc'

class BusinessCard < Card
  property :extension_code
  property :job_title
end

class DesignBusinessCard < BusinessCard
  property :bg_color, :default => '#eee'
end

class OnlineCourse < Course
  property :url
  view_by :url
end

class Animal < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  property :name
  view_by :name
end

class Dog < Animal; end

describe "Subclassing an ExtendedDocument" do
  
  before(:each) do
    @card = BusinessCard.new
  end
  
  it "shouldn't messup the parent's properties" do
    Card.properties.should_not == BusinessCard.properties
  end
  
  it "should share the same db default" do
    @card.database.uri.should == Card.database.uri
  end
  
  it "should share the same autovalidation details" do
    @card.auto_validation.should be_true
  end
  
  it "should have kept the validation details" do
    @card.should_not be_valid
  end
  
  it "should have added the new validation details" do
    validated_fields = @card.class.validators.contexts[:default].map{|v| v.field_name}
    validated_fields.should include(:extension_code) 
    validated_fields.should include(:job_title)
  end
  
  it "should not add to the parent's validations" do
    validated_fields = Card.validators.contexts[:default].map{|v| v.field_name}
    validated_fields.should_not include(:extension_code)
    validated_fields.should_not include(:job_title) 
  end
  
  it "should inherit default property values" do
    @card.bg_color.should == '#ccc'
  end
  
  it "should be able to overwrite a default property" do
    DesignBusinessCard.new.bg_color.should == '#eee'
  end
  
  it "should have a design doc slug based on the subclass name" do
    Course.refresh_design_doc
    OnlineCourse.design_doc_slug.should =~ /^OnlineCourse/
  end
  
  it "should have its own design_doc_fresh" do
    Animal.refresh_design_doc
    Dog.design_doc_fresh.should_not == true
    Dog.refresh_design_doc
    Dog.design_doc_fresh.should == true
  end
  
  it "should not add views to the parent's design_doc" do
    Course.design_doc['views'].keys.should_not include('by_url')
  end
  
  it "should not add the parent's views to its design doc" do
    Course.refresh_design_doc
    OnlineCourse.refresh_design_doc
    OnlineCourse.design_doc['views'].keys.should_not include('by_title')
  end
  
  it "should have an all view with a guard clause for couchrest-type == subclass name in the map function" do
    OnlineCourse.design_doc['views']['all']['map'].should =~ /if \(doc\['couchrest-type'\] == 'OnlineCourse'\)/
  end
end

