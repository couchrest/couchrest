module CouchRest
  class Streamer

    attr_accessor :default_curl_opts

    def initialize
      self.default_curl_opts = "--silent --no-buffer --tcp-nodelay"
    end

    def view(*args)
      raise "CouchRest::Streamer#view is depricated. Please use Database#view with block."
    end

    def get(url, &block)
      open_pipe("curl #{default_curl_opts} \"#{url}\"", &block)
    end

    def post(url, params = {}, &block)
      open_pipe("curl #{default_curl_opts} -d \"#{CGI.encode(params.to_json)}\" \"#{url}\"", &block)
    end

    protected

    def open_pipe(cmd, &block)
      first = nil
      IO.popen(cmd) do |view|
        first = view.gets # discard header
        while line = view.gets 
          row = parse_line(line)
          block.call row unless row.nil? # last line "}]" discarded
        end
      end
      parse_first(first)
    end

    def parse_line line
      return nil unless line
      if /(\{.*\}),?/.match(line.chomp)
        JSON.parse($1)
      end
    end

    def parse_first first
      return nil unless first
      parts = first.split(',')
      parts.pop
      line = parts.join(',')
      JSON.parse("#{line}}")
    rescue
      nil
    end
    
  end
end
