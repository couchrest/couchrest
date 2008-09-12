Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "0.9.4"
  s.date = "2008-09-11"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@grabb.it"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = false
  s.authors = ["J. Chris Anderson", "Greg Borenstein"]
  s.files = %w{
    lib/couchrest.rb
    lib/couchrest/commands/generate.rb lib/couchrest/commands/push.rb
    lib/couchrest/core/database.rb lib/couchrest/core/server.rb
    lib/couchrest/helper/file_manager.rb lib/couchrest/helper/pager.rb lib/couchrest/helper/streamer.rb
    lib/couchrest/monkeypatches.rb
    Rakefile README.rdoc
    bin/couchdir bin/couchview 
    spec/couchrest_spec.rb spec/database_spec.rb spec/pager_spec.rb  spec/file_manager_spec.rb spec/streamer_spec.rb
    spec/spec_helper.rb
    }
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'couchview'
  s.executables << 'couchdir'
  s.add_dependency("json", [">= 1.1.2"])
  s.add_dependency("rest-client", [">= 0.5"])
end
