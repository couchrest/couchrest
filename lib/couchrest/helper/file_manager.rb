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
      "js"    => "test/javascript"
    }    
    def initialize(dbname, host="http://localhost:5984")
      @db = CouchRest.new(host).database(dbname)
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
    
    def push_views(view_dir)
      designs = {}

      Dir["#{view_dir}/**/*.*"].each do |design_doc|
        design_doc_parts = design_doc.split('/')
        next if /^lib\..*$/.match design_doc_parts.last
        pre_normalized_view_name = design_doc_parts.last.split("-")
        view_name = pre_normalized_view_name[0..pre_normalized_view_name.length-2].join("-")

        folder = design_doc_parts[-2]

        designs[folder] ||= {}
        designs[folder]["views"] ||= {}
        design_lang = design_doc_parts.last.split(".").last
        designs[folder]["language"] ||= LANGS[design_lang]

        libs = ""
        Dir["#{view_dir}/lib.#{design_lang}"].collect do |global_lib|
          libs << open(global_lib).read
          libs << "\n"
        end
        Dir["#{view_dir}/#{folder}/lib.#{design_lang}"].collect do |global_lib|
          libs << open(global_lib).read
          libs << "\n"
        end
        if design_doc_parts.last =~ /-map/
          designs[folder]["views"]["#{view_name}-map"] ||= {}

          designs[folder]["views"]["#{view_name}-map"]["map"] = read(design_doc, libs)

          designs[folder]["views"]["#{view_name}-reduce"] ||= {}
          designs[folder]["views"]["#{view_name}-reduce"]["map"] = read(design_doc, libs)
        end

        if design_doc_parts.last =~ /-reduce/
          designs[folder]["views"]["#{view_name}-reduce"] ||= {}

          designs[folder]["views"]["#{view_name}-reduce"]["reduce"] = read(design_doc, libs)
        end
      end

      # cleanup empty maps and reduces
      designs.each do |name, props|
        props["views"].each do |view, funcs|
          next unless view.include?("reduce")
          props["views"].delete(view) unless funcs.keys.include?("reduce")
        end
      end
      
      designs.each do |k,v|
        create_or_update("_design/#{k}", v)
      end
      
      designs
    end
    
    def pull_views(view_dir)
      prefix = "_design"
      ds = db.documents(:startkey => '#{prefix}/', :endkey => '#{prefix}/ZZZZZZZZZ')
      ds['rows'].collect{|r|r['id']}.each do |id|
        puts directory = id.split('/').last
        FileUtils.mkdir_p(File.join(view_dir,directory))
        views = db.get(id)['views']

        vgroups = views.keys.group_by{|k|k.sub(/\-(map|reduce)$/,'')}
        vgroups.each do|g,vs|
          mapname = vs.find {|v|views[v]["map"]}
          if mapname
            # save map
            mapfunc = views[mapname]["map"]
            mapfile = File.join(view_dir, directory, "#{g}-map.js") # todo support non-js views
            File.open(mapfile,'w') do |f|
              f.write mapfunc
            end
          end

          reducename = vs.find {|v|views[v]["reduce"]}
          if reducename
            # save reduce
            reducefunc = views[reducename]["reduce"]
            reducefile = File.join(view_dir, directory, "#{g}-reduce.js") # todo support non-js views
            File.open(reducefile,'w') do |f|
              f.write reducefunc
            end
          end
        end
      end  
      
    end
    
    def push_app(appdir, appname)
      libs = []
      viewdir = File.join(appdir,"views")
      attachdir = File.join(appdir,"_attachments")
      views, lang = read_design_views(viewdir)

      docid = "_design/#{appname}"
      design = @db.get(docid) rescue {}
      design['_id'] = docid
      design['views'] = views
      design['language'] = lang if lang
      @db.save(design)
      push_directory(attachdir, docid)
      
      push_fields(appdir, docid)
    end
    
    def push_fields(appdir, docid)
      fields = {}
      (Dir["#{appdir}/**/*.*"] - 
        Dir["#{appdir}/views/**/*.*"] - 
        Dir["#{appdir}/doc.json"] -         
        Dir["#{appdir}/_attachments/**/*.*"]).each do |file|
        farray = file.sub(appdir, '').sub(/^\//,'').split('/')
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
      if File.exists?("#{appdir}/doc.json")
        default_json = JSON.parse(File.open("#{appdir}/doc.json").read)
      end
      design = @db.get(docid) rescue {}
      design.merge!(fields)
      design.merge!(default_json) if default_json
      @db.save(design)
    end
    
    # Generate an application in the given directory.
    # This is a class method because it doesn't depend on 
    # specifying a database.
    def self.generate_app(app_dir)      
      FileUtils.mkdir_p(app_dir)
      FileUtils.mkdir_p(File.join(app_dir,"_attachments"))      
      FileUtils.mkdir_p(File.join(app_dir,"views"))
      FileUtils.mkdir_p(File.join(app_dir,"foo"))
      
      {
        "index.html" => "_attachments",
        'example-map.js' => "views",
        'example-reduce.js' => "views",
        'bar.txt' => "foo",
      }.each do |filename, targetdir|
        template = File.join(File.expand_path(File.dirname(__FILE__)), 'templates',filename)
        dest = File.join(app_dir,targetdir,filename)
        FileUtils.cp(template, dest)
      end
    end
    
    private
    
    def read_design_views(viewdir)
      libs = []
      language = nil
      views = {}
      Dir["#{viewdir}/*.*"].each do |viewfile|
        view_parts = viewfile.split('/')
        viewfile_name = view_parts.last
        # example-map.js
        viewfile_name_parts = viewfile_name.split('.')
        viewfile_ext = viewfile_name_parts.last
        view_name_parts = viewfile_name_parts.first.split('-')
        func_type = view_name_parts.pop
        view_name = view_name_parts.join('-')
        contents = File.open(viewfile).read
        if /^lib\..*$/.match viewfile_name
          libs.push(contents)
        else
          views[view_name] ||= {}
          language = LANGS[viewfile_ext]
          views[view_name][func_type] = contents.sub(/(\/\/|#)include-lib/,libs.join("\n"))
        end
      end
      [views, language]
    end
    
    def say words
      puts words if @loud
    end
    
    def md5 string
      Digest::MD5.hexdigest(string)
    end
    
    def read(file, libs=nil)
      st = open(file).read
      st.sub!(/(\/\/|#)include-lib/,libs) if libs
      st
    end
    
    def create_or_update(id, fields)
      existing = @db.get(id) rescue nil

      if existing
        updated = existing.merge(fields)
        if existing != updated
          say "replacing #{id}"
          db.save(updated)
        else
          say "skipping #{id}"
        end
      else
        say "creating #{id}"
        db.save(fields.merge({"_id" => id}))
      end

    end
  end
end
