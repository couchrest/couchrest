Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "0.9.1"
  s.date = "2008-08-03"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@grabb.it"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = false
  s.authors = ["J. Chris Anderson", "Greg Borenstein"]
  s.files = %w{
    lib/couchrest.rb
    lib/couch_rest.rb lib/database.rb lib/pager.rb lib/file_manager.rb 
    Rakefile README 
    bin/couchdir bin/couchview 
    spec/couchrest_spec.rb spec/database_spec.rb spec/pager_spec.rb  spec/file_manager_spec.rb
    spec/spec_helper.rb
    }
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'couchview'
  s.executables << 'couchdir'
  s.add_dependency("json", [">= 1.1.2"])
  s.add_dependency("rest-client", [">= 0.5"])
end
