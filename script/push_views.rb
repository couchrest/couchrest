$: << File.expand_path(File.dirname(__FILE__)) + '/..'
require 'lib/parse'
require 'couchrest/couchrest'
require 'vendor/jsmin/lib/jsmin'
# require 'yaml'
# connect to couchdb

cr = CouchRest.new("http://localhost:5984")
cr.create_db('grabbit-import') rescue nil
db = cr.database('grabbit-import')

# create views from files
views = {}
viewfiles = Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)),"..","views","**","*.js"))

libfiles = viewfiles.select{|f|/lib\.js/.match(f)}

all = (viewfiles-libfiles).collect do |file|
  filename = /(\w.*)-(\w.*)\.js/.match file.split('/').pop
  filename.to_a + [file]
end

@libfuncs = open(libfiles[0]).read

def readjs(file)
  st = open(file).read
  st.sub!(/\/\/include-lib/,@libfuncs)
  JSMin.minify(st)
end 

all.group_by do |f|
  f[3].split('/')[-2]
end.each do |design,ps|
  views[design] ||= {}
  puts "design #{design}"
  ps.group_by do |f|
    f[1]
  end.each do |view,parts|
    puts "view #{view}"
    views[design]["#{view}-reduce"] ||= {}
    parts.each do |p|
      puts "part #{p.inspect}"
      views[design]["#{view}-reduce"][p[2]] = readjs(p[3])
    end
    views[design]["#{view}-map"] = {:map => views[design]["#{view}-reduce"]['map']}
    views[design].delete("#{view}-reduce") unless views[design]["#{view}-reduce"]['reduce']
  end  
end

views.each do |design,viewfuncs|
  begin
    view = db.get("_design/#{design}")
    db.delete(view)
  rescue
  end
  db.save({
    "_id" => "_design/#{design}",
    :views => viewfuncs
  })
end
