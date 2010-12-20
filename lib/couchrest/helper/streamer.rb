module CouchRest
  class Streamer
    attr_accessor :db
    def initialize db
      @db = db
    end
    
    # Stream a view, yielding one row at a time. Shells out to <tt>curl</tt> to keep RAM usage low when you have millions of rows.
    def view name, params = nil, &block
      urlst = if /^_/.match(name) then
        "#{@db.root}/#{name}"
      else
        name = name.split('/')
        dname = name.shift
        vname = name.join('/')
        "#{@db.root}/_design/#{dname}/_view/#{vname}"
      end
      url = CouchRest.paramify_url urlst, params
      # puts "stream #{url}"
      first = nil
      IO.popen("curl --silent '#{url}'") do |view|
        first = view.gets # discard header
        while line = view.gets 
          row = parse_line(line)
          block.call row unless row.nil? # last line "}]" discarded
        end
      end
      parse_first(first)
    end
    
    private
    
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
