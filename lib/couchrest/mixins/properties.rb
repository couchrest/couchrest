require File.join(File.dirname(__FILE__), '..', 'more', 'property')

module CouchRest
  module Mixins
    module Properties
      
      class IncludeError < StandardError; end
      
      def self.included(base)
        base.cattr_accessor(:properties)
          base.class_eval <<-EOS, __FILE__, __LINE__
              @@properties = []
          EOS
        base.extend(ClassMethods)
        raise CouchRest::Mixins::Properties::IncludeError, "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end
      
      def apply_defaults
        return unless self.respond_to?(:new_document?) && new_document?
        return unless self.class.respond_to?(:properties) 
        return if self.class.properties.empty?
        # TODO: cache the default object
        self.class.properties.each do |property|
          key = property.name.to_s
          # let's make sure we have a default and we can assign the value
          if property.default && (self.respond_to?("#{key}=") || self.key?(key))
              if property.default.class == Proc
                self[key] = property.default.call
              else
                self[key] = Marshal.load(Marshal.dump(property.default))
              end
            end
        end
      end
      
      def cast_keys
        return unless self.class.properties
        # TODO move the argument checking to the cast method for early crashes
        self.class.properties.each do |property|
          next unless property.casted
          key = self.has_key?(property.name) ? property.name : property.name.to_sym
          target = property.type
          if target.is_a?(Array)
            klass = ::CouchRest.constantize(target[0])
            
            self[property.name] = self[key].collect do |value|
              obj = ( (property.init_method == 'send') && klass == Time) ? Time.parse(value) : klass.send(property.init_method, value)
              obj.casted_by = self if obj.respond_to?(:casted_by)
              obj
            end
          else
            # Let people use :send as a Time parse arg
            self[property.name] = if ((property.init_method != 'send') && target == 'Time') 
              Time.parse(self[property.init_method])
            else
              klass = ::CouchRest.constantize(target)
              klass.send(property.init_method, self[property.name])
            end
            self[key].casted_by = self if self[key].respond_to?(:casted_by)
          end
        end
      end
      
      module ClassMethods
        
        def property(name, options={})
          define_property(name, options) unless properties.map{|p| p.name}.include?(name.to_s)
        end
        
        protected
        
          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure to use a mutex.
          def define_property(name, options={})
            # check if this property is going to casted
            options[:casted] = true if options[:cast_as]
            property = CouchRest::Property.new(name, (options.delete(:cast_as) || options.delete(:type)), options)
            create_property_getter(property) 
            create_property_setter(property) unless property.read_only == true
            properties << property
          end
          
          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            # meth = property.name
            class_eval <<-EOS, __FILE__, __LINE__
              def #{property.name}
                self['#{property.name}']
              end
            EOS

            if property.alias
              class_eval <<-EOS, __FILE__, __LINE__
                alias #{property.alias.to_sym} #{property.name.to_sym}
              EOS
            end
          end

          # defines the setter for the property (and optional aliases)
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