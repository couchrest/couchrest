require 'digest/md5'

module CouchRest
  class FileManager
    attr_reader :db
    attr_accessor :loud
    
    LANGS = {"rb" => "ruby", "js" => "javascript"}
    MIMES = {
      "html"  => "text/html",
      "htm"   => "text/html",
      "png"   => "image/png",
      "gif"   => "image/gif",
      "css"   => "text/css",
      "js"    => "test/javascript",
      "txt"   => "text/plain"
    }

    # Generate an application in the given directory.
    # This is a class method because it doesn't depend on 
    # specifying a database.
    def self.generate_app(app_dir)      
      templatedir = File.join(File.expand_path(File.dirname(__FILE__)), 'app-template')
      FileUtils.cp_r(templatedir, app_dir)
    end
     
    # instance methods
     
    def initialize(dbname, host="http://127.0.0.1:5984")
      @db = CouchRest.new(host).database(dbname)
    end
    
    # maintain the correspondence between an fs and couch
    
    def push_app(appdir, appname)
      libs = []
      viewdir = File.join(appdir,"views")
      attachdir = File.join(appdir,"_attachments")

      @doc = dir_to_fields(appdir)
      package_forms(@doc["forms"]) if @doc['forms']
      package_views(@doc["views"]) if @doc['views']

      docid = "_design/#{appname}"
      design = @db.get(docid) rescue {}
      design.merge!(@doc)
      design['_id'] = docid
      # design['language'] = lang if lang
      @db.save(design)
      push_directory(attachdir, docid)
    end
    
    def dir_to_fields(dir)
      fields = {}
      (Dir["#{dir}/**/*.*"] - 
        Dir["#{dir}/_attachments/**/*.*"]).each do |file|
        farray = file.sub(dir, '').sub(/^\//,'').split('/')
        myfield = fields
        while farray.length > 1
          front = farray.shift
          myfield[front] ||= {}
          myfield = myfield[front]
        end
        fname, fext = farray.shift.split('.')
        fguts = File.open(file).read
        if fext == 'json'
          myfield[fname] = JSON.parse(fguts)
        else
          myfield[fname] = fguts
        end
      end
      return fields
    end
    
    def push_directory(push_dir, docid=nil)
      docid ||= push_dir.split('/').reverse.find{|part|!part.empty?}

      pushfiles = Dir["#{push_dir}/**/*.*"].collect do |f|
        {f.split("#{push_dir}/").last => open(f).read}
      end

      return if pushfiles.empty?

      @attachments = {}
      @signatures = {}
      pushfiles.each do |file|
        name = file.keys.first
        value = file.values.first
        @signatures[name] = md5(value)

        @attachments[name] = {
          "data" => value,
          "content_type" => MIMES[name.split('.').last]
        } 
      end

      doc = @db.get(docid) rescue nil

      unless doc
        say "creating #{docid}"
        @db.save({"_id" => docid, "_attachments" => @attachments, "signatures" => @signatures})
        return
      end

      doc["signatures"] ||= {}
      doc["_attachments"] ||= {}
      # remove deleted docs
      to_be_removed = doc["signatures"].keys.select do |d| 
        !pushfiles.collect{|p| p.keys.first}.include?(d) 
      end 

      to_be_removed.each do |p|
        say "deleting #{p}"
        doc["signatures"].delete(p)
        doc["_attachments"].delete(p)
      end

      # update existing docs:
      doc["signatures"].each do |path, sig|
        if (@signatures[path] == sig)
          say "no change to #{path}. skipping..."
        else
          say "replacing #{path}"
          doc["signatures"][path] = md5(@attachments[path]["data"])
          doc["_attachments"][path].delete("stub")
          doc["_attachments"][path].delete("length")    
          doc["_attachments"][path]["data"] = @attachments[path]["data"]
          doc["_attachments"][path].merge!({"data" => @attachments[path]["data"]} )
        end
      end

      # add in new files
      new_files = pushfiles.select{|d| !doc["signatures"].keys.include?( d.keys.first) } 

      new_files.each do |f|
        say "creating #{f}"
        path = f.keys.first
        content = f.values.first
        doc["signatures"][path] = md5(content)

        doc["_attachments"][path] = {
          "data" => content,
          "content_type" => MIMES[path.split('.').last]
        }
      end

      begin
        @db.save(doc)
      rescue Exception => e
        say e.message
      end
    end
    
    private
    
    def package_forms(funcs)
      apply_lib(funcs)
    end
    
    def package_views(views)
      views.each do |view, funcs|
        apply_lib(funcs)
      end
    end
    
    def apply_lib(funcs)
      funcs.each do |k,v|
        next unless v.is_a?(String)
        funcs[k] = process_include(process_require(v))
      end
    end
    
    # process requires
    def process_require(f_string)
      f_string.gsub /(\/\/|#)\ ?!code (.*)/ do
        fields = $2.split('.')
        library = @doc
        fields.each do |field|
          library = library[field]
          break unless library
        end
        library
      end
    end
    
    
    def process_include(f_string)

      # process includes
      included = {}
      f_string.gsub /(\/\/|#)\ ?!json (.*)/ do
        fields = $2.split('.')
        library = @doc
        include_to = included
        count = fields.length
        fields.each_with_index do |field, i|
          break unless library[field]
          library = library[field]
          # normal case
          if i+1 < count 
            include_to[field] = include_to[field] || {}
            include_to = include_to[field]
          else
            # last one
            include_to[field] = library
          end
        end

      end
      # puts included.inspect
      rval = if included == {}
        f_string
      else
        varstrings = included.collect do |k, v|
          "var #{k} = #{v.to_json};"
        end
        # just replace the first instance of the macro
        f_string.sub /(\/\/|#)\ ?!json (.*)/, varstrings.join("\n")
      end
      
      rval
    end
    
    
    def say words
      puts words if @loud
    end
    
    def md5 string
      Digest::MD5.hexdigest(string)
    end
  end
end
