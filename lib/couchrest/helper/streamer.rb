module CouchRest
  class Streamer
    attr_accessor :db
    def initialize db
      @db = db
    end
    
    # Stream a view, yielding one row at a time. Shells out to <tt>curl</tt> to keep RAM usage low when you have millions of rows.
    def view name, params = nil, &block
      urlst = /^_/.match(name) ? "#{@db.root}/#{name}" : "#{@db.root}/_view/#{name}"
      url = CouchRest.paramify_url urlst, params
      first = nil
      IO.popen("curl --silent #{url}") do |view|
        first = view.gets # discard header
        # puts first
        while line = view.gets 
          # puts line
          row = parse_line(line)
          block.call row
        end
      end
      # parse_line(line)
      first
    end
    
    private
    
    def parse_line line
      return nil unless line
      if /(\{.*\}),?/.match(line.chomp)
        JSON.parse($1)
      end
    end
    
  end
end