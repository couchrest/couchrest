require 'digest/md5'


class CouchRest
  class FileManager
    attr_reader :db
    
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
        # puts "creating public"
        @db.save({"_id" => docid, "_attachments" => @attachments, "signatures" => @signatures})
        return
      end

      # remove deleted docs
      to_be_removed = doc["signatures"].keys.select{|d| !couch["public"].collect{|p| p.keys.first}.include?(d) }

      to_be_removed.each do |p|
        # puts "deleting #{p}"
        doc["signatures"].delete(p)
        doc["_attachments"].delete(p)
      end

      # update existing docs:
      doc["signatures"].each do |path, sig|
        if (@signatures[path] == sig)
          # puts "no change to #{path}. skipping..."
        else
          # puts "replacing #{path}"
          doc["signatures"][path] = md5(@attachments[path]["data"])
          doc["_attachments"][path].delete("stub")
          doc["_attachments"][path].delete("length")    
          doc["_attachments"][path]["data"] = @attachments[path]["data"]
          doc["_attachments"][path].merge!({"data" => @attachments[path]["data"]} )

        end
      end

      # add in new files
      new_files = couch["public"].select{|d| !doc["signatures"].keys.include?( d.keys.first) } 

      new_files.each do |f|
        # puts "creating #{f}"
        path = f.keys.first
        content = f.values.first
        doc["signatures"][path] = md5(content)

        doc["_attachments"][path] = {
          "data" => content,
          "content_type" => @content_types[path.split('.').last]
        }
      end

      begin
        @db.save(doc)
      rescue Exception => e
        # puts e.message
      end
    end
    
    def push_views(view_dir)
      designs = {}

      Dir["#{view_dir}/**/*.*"].collect do |design_doc|
        design_doc_parts = design_doc.split('/')
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
      else
        # puts "saving #{id}"
        db.save(fields.merge({"_id" => id}))
      end

      if existing != updated
        # puts "replacing #{id}"
        db.save(updated)
      end

    end
  end
end

__END__




# parse the file structure to load the public files, controllers, and views into a hash with the right shape for coucdb
couch = {}

couch["public"] = Dir["#{File.expand_path(File.dirname("."))}/public/**/*.*"].collect do |f|
  {f.split("public/").last => open(f).read}
end

couch["controllers"] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/controllers/**/*.*"].collect do |c|
  path_parts = c.split("/")
  
  controller_name = path_parts[path_parts.length - 2]
  action_name = path_parts[path_parts.length - 1].split(".").first

  couch["controllers"][controller_name] ||= {"actions" => {}}
  couch["controllers"][controller_name]["actions"][action_name] = open(c).read
  
end

couch["designs"] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/views/**/*.*"].collect do |design_doc|
  design_doc_parts = design_doc.split('/')
  pre_normalized_view_name = design_doc_parts.last.split("-")
  view_name = pre_normalized_view_name[0..pre_normalized_view_name.length-2].join("-")

  folder = design_doc.split("app/views").last.split("/")[1]

  couch["designs"][folder] ||= {}
  couch["designs"][folder]["views"] ||= {}
  couch["designs"][folder]["language"] ||= LANGS[design_doc_parts.last.split(".").last]
  
  if design_doc_parts.last =~ /-map/
    couch["designs"][folder]["views"]["#{view_name}-map"] ||= {}

    couch["designs"][folder]["views"]["#{view_name}-map"]["map"] = open(design_doc).read

    couch["designs"][folder]["views"]["#{view_name}-reduce"] ||= {}
    couch["designs"][folder]["views"]["#{view_name}-reduce"]["map"] = open(design_doc).read
  end
  
  if design_doc_parts.last =~ /-reduce/
    couch["designs"][folder]["views"]["#{view_name}-reduce"] ||= {}

    couch["designs"][folder]["views"]["#{view_name}-reduce"]["reduce"] = open(design_doc).read
  end
end

# cleanup empty maps and reduces
couch["designs"].each do |name, props|
  props["views"].delete("#{name}-reduce") unless props["views"]["#{name}-reduce"].keys.include?("reduce")
end

# parsing done, begin posting

# connect to couchdb
cr = CouchRest.new("http://localhost:5984")
@db = cr.database(DBNAME)

def create_or_update(id, fields)
  existing = get(id)
  
  if existing
    updated = fields.merge({"_id" => id, "_rev" => existing["_rev"]})
  else
    puts "saving #{id}"
    save(fields.merge({"_id" => id}))
  end
  
  if existing == updated
    puts "no change to #{id}. skipping..."
  else
    puts "replacing #{id}"
    save(updated)
  end

end

def get(id)
  doc = handle_errors do
    @db.get(id)
  end
end

def save(doc)
  handle_errors do
    @db.save(doc)
  end
end

def handle_errors(&block)
  begin
    yield
  rescue Exception => e
    # puts e.message
    nil
  end
end


if todo.include? "views"
  puts "posting views into CouchDB"
  couch["designs"].each do |k,v|
    create_or_update("_design/#{k}", v)
  end
  puts
end

if todo.include? "controllers"
  puts "posting controllers into CouchDB"
  couch["controllers"].each do |k,v|
    create_or_update("controller/#{k}", v)
  end
  puts
end


if todo.include? "public"
  puts "posting public docs into CouchDB"

  if couch["public"].empty?
    puts "no docs in public"; exit 
  end
  
  @content_types = {
    "html"       => "text/html",
    "htm"        => "text/html",
    "png"        => "image/png",
    "css"        => "text/css",
    "js"         => "test/javascript"
  }
  
  def md5 string
    Digest::MD5.hexdigest(string)
  end
    
  @attachments = {}
  @signatures = {}
  couch["public"].each do |doc|
    @signatures[doc.keys.first] = md5(doc.values.first)
    
    @attachments[doc.keys.first] = {
      "data" => doc.values.first,
      "content_type" => @content_types[doc.keys.first.split('.').last]
    }
  end
  
  doc = get("public")
  
  unless doc
    puts "creating public"
    @db.save({"_id" => "public", "_attachments" => @attachments, "signatures" => @signatures})
    exit
  end
  
  # remove deleted docs
  to_be_removed = doc["signatures"].keys.select{|d| !couch["public"].collect{|p| p.keys.first}.include?(d) }
  
  to_be_removed.each do |p|
    puts "deleting #{p}"
    doc["signatures"].delete(p)
    doc["_attachments"].delete(p)
  end
  
  # update existing docs:
  doc["signatures"].each do |path, sig|
    if (@signatures[path] == sig)
      puts "no change to #{path}. skipping..."
    else
      puts "replacing #{path}"
      doc["signatures"][path] = md5(@attachments[path]["data"])
      doc["_attachments"][path].delete("stub")
      doc["_attachments"][path].delete("length")    
      doc["_attachments"][path]["data"] = @attachments[path]["data"]
      doc["_attachments"][path].merge!({"data" => @attachments[path]["data"]} )
      
    end
  end
  
  # add in new files
  new_files = couch["public"].select{|d| !doc["signatures"].keys.include?( d.keys.first) } 
  
  new_files.each do |f|
    puts "creating #{f}"
    path = f.keys.first
    content = f.values.first
    doc["signatures"][path] = md5(content)
    
    doc["_attachments"][path] = {
      "data" => content,
      "content_type" => @content_types[path.split('.').last]
    }
  end
  
  begin
    @db.save(doc)
  rescue Exception => e
    puts e.message
  end
  
  puts
end