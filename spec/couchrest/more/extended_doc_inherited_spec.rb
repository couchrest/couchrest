require File.expand_path('../../../spec_helper', __FILE__)

begin
  require 'rubygems' unless ENV['SKIP_RUBYGEMS']  
  require 'activesupport'
  ActiveSupport::JSON.backend = :JSONGem

  class PlainParent
    class_inheritable_accessor :foo
    self.foo = :bar
  end

  class PlainChild < PlainParent
  end

  class ExtendedParent < CouchRest::ExtendedDocument
    class_inheritable_accessor :foo
    self.foo = :bar
  end

  class ExtendedChild < ExtendedParent
  end

  describe "Using chained inheritance without CouchRest::ExtendedDocument" do
    it "should preserve inheritable attributes" do
      PlainParent.foo.should == :bar
      PlainChild.foo.should == :bar
    end
  end

  describe "Using chained inheritance with CouchRest::ExtendedDocument" do
    it "should preserve inheritable attributes" do
      ExtendedParent.foo.should == :bar
      ExtendedChild.foo.should == :bar
    end
  end

rescue LoadError
  puts "This spec requires 'active_support' to be loaded"
end
