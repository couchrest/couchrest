require 'time'
require File.join(File.dirname(__FILE__), '..', 'more', 'property')
require File.join(File.dirname(__FILE__), '..', 'more', 'typecast')

module CouchRest
  module Mixins
    module Properties
      
      class IncludeError < StandardError; end
      
      include ::CouchRest::More::Typecast

      def self.included(base)
        base.class_eval <<-EOS, __FILE__, __LINE__ + 1
            extlib_inheritable_accessor(:properties) unless self.respond_to?(:properties)
            self.properties ||= []
        EOS
        base.extend(ClassMethods)
        raise CouchRest::Mixins::Properties::IncludeError, "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end
      
      def apply_defaults
        return if self.respond_to?(:new?) && (new? == false)
        return unless self.class.respond_to?(:properties) 
        return if self.class.properties.empty?
        # TODO: cache the default object
        self.class.properties.each do |property|
          key = property.name.to_s
          # let's make sure we have a default
          unless property.default.nil?
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
        self.class.properties.each do |property|
          cast_property(property)
        end
      end
      
      def cast_property(property, assigned=false)
        return unless property.casted
        key = self.has_key?(property.name) ? property.name : property.name.to_sym
        # Don't cast the property unless it has a value
        return unless self[key]
        if property.type.is_a?(Array)
          klass = ::CouchRest.constantize(property.type[0])
          self[key] = [self[key]] unless self[key].is_a?(Array)
          arr = self[key].collect do |value|
            value = typecast_value(value, klass, property.init_method)
            associate_casted_to_parent(value, assigned)
            value
          end
          self[key] = klass != String ? CastedArray.new(arr) : arr
          self[key].casted_by = self if self[key].respond_to?(:casted_by)
        else
          if property.type.downcase == 'boolean'
            klass = TrueClass
          else
            klass = ::CouchRest.constantize(property.type)
          end
          
          self[key] = typecast_value(self[key], klass, property.init_method)
          associate_casted_to_parent(self[key], assigned)
        end
      end
      
      def associate_casted_to_parent(casted, assigned)
        casted.casted_by = self if casted.respond_to?(:casted_by)
        casted.document_saved = true if !assigned && casted.respond_to?(:document_saved)
      end
      
      def cast_property_by_name(property_name)
        return unless self.class.properties
        property = self.class.properties.detect{|property| property.name == property_name}
        return unless property
        cast_property(property, true)
      end
      
     
      module ClassMethods
        
        def property(name, options={})
          existing_property = self.properties.find{|p| p.name == name.to_s}
          if existing_property.nil? || (existing_property.default != options[:default])
            define_property(name, options)
          end
        end
        
        protected
        
          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure to use a mutex.
          def define_property(name, options={})
            # check if this property is going to casted
            options[:casted] = !!(options[:cast_as] || options[:type])
            property = CouchRest::Property.new(name, (options.delete(:cast_as) || options.delete(:type)), options)
            create_property_getter(property) 
            create_property_setter(property) unless property.read_only == true
            properties << property
          end
          
          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            # meth = property.name
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def #{property.name}
                self['#{property.name}']
              end
            EOS

            if property.type == 'boolean'
              class_eval <<-EOS, __FILE__, __LINE__
                def #{property.name}?
                  if self['#{property.name}'].nil? || self['#{property.name}'] == false || self['#{property.name}'].to_s.downcase == 'false'
                    false
                  else
                    true
                  end
                end
              EOS
            end

            if property.alias
              class_eval <<-EOS, __FILE__, __LINE__ + 1
                alias #{property.alias.to_sym} #{property.name.to_sym}
              EOS
            end
          end

          # defines the setter for the property (and optional aliases)
          def create_property_setter(property)
            property_name = property.name
            class_eval <<-EOS
              def #{property_name}=(value)
                self['#{property_name}'] = value
                cast_property_by_name('#{property_name}')
              end
            EOS

            if property.alias
              class_eval <<-EOS
                alias #{property.alias.to_sym}= #{property_name.to_sym}=
              EOS
            end
          end
          
      end # module ClassMethods
      
    end
  end
end
