require File.dirname(__FILE__) + '/../../spec_helper'

describe "ExtendedDocument" do
  
  class WithDefaultValues < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :preset,       :default => {:right => 10, :top_align => false}
    property :set_by_proc,  :default => Proc.new{Time.now},       :cast_as => 'Time'
    property :name
    timestamps!
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
  
end