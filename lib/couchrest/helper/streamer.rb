module CouchRest
  class Streamer

    attr_accessor :default_curl_opts

    def initialize
      self.default_curl_opts = "--silent --no-buffer --tcp-nodelay -H \"Content-Type: application/json\""
    end

    def view(*args)
      raise "CouchRest::Streamer#view is deprecated. Please use Database#view with block."
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
      prev = nil
      IO.popen(cmd) do |f|
        first = f.gets # discard header
        while line = f.gets 
          row = parse_line(line)
          block.call row unless row.nil? # last line "}]" discarded
          prev = line
        end
      end

      raise RestClient::ServerBrokeConnection if $? && $?.exitstatus != 0

      parse_first(first, prev)
    end

    def parse_line line
      return nil unless line
      if /(\{.*\}),?/.match(line.chomp)
        MultiJson.decode($1)
      end
    end

    def parse_first first, last
      return nil unless first
      header = MultiJson.decode(last ? first + last : first)
      header.delete("rows")
      header
    end

  end
end
