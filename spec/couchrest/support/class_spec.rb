require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'couchrest', 'support', 'class')

describe CouchRest::ClassExtension do
  
  before :all do
    class FullyDefinedClassExtensions
      def self.respond_to?(method)
        if CouchRest::ClassExtension::InstanceMethods.instance_methods.include?(method)
          true
        else
          super
        end
      end
    end
    
    class PartDefinedClassExtensions
      def self.respond_to?(method)
        methods = CouchRest::ClassExtension::InstanceMethods.instance_methods
        methods.delete('cattr_reader')
        
        if methods.include?(method)
          false
        else
          super
        end
      end
    end
    
    class NoClassExtensions
      def self.respond_to?(method)
        if CouchRest::ClassExtension::InstanceMethods.instance_methods.include?(method)
          false
        else
          super
        end
      end
    end


  end
  
  it "should not include InstanceMethods if the class extensions are already defined" do
    FullyDefinedClassExtensions.send(:include, CouchRest::ClassExtension)
    FullyDefinedClassExtensions.ancestors.should_not include(CouchRest::ClassExtension::InstanceMethods)
  end
  
  it "should raise RuntimeError if the class extensions are only partially defined" do
    lambda {
      PartDefinedClassExtensions.send(:include, CouchRest::ClassExtension)
    }.should raise_error(RuntimeError)
  end
  
  it "should include class extensions if they are not already defined" do
    NoClassExtensions.send(:include, CouchRest::ClassExtension)
    NoClassExtensions.ancestors.should include(CouchRest::ClassExtension::InstanceMethods)
  end
  
end