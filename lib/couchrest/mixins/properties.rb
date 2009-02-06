module CouchRest
  module Mixins
    module DocumentProperties
      
      class IncludeError < StandardError; end
      
      def self.included(base)
        base.extend(ClassMethods)
        raise CouchRest::Mixins::DocumentProporties::InludeError, "You can only mixin Properties in a class responding to [] and []=" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end
      
      def apply_defaults
        return unless new_document?
        return if self.class.properties.empty?
        
        # TODO: cache the default object
        self.class.properties.each do |property|
          key = property.name.to_s
          # let's make sure we have a default and we can assign the value
          if property.default && (self.respond_to?("#{key}=") || self.key?(key))
              if property.default.class == Proc
                self[key] = v.call
              else
                self[key] = Marshal.load(Marshal.dump(property.default))
              end
            end
        end
        
      end
      
      module ClassMethods
        
        # Stores the class properties
        def properties
          @@properties ||= []
        end
        
        def property(name, options={})
          define_property(name, options) unless properties.map{|p| p.name}.include?(name.to_s)
        end
        
        protected
        
          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure to use a mutex.
          def define_property(name, options={})
            property = CouchRest::Property.new(name, options.delete(:type), options)
            create_property_getter(property) 
            create_property_setter(property) unless property.read_only == true
            properties << property
          end
          
          # defines the getter for the property
          def create_property_getter(property)
            meth = property.name
            class_eval <<-EOS
              def #{meth}
                self['#{meth}']
              end
            EOS

            if property.alias
              class_eval <<-EOS
                alias #{property.alias.to_sym} #{meth.to_sym}
              EOS
            end
          end

          # defines the setter for the property
          def create_property_setter(property)
            meth = property.name
            class_eval <<-EOS
              def #{meth}=(value)
                self['#{meth}'] = value
              end
            EOS

            if property.alias
              class_eval <<-EOS
                alias #{property.alias.to_sym}= #{meth.to_sym}=
              EOS
            end
          end
          
      end # module ClassMethods
      
    end
  end
end