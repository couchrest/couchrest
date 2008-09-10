require 'digest/md5'

class CouchRest
  class FileManager
    attr_reader :db
    attr_accessor :loud
    
    LANGS = {"rb" => "ruby", "js" => "javascript"}
    MIMES = {
      "html"  => "text/html",
      "htm"   => "text/html",
      "png"   => "image/png",
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
    
    
    private
    
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
        updated = fields.merge({"_id" => id, "_rev" => existing["_rev"]})
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
