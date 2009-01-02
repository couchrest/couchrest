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
     
    def initialize(dbname, host="http://127.0.0.1:5984")
      @db = CouchRest.new(host).database(dbname)
    end
    
    def push_app(appdir, appname)
      libs = []
      viewdir = File.join(appdir,"views")
      attachdir = File.join(appdir,"_attachments")

      fields = dir_to_fields(appdir)
      library = fields["library"]
      package_forms(fields["forms"], library)
      package_views(fields["views"], library)

      docid = "_design/#{appname}"
      design = @db.get(docid) rescue {}
      design.merge!(fields)
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
    
    
    # Generate an application in the given directory.
    # This is a class method because it doesn't depend on 
    # specifying a database.
    def self.generate_app(app_dir)      
      templatedir = File.join(File.expand_path(File.dirname(__FILE__)), 'template-app')
      FileUtils.cp_r(templatedir, app_dir)
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
    
    def package_forms(funcs, library)
      if library
        lib = "var library = #{library.to_json};"
        apply_lib(funcs, lib)
      end
    end
    
    def package_views(views, library)
      if library
        lib = "var library = #{library.to_json};"
        views.each do |view, funcs|
          apply_lib(funcs, lib) if lib
        end
      end
    end
    
    def apply_lib(funcs, lib)
      funcs.each do |k,v|
        funcs[k] = v.sub(/(\/\/|#)\ ?include-lib/,lib)
      end
    end
    
    def say words
      puts words if @loud
    end
    
    def md5 string
      Digest::MD5.hexdigest(string)
    end
  end
end
