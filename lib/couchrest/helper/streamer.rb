module CouchRest
  class Streamer

    attr_accessor :default_curl_opts

    def initialize
      self.default_curl_opts = "--silent --no-buffer --tcp-nodelay -H \"Content-Type: application/json\""
    end

    def view(*args)
      raise "CouchRest::Streamer#view is depricated. Please use Database#view with block."
    end

    def get(url, &block)
      open_pipe("curl #{default_curl_opts} \"#{url}\"", &block)
    end

    def post(url, params = {}, &block)
      open_pipe("curl #{default_curl_opts} -d \"#{escape_quotes(MultiJson.encode(params))}\" \"#{url}\"", &block)
    end

    protected

    def escape_quotes(data)
      data.gsub(/"/, '\"')
    end

    def open_pipe(cmd, &block)
      first = nil
      IO.popen(cmd) do |f|
        first = f.gets # discard header
        while line = f.gets 
          row = parse_line(line)
          block.call row unless row.nil? # last line "}]" discarded
        end
      end
      parse_first(first)
    end

    def parse_line line
      return nil unless line
      if /(\{.*\}),?/.match(line.chomp)
        MultiJson.decode($1)
      end
    end

    def parse_first first
      return nil unless first
      parts = first.split(',')
      parts.pop
      line = parts.join(',')
      MultiJson.decode("#{line}}")
    rescue
      nil
    end

  end
end
