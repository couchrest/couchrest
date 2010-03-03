# encoding: utf-8

require File.expand_path('../../../spec_helper', __FILE__)
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'more', 'cat')
require File.join(FIXTURE_PATH, 'more', 'person')
require File.join(FIXTURE_PATH, 'more', 'question')
require File.join(FIXTURE_PATH, 'more', 'course')


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

class CastedCallbackDoc < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  raise "Default DB not set" if TEST_SERVER.default_database.nil?
  property :callback_model, :cast_as => 'WithCastedCallBackModel'
end
class WithCastedCallBackModel < Hash
  include CouchRest::CastedModel
  include CouchRest::Validation
  property :name
  property :run_before_validate
  property :run_after_validate
  
  before_validate do |object|
    object.run_before_validate = true
  end
  after_validate do |object| 
    object.run_after_validate = true
  end
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
  
  describe "update attributes without saving" do
    before(:each) do
      @question = Question.new(:q => "What is your quest?", :a => "To seek the Holy Grail")
    end
    it "should work for attribute= methods" do
      @question.q.should == "What is your quest?"
      @question['a'].should == "To seek the Holy Grail"
      @question.update_attributes_without_saving(:q => "What is your favorite color?", 'a' => "Blue")
      @question['q'].should == "What is your favorite color?"
      @question.a.should == "Blue"
    end
    
    it "should also work for attributes= alias" do
      @question.respond_to?(:attributes=).should be_true
      @question.attributes = {:q => "What is your favorite color?", 'a' => "Blue"}
      @question['q'].should == "What is your favorite color?"
      @question.a.should == "Blue"
    end
    
    it "should flip out if an attribute= method is missing" do
      lambda {
        @q.update_attributes_without_saving('foo' => "something", :a => "No green")
      }.should raise_error(NoMethodError)
    end
    
    it "should not change any attributes if there is an error" do
      lambda {
        @q.update_attributes_without_saving('foo' => "something", :a => "No green")
      }.should raise_error(NoMethodError)
      @question.q.should == "What is your quest?"
      @question.a.should == "To seek the Holy Grail"
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
      @cat = Cat.get @cat.id
      @cat.toys.class.should == CastedArray
      @cat.toys.first.class.should == CatToy
      @cat.toys.first.should === toy
    end

    it "should fail because name is not present" do
      toy = CatToy.new
      @cat.toys.push(toy)
      @cat.should_not be_valid
      @cat.save.should be_false
    end
    
    it "should not fail if the casted model doesn't have validation" do
      Cat.property :masters, :cast_as => ['Person'], :default => []
      Cat.validates_presence_of :name
      cat = Cat.new(:name => 'kitty')
      cat.should be_valid
      cat.masters.push Person.new
      cat.should be_valid
    end
  end
  
  describe "calling valid?" do
    before :each do
      @cat = Cat.new
      @toy1 = CatToy.new
      @toy2 = CatToy.new
      @toy3 = CatToy.new
      @cat.favorite_toy = @toy1
      @cat.toys << @toy2
      @cat.toys << @toy3
    end
    
    describe "on the top document" do
      it "should put errors on all invalid casted models" do
        @cat.should_not be_valid
        @cat.errors.should_not be_empty
        @toy1.errors.should_not be_empty
        @toy2.errors.should_not be_empty
        @toy3.errors.should_not be_empty
      end
      
      it "should not put errors on valid casted models" do
        @toy1.name = "Feather"
        @toy2.name = "Twine" 
        @cat.should_not be_valid
        @cat.errors.should_not be_empty
        @toy1.errors.should be_empty
        @toy2.errors.should be_empty
        @toy3.errors.should_not be_empty
      end
    end
    
    describe "on a casted model property" do
      it "should only validate itself" do
        @toy1.should_not be_valid
        @toy1.errors.should_not be_empty
        @cat.errors.should be_empty
        @toy2.errors.should be_empty
        @toy3.errors.should be_empty
      end
    end
    
    describe "on a casted model inside a casted collection" do
      it "should only validate itself" do
        @toy2.should_not be_valid
        @toy2.errors.should_not be_empty
        @cat.errors.should be_empty
        @toy1.errors.should be_empty
        @toy3.errors.should be_empty
      end
    end
  end
  
  describe "calling new? on a casted model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Sockington')
      @favorite_toy = CatToy.new(:name => 'Catnip Ball')
      @cat.favorite_toy = @favorite_toy
      @cat.toys << CatToy.new(:name => 'Fuzzy Stick')
    end
    
    it "should be true on new" do
      CatToy.new.should be_new
      CatToy.new.new_record?.should be_true
    end
    
    it "should be true after assignment" do
      @cat.should be_new
      @cat.favorite_toy.should be_new
      @cat.toys.first.should be_new
    end
    
    it "should not be true after create or save" do
      @cat.create
      @cat.save
      @cat.favorite_toy.should_not be_new
      @cat.toys.first.should_not be_new
    end
    
    it "should not be true after get from the database" do
      @cat.save
      @cat = Cat.get(@cat.id)
      @cat.favorite_toy.should_not be_new
      @cat.toys.first.should_not be_new
    end
    
    it "should still be true after a failed create or save" do
      @cat.name = nil
      @cat.create.should be_false
      @cat.save.should be_false
      @cat.favorite_toy.should be_new
      @cat.toys.first.should be_new
    end
  end
  
  describe "calling base_doc from a nested casted model" do
    before :each do
      @course = Course.new(:title => 'Science 101')
      @professor = Person.new(:name => 'Professor Plum')
      @cat = Cat.new(:name => 'Scratchy')
      @toy1 = CatToy.new
      @toy2 = CatToy.new
      @course.professor = @professor
      @professor.pet = @cat
      @cat.favorite_toy = @toy1
      @cat.toys << @toy2
    end
    
    it "should reference the top document for" do
      @course.base_doc.should === @course
      @professor.casted_by.should === @course
      @professor.base_doc.should === @course
      @cat.base_doc.should === @course
      @toy1.base_doc.should === @course
      @toy2.base_doc.should === @course
    end
    
    it "should call setter on top document" do
      @toy1.base_doc.should_not be_nil
      @toy1.base_doc.title = 'Tom Foolery'
      @course.title.should == 'Tom Foolery'
    end
    
    it "should return nil if not yet casted" do
      person = Person.new
      person.base_doc.should == nil
    end
  end
  
  describe "calling base_doc.save from a nested casted model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Snowball')
      @toy = CatToy.new
      @cat.favorite_toy = @toy
    end
    
    it "should not save parent document when casted model is invalid" do
      @toy.should_not be_valid
      @toy.base_doc.save.should be_false
      lambda{@toy.base_doc.save!}.should raise_error
    end
    
    it "should save parent document when nested casted model is valid" do
      @toy.name = "Mr Squeaks"
      @toy.should be_valid
      @toy.base_doc.save.should be_true
      lambda{@toy.base_doc.save!}.should_not raise_error
    end
  end
  
  describe "callbacks" do
    before(:each) do
      @doc = CastedCallbackDoc.new
      @model = WithCastedCallBackModel.new
      @doc.callback_model = @model
    end
    
    describe "validate" do
      it "should run before_validate before validating" do
        @model.run_before_validate.should be_nil
        @model.should be_valid
        @model.run_before_validate.should be_true
      end
      it "should run after_validate after validating" do
        @model.run_after_validate.should be_nil
        @model.should be_valid
        @model.run_after_validate.should be_true
      end      
    end
  end
end
