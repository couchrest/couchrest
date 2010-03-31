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

    private

      def parse_type(type)
        if type.nil?
          @type = String
        elsif type.is_a?(Array) && type.empty?
          @type = [Object]
        else
          base_type = type.is_a?(Array) ? type.first : type
          if base_type.is_a?(String)
            if base_type.downcase == 'boolean'
              base_type = TrueClass 
            else
              begin
                base_type = ::CouchRest.constantize(base_type)
              rescue  # leave base type as a string and convert in more/typecast
              end
            end
          end
          @type = type.is_a?(Array) ? [base_type] : base_type 
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
