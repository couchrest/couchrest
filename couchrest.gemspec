Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "0.9.4"
  s.date = "2008-09-11"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@grabb.it"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = true
  s.authors = ["J. Chris Anderson", "Greg Borenstein"]
  s.files = %w( LICENSE README.rdoc Rakefile ) + Dir["{bin,examples,lib,spec,utils}/**/*"]
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'couchview'
  s.executables << 'couchdir'
  s.add_dependency("json", [">= 1.1.2"])
  s.add_dependency("rest-client", [">= 0.5"])
end
