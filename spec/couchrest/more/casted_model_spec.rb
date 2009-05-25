# encoding: utf-8

require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'more', 'cat')
require File.join(FIXTURE_PATH, 'more', 'person')


class WithCastedModelMixin < Hash
  include CouchRest::CastedModel
  property :name
  property :no_value
  property :details,          :default => {}
  property :casted_attribute, :cast_as => 'WithCastedModelMixin'
end

class DummyModel < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  raise "Default DB not set" if TEST_SERVER.default_database.nil?
  property :casted_attribute, :cast_as => 'WithCastedModelMixin'
  property :keywords,         :cast_as => ["String"]
end

describe CouchRest::CastedModel do
  
  describe "A non hash class including CastedModel" do
    it "should fail raising and include error" do
      lambda do
        class NotAHashButWithCastedModelMixin
          include CouchRest::CastedModel
          property :name
        end
        
      end.should raise_error
    end
  end
  
  describe "isolated" do
    before(:each) do
      @obj = WithCastedModelMixin.new
    end
    it "should automatically include the property mixin and define getters and setters" do
      @obj.name = 'Matt'
      @obj.name.should == 'Matt' 
    end
    
    it "should allow override of default" do
      @obj = WithCastedModelMixin.new(:name => 'Eric', :details => {'color' => 'orange'})
      @obj.name.should == 'Eric'
      @obj.details['color'].should == 'orange'
    end
  end
  
  describe "casted as an attribute, but without a value" do
    before(:each) do
      @obj = DummyModel.new
      @casted_obj = @obj.casted_attribute
    end
    it "should be nil" do
      @casted_obj.should == nil
    end
  end
  
  describe "casted as attribute" do
    before(:each) do
      casted = {:name => 'not whatever'}
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever', :casted_attribute => casted})
      @casted_obj = @obj.casted_attribute
    end
    
    it "should be available from its parent" do
      @casted_obj.should be_an_instance_of(WithCastedModelMixin)
    end
    
    it "should have the getters defined" do
      @casted_obj.name.should == 'whatever'
    end
    
    it "should know who casted it" do
      @casted_obj.casted_by.should == @obj
    end

    it "should return nil for the 'no_value' attribute" do
      @casted_obj.no_value.should be_nil
    end

    it "should return nil for the unknown attribute" do
      @casted_obj["unknown"].should be_nil
    end
    
    it "should return {} for the hash attribute" do
      @casted_obj.details.should == {}
    end
    
    it "should cast its own attributes" do
      @casted_obj.casted_attribute.should be_instance_of(WithCastedModelMixin)
    end
  end
  
  describe "casted as an array of a different type" do
    before(:each) do
      @obj = DummyModel.new(:keywords => ['couch', 'sofa', 'relax', 'canapé'])
    end
    
    it "should cast the array propery" do
      @obj.keywords.should be_an_instance_of(Array)
      @obj.keywords.first.should == 'couch'
    end
    
  end
  
  describe "saved document with casted models" do
    before(:each) do
      reset_test_db!
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever'})
      @obj.save.should be_true
      @obj = DummyModel.get(@obj.id)
    end
    
    it "should be able to load with the casted models" do
      casted_obj = @obj.casted_attribute
      casted_obj.should_not be_nil
      casted_obj.should be_an_instance_of(WithCastedModelMixin)
    end
    
    it "should have defined getters for the casted model" do
      casted_obj = @obj.casted_attribute
      casted_obj.name.should == "whatever"
    end
    
    it "should have defined setters for the casted model" do
      casted_obj = @obj.casted_attribute
      casted_obj.name = "test"
      casted_obj.name.should == "test"
    end
    
    it "should retain an override of a casted model attribute's default" do
      casted_obj = @obj.casted_attribute
      casted_obj.details['color'] = 'orange'
      @obj.save
      casted_obj = DummyModel.get(@obj.id).casted_attribute
      casted_obj.details['color'].should == 'orange'
    end
    
  end

  describe "saving document with array of casted models and validation" do
    before :each do
      @cat = Cat.new
      @cat.save
    end

    it "should save" do
      toy = CatToy.new :name => "Mouse"
      @cat.toys.push(toy)
      @cat.save.should be_true
    end

    it "should fail because name is not present" do
      toy = CatToy.new
      @cat.toys.push(toy)
      @cat.should_not be_valid
      @cat.save.should be_false
    end
    
    it "should not fail if the casted model doesn't have validation" do
      Cat.property :masters, :cast_as => ['Person'], :default => []
      Cat.validates_present :name
      cat = Cat.new(:name => 'kitty')
      cat.should be_valid
      cat.masters.push Person.new
      cat.should be_valid
    end
    
  end
  
end
