module CouchRest
  
  # Basic attribute support adding getter/setter + validation
  class Property
    attr_reader :name, :type, :validation_format, :required, :read_only, :alias
    
    # attribute to define
    def initialize(name, type = String, options = {})
      @name      = name.to_s
      @type      = type
      parse_options(options)
      self
    end
    
    
    private
      def parse_options(options)
        return if options.empty?
        @required           = true if (options[:required] && (options[:required] == true))
        @validation_format  = options[:format] if options[:format]
        @read_only          = options[:read_only] if options[:read_only]
        @alias              = options[:alias]     if options
      end
    
  end
end