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

    def initialize
      @header  = ""
      @data    = ""
      @string  = false
      @escape  = false

      @in_rows   = false
      @obj_level = 0
      @obj_close = false
    end

    def parse(segment, &block)
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
          @obj_close = false
          if @obj_level == 1 && c == "[" # start of rows
            @in_rows = true
          elsif @obj_level == 1 && c == "]" # end of rows
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
        if @obj_level == 0 || (@obj_level == 1 && !@obj_close)
          @header << c unless @in_rows && (c == ',' || c == ' ' || c == "\n") # skip row whitespace
        else
          @data << c
        end

        # Determine if we need to trigger an event
        if @obj_close && @obj_level == 1
          block.call(@data)
          @data = ""
        end
      end
    end

  end

end
