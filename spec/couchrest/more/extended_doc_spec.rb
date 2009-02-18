require File.dirname(__FILE__) + '/../../spec_helper'

describe "ExtendedDocument" do
  
  class WithDefaultValues < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :preset,       :default => {:right => 10, :top_align => false}
    property :set_by_proc,  :default => Proc.new{Time.now},       :cast_as => 'Time'
    property :tags,         :default => []
    property :name
    timestamps!
  end
  
  class WithCallBacks < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name
    property :run_before_save
    property :run_after_save
    property :run_before_create
    property :run_after_create
    property :run_before_update
    property :run_after_update
    
    save_callback :before do |object| 
      object.run_before_save = true
    end
    save_callback :after do |object| 
      object.run_after_save = true
    end
    create_callback :before do |object| 
      object.run_before_create = true
    end
    create_callback :after do |object| 
      object.run_after_create = true
    end
    update_callback :before do |object| 
      object.run_before_update = true
    end
    update_callback :after do |object| 
      object.run_after_update = true
    end
  end
  
  before(:each) do
    @obj = WithDefaultValues.new
  end
  
  describe "with default" do
    it "should have the default value set at initalization" do
      @obj.preset.should == {:right => 10, :top_align => false}
    end
    
    it "should automatically call a proc default at initialization" do
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.set_by_proc.should == @obj.set_by_proc
      @obj.set_by_proc.should < Time.now
    end
    
    it "should let you overwrite the default values" do
      obj = WithDefaultValues.new(:preset => 'test')
      obj.preset = 'test'
    end
    
    it "should work with a default empty array" do
      obj = WithDefaultValues.new(:tags => ['spec'])
      obj.tags.should == ['spec']
    end
  end
  
  describe "timestamping" do
    it "should define the updated_at and created_at getters and set the values" do
      @obj.save
      obj = WithDefaultValues.get(@obj.id)
      obj.should be_an_instance_of(WithDefaultValues)
      obj.created_at.should be_an_instance_of(Time)
      obj.updated_at.should be_an_instance_of(Time)
      obj.created_at.to_s.should == @obj.updated_at.to_s
    end 
  end
  
  describe "saving and retrieving" do
    it "should work fine" do
      @obj.name = "should be easily saved and retrieved"
      @obj.save
      saved_obj = WithDefaultValues.get(@obj.id)
      saved_obj.should_not be_nil
    end
    
    it "should parse the Time attributes automatically" do
      @obj.name = "should parse the Time attributes automatically"
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.save
      @obj.set_by_proc.should be_an_instance_of(Time)
      saved_obj = WithDefaultValues.get(@obj.id)
      saved_obj.set_by_proc.should be_an_instance_of(Time)
    end
  end
  
  describe "callbacks" do
    
    before(:each) do
      @doc = WithCallBacks.new
    end
    
    describe "save" do
      it "should not run the before filter before saving if the save failed" do
        @doc.run_before_save.should be_nil
        @doc.save.should be_true
        @doc.run_before_save.should be_true
      end
      it "should not run the before filter before saving if the save failed" do
        @doc.should_receive(:save).and_return(false)
        @doc.run_before_save.should be_nil
        @doc.save.should be_false
        @doc.run_before_save.should be_nil
      end
      it "should run the after filter after saving" do
        @doc.run_after_save.should be_nil
        @doc.save.should be_true
        @doc.run_after_save.should be_true
      end
      it "should not run the after filter before saving if the save failed" do
        @doc.should_receive(:save).and_return(false)
        @doc.run_after_save.should be_nil
        @doc.save.should be_false
        @doc.run_after_save.should be_nil
      end
    end
    describe "create" do
      it "should run the before save filter when creating" do
        @doc.run_before_save.should be_nil
        @doc.create.should_not be_nil
        @doc.run_before_save.should be_true
      end
      it "should not run the before save filter when the object creation fails" do
        pending "need to ask wycats about chainable callbacks" do
          @doc.should_receive(:create_without_callbacks).and_return(false)
          @doc.run_before_save.should be_nil
          @doc.save
          @doc.run_before_save.should be_nil
        end
      end
      it "should run the before create filter" do
        @doc.run_before_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_before_create.should be_true
      end
      it "should run the after create filter" do
        @doc.run_after_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_after_create.should be_true
      end
    end
    describe "update" do
      
      before(:each) do
        @doc.save
      end      
      it "should run the before update filter when updating an existing document" do
        @doc.run_before_update.should be_nil
        @doc.update
        @doc.run_before_update.should be_true
      end
      it "should run the after update filter when updating an existing document" do
        @doc.run_after_update.should be_nil
        @doc.update
        @doc.run_after_update.should be_true
      end
      it "should run the before update filter when saving an existing document" do
        @doc.run_before_update.should be_nil
        @doc.save
        @doc.run_before_update.should be_true
      end
      
    end
  end
end