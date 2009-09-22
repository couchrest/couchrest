require 'time'
require File.join(File.dirname(__FILE__), '..', 'more', 'property')

class Time                       
  # returns a local time value much faster than Time.parse
  def self.mktime_with_offset(string)
    string =~ /(\d{4})[\-|\/](\d{2})[\-|\/](\d{2})[T|\s](\d{2}):(\d{2}):(\d{2})([\+|\s|\-])*(\d{2}):?(\d{2})/
    # $1 = year
    # $2 = month
    # $3 = day
    # $4 = hours
    # $5 = minutes
    # $6 = seconds
    # $7 = time zone direction
    # $8 = tz difference
    # utc time with wrong TZ info: 
    time = mktime($1, RFC2822_MONTH_NAME[$2.to_i - 1], $3, $4, $5, $6, $7)
    tz_difference = ("#{$7 == '-' ? '+' : '-'}#{$8}".to_i * 3600)
    time + tz_difference + zone_offset(time.zone) 
  end 
end

module CouchRest
  module Mixins
    module Properties
      
      class IncludeError < StandardError; end
      
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
          arr = self[key].dup.collect do |value|
            unless value.instance_of?(klass)
              value = convert_property_value(property, klass, value)
            end
            associate_casted_to_parent(value, assigned)
            value
          end
          self[key] = klass != String ? CastedArray.new(arr) : arr
          self[key].casted_by = self if self[key].respond_to?(:casted_by)
        else
          if property.type == 'boolean'
            klass = TrueClass
          else
            klass = ::CouchRest.constantize(property.type)
          end
          
          unless self[key].instance_of?(klass)
            self[key] = convert_property_value(property, klass, self[property.name])
          end
          associate_casted_to_parent(self[property.name], assigned)
        end
        
      end
      
      def associate_casted_to_parent(casted, assigned)
        casted.casted_by = self if casted.respond_to?(:casted_by)
        casted.document_saved = true if !assigned && casted.respond_to?(:document_saved)
      end
      
      def convert_property_value(property, klass, value)
        if ((property.init_method == 'new') && klass == Time)
          # Using custom time parsing method because Ruby's default method is toooo slow
          value.is_a?(String) ? Time.mktime_with_offset(value.dup) : value
        # Float instances don't get initialized with #new
        elsif ((property.init_method == 'new') && klass == Float)
          cast_float(value)
          # 'boolean' type is simply used to generate a property? accessor method
        elsif ((property.init_method == 'new') && klass == TrueClass)
          value
        else
          klass.send(property.init_method, value.dup)
        end
      end
      
      def cast_property_by_name(property_name)
        return unless self.class.properties
        property = self.class.properties.detect{|property| property.name == property_name}
        return unless property
        cast_property(property, true)
      end
      
      def cast_float(value)
        begin 
          Float(value)
        rescue
          value
        end
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
            options[:casted] = options[:cast_as] ? options[:cast_as] : false
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
