Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "0.8.1"
  s.date = "2008-06-20"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@grabb.it"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = false
  s.authors = ["J. Chris Anderson"]
  s.files = %w{lib/couchrest.rb lib/database.rb lib/pager.rb Rakefile README script/couchdir script/couchview spec/couchrest_spec.rb spec/database_spec.rb spec/pager_spec.rb spec/spec_helper.rb}
  s.require_path = "lib"
  s.add_dependency("json", [">= 1.1.2"])
  s.add_dependency("rest-client", [">= 0.4"])
end
