# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couchrest}
  s.version = `cat VERSION`.strip

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber", "Sam Lown"]
  s.date = File.mtime('VERSION')
  s.description = %q{CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments.}
  s.email = %q{jchris@apache.org}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "THANKS.md"
  ]
  s.homepage = %q{http://github.com/couchrest/couchrest}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Lean and RESTful interface to CouchDB.}

  s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
  s.add_dependency(%q<mime-types>, ["~> 1.15"])
  s.add_dependency(%q<multi_json>, ["~> 1.0.0"])
  s.add_development_dependency(%q<json>, ["~> 1.5.1"])
  s.add_development_dependency(%q<rspec>, "~> 2.6.0")
end
