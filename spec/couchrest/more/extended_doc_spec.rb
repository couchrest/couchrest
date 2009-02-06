require File.dirname(__FILE__) + '/../../spec_helper'

# require File.join(FIXTURE_PATH, 'more', 'card')
# require File.join(FIXTURE_PATH, 'more', 'invoice')
# require File.join(FIXTURE_PATH, 'more', 'service')


class WithDefaultValues < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  property :preset, :default => {:right => 10, :top_align => false}
end

describe "ExtendedDocument" do
  
  describe "with default" do
    before(:each) do
      @obj = WithDefaultValues.new
    end
    
    it "should have the default value set an initalization" do
      @obj.preset.should == {:right => 10, :top_align => false}
    end
  end
  
end