require File.dirname(__FILE__) + '/../../spec_helper'

class WithDefaultValues < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  property :preset,       :default => {:right => 10, :top_align => false}
  property :set_by_proc,  :default => Proc.new{Time.now}, :type => 'Time'
end

describe "ExtendedDocument" do
  
  describe "with default" do
    before(:each) do
      @obj = WithDefaultValues.new
    end
    
    it "should have the default value set at initalization" do
      @obj.preset.should == {:right => 10, :top_align => false}
    end
    
    it "should automatically call a proc default at initialization" do
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.set_by_proc.should == @obj.set_by_proc
      @obj.set_by_proc.should < Time.now
    end
  end
  
end