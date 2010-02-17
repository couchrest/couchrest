require 'time'
require 'bigdecimal'
require 'bigdecimal/util'

module CouchRest

  # Basic attribute support for adding getter/setter + validation
  class Property
    attr_reader :name, :type, :read_only, :alias, :default, :casted, :init_method, :options

    # attribute to define
    def initialize(name, type = nil, options = {})
      @name = name.to_s
      parse_type(type)
      parse_options(options)
      self
    end

    def typecast(value)
      do_typecast(value, type, init_method)
    end

    protected

      def do_typecast(value, target, init_method)
        return nil if value.nil?

        if target == 'String'        then typecast_to_string(value)
        elsif target == 'Boolean'    then typecast_to_boolean(value)
        elsif target == 'Integer'    then typecast_to_integer(value)
        elsif target == 'Float'      then typecast_to_float(value)
        elsif target == 'BigDecimal' then typecast_to_bigdecimal(value)
        elsif target == 'DateTime'   then typecast_to_datetime(value)
        elsif target == 'Time'       then typecast_to_time(value)
        elsif target == 'Date'       then typecast_to_date(value)
        elsif target == 'Class'      then typecast_to_class(value)
        elsif target.is_a?(Array)    then typecast_array(value, target, init_method)
        else
          @klass ||= ::CouchRest.constantize(target)
          value.kind_of?(@klass) ? value : @klass.send(init_method, value.dup)
        end
      end

      def typecast_array(value, target, init_method)
        value.map { |v| do_typecast(v, target[0], init_method) }
      end

      # Typecast a value to an Integer
      def typecast_to_integer(value)
        value.kind_of?(Integer) ? value : typecast_to_numeric(value, :to_i)
      end

      # Typecast a value to a String
      def typecast_to_string(value)
        value.to_s
      end

      # Typecast a value to a true or false
      def typecast_to_boolean(value)
        return value if value == true || value == false

        if value.kind_of?(Integer)
          return true  if value == 1
          return false if value == 0
        elsif value.respond_to?(:to_str)
          return true  if %w[ true  1 t ].include?(value.to_str.downcase)
          return false if %w[ false 0 f ].include?(value.to_str.downcase)
        end

        value
      end

      # Typecast a value to a BigDecimal
      def typecast_to_bigdecimal(value)
        return value if value.kind_of?(BigDecimal)

        if value.kind_of?(Integer)
          value.to_s.to_d
        else
          typecast_to_numeric(value, :to_d)
        end
      end

      # Typecast a value to a Float
      def typecast_to_float(value)
        return value if value.kind_of?(Float)
        typecast_to_numeric(value, :to_f)
      end

      # Match numeric string
      def typecast_to_numeric(value, method)
        if value.respond_to?(:to_str)
          if value.to_str =~ /\A(-?(?:0|[1-9]\d*)(?:\.\d+)?|(?:\.\d+))\z/
            $1.send(method)
          else
            value
          end
        elsif value.respond_to?(method)
          value.send(method)
        else
          value
        end
      end

      # Typecasts an arbitrary value to a DateTime.
      # Handles both Hashes and DateTime instances.
      def typecast_to_datetime(value)
        return value if value.kind_of?(DateTime)

        if value.is_a?(Hash)
          typecast_hash_to_datetime(value)
        else
          DateTime.parse(value.to_s)
        end
      rescue ArgumentError
        value
      end

      # Typecasts an arbitrary value to a Date
      # Handles both Hashes and Date instances.
      def typecast_to_date(value)
        return value if value.kind_of?(Date)

        if value.is_a?(Hash)
          typecast_hash_to_date(value)
        else
          Date.parse(value.to_s)
        end
      rescue ArgumentError
        value
      end

      # Typecasts an arbitrary value to a Time
      # Handles both Hashes and Time instances.
      def typecast_to_time(value)
        return value if value.kind_of?(Time)

        if value.is_a?(Hash)
          typecast_hash_to_time(value)
        else
          Time.mktime_with_offset(value.to_s)
        end
      rescue ArgumentError
        value
      rescue TypeError
        value
      end

      # Creates a DateTime instance from a Hash with keys :year, :month, :day,
      # :hour, :min, :sec
      def typecast_hash_to_datetime(value)
        DateTime.new(*extract_time(value))
      end

      # Creates a Date instance from a Hash with keys :year, :month, :day
      def typecast_hash_to_date(value)
        Date.new(*extract_time(value)[0, 3])
      end

      # Creates a Time instance from a Hash with keys :year, :month, :day,
      # :hour, :min, :sec
      def typecast_hash_to_time(value)
        Time.local(*extract_time(value))
      end

      # Extracts the given args from the hash. If a value does not exist, it
      # uses the value of Time.now.
      def extract_time(value)
        now  = Time.now

        [:year, :month, :day, :hour, :min, :sec].map do |segment|
          typecast_to_numeric(value.fetch(segment, now.send(segment)), :to_i)
        end
      end

      # Typecast a value to a Class
      def typecast_to_class(value)
        return value if value.kind_of?(Class)
        ::CouchRest.constantize(value.to_s)
      rescue NameError
        value
      end

    private

      def parse_type(type)
        if type.nil?
          @type = 'String'
        elsif type.is_a?(Array) && type.empty?
          @type = ['Object']
        else
          @type = type.is_a?(Array) ? [type.first.to_s] : type.to_s
        end
      end

      def parse_options(options)
        return if options.empty?
        @validation_format  = options.delete(:format)     if options[:format]
        @read_only          = options.delete(:read_only)  if options[:read_only]
        @alias              = options.delete(:alias)      if options[:alias]
        @default            = options.delete(:default)    unless options[:default].nil?
        @casted             = options[:casted] ? true : false
        @init_method        = options[:init_method] ? options.delete(:init_method) : 'new'
        @options            = options
      end

  end
end

class CastedArray < Array
  attr_accessor :casted_by
  
  def << obj
    obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
    super(obj)
  end
  
  def push(obj)
    obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
    super(obj)
  end
  
  def []= index, obj
    obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
    super(index, obj)
  end
end