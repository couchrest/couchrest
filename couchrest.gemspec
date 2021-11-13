# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couchrest}
  s.version = `cat VERSION`.strip
  s.license = "Apache License 2.0"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber", "Sam Lown"]
  s.date = File.mtime('VERSION')
  s.description = %q{CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments.}
  s.email = %q{me@samlown.com}

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
  s.summary = %q{Lean and RESTful interface to CouchDB.}

  s.add_dependency "httpclient", ["~> 2.8"]
  s.add_dependency "multi_json", ["~> 1.7"]
  s.add_dependency "mime-types", [">= 1.15"]

  s.add_development_dependency "bundler" #, "~> 1.3"
  # s.add_development_dependency "json", ">= 2.0.1"
  s.add_development_dependency "rspec", "~> 2.14.1"
  s.add_development_dependency "rake", "< 11.0"
  s.add_development_dependency "webmock"
end
