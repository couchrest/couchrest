module CouchRest

  # CouchRest Stream Row Parser
  #
  # Will parse a stream containing a standard CouchDB response including rows.
  # Allows each row to be parsed individually, and provided in a block for 
  # efficient memory usage.
  #
  # The StreamRowParser#parse method expects to be called multiple times with segments
  # of data, typcially provided by the Net::HTTPResponse#read_body method.
  # 
  # Data will be cached until usable objects can be extracted in rows and provied in the block.
  #
  class StreamRowParser

    # String containing the fields provided before and after the rows.
    attr_accessor :header

    # The row level at which we expect to receive "rows" of data.
    # Typically this will be 0 for contious feeds, and 1 for most other users.
    attr_reader :row_level

    # Instantiate a new StreamRowParser with the mode set according to the type of data.
    # The supported modes are:
    #
    #  * `:array` - objects are contianed in a data array, the default.
    #  * `:feed` - each row of the stream is an object, like in continuous changes feeds.
    #
    def initialize(mode = :array)
      @header  = ""
      @data    = ""
      @string  = false
      @escape  = false

      @row_level = mode == :array ? 1 : 0
      @in_rows   = false
      @obj_level = 0
      @obj_close = false
    end

    def parse(segment, &block)
      @in_rows = true if @row_level == 0
      segment.each_char do |c|
        if @string
          # Inside a string, handling escaping and closure
          if @escape
            @escape = false
          else
            if c == '"'
              @string = false
            elsif c == '\\'
              @escape = true
            end
          end
        else
          # Inside an object
          @obj_close = false
          if @obj_level == @row_level && c == "[" # start of rows
            @in_rows = true
          elsif @obj_level == @row_level && c == "]" # end of rows
            @in_rows = false
          elsif c == "{" # object
            @obj_level += 1
          elsif c == "}" # object end
            @obj_level -= 1
            @obj_close = true
          elsif c == '"'
            @string = true
          end
        end

        # Append data
        if @row_level > 0
          if @obj_level == 0 || (@obj_level == @row_level && !@obj_close)
            @header << c unless @in_rows && (c == ',' || c == ' ' || c == "\n") # skip row whitespace
          else
            @data << c
          end
        else
          @data << c
        end

        # Determine if we need to trigger an event
        if @obj_close && @obj_level == @row_level
          block.call(@data)
          @data = ""
        end
      end
    end

  end

end
