Gem::Specification.new do |s|
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "THANKS"]
  s.date = "Tue Oct 14 00:00:00 -0700 2008"
  s.executables = ["couchview", "couchdir", "couchapp"]
  s.authors = ["J. Chris Anderson"]
  s.required_rubygems_version = ">= 0"
  s.version = "0.9.14"
  s.files = ["LICENSE",
 "README.rdoc",
 "Rakefile",
 "THANKS",
 "bin/couchapp",
 "bin/couchdir",
 "bin/couchview",
 "examples/model",
 "examples/model/example.rb",
 "examples/word_count",
 "examples/word_count/markov",
 "examples/word_count/views",
 "examples/word_count/views/books",
 "examples/word_count/views/books/chunked-map.js",
 "examples/word_count/views/books/united-map.js",
 "examples/word_count/views/markov",
 "examples/word_count/views/markov/chain-map.js",
 "examples/word_count/views/markov/chain-reduce.js",
 "examples/word_count/views/word_count",
 "examples/word_count/views/word_count/count-map.js",
 "examples/word_count/views/word_count/count-reduce.js",
 "examples/word_count/word_count.rb",
 "examples/word_count/word_count_query.rb",
 "lib/couchrest",
 "lib/couchrest/commands",
 "lib/couchrest/commands/generate.rb",
 "lib/couchrest/commands/push.rb",
 "lib/couchrest/core",
 "lib/couchrest/core/database.rb",
 "lib/couchrest/core/model.rb",
 "lib/couchrest/core/server.rb",
 "lib/couchrest/helper",
 "lib/couchrest/helper/file_manager.rb",
 "lib/couchrest/helper/pager.rb",
 "lib/couchrest/helper/streamer.rb",
 "lib/couchrest/helper/templates",
 "lib/couchrest/helper/templates/bar.txt",
 "lib/couchrest/helper/templates/example-map.js",
 "lib/couchrest/helper/templates/example-reduce.js",
 "lib/couchrest/helper/templates/index.html",
 "lib/couchrest/monkeypatches.rb",
 "lib/couchrest.rb",
 "spec/couchapp_spec.rb",
 "spec/couchrest",
 "spec/couchrest/core",
 "spec/couchrest/core/couchrest_spec.rb",
 "spec/couchrest/core/database_spec.rb",
 "spec/couchrest/core/model_spec.rb",
 "spec/couchrest/helpers",
 "spec/couchrest/helpers/file_manager_spec.rb",
 "spec/couchrest/helpers/pager_spec.rb",
 "spec/couchrest/helpers/streamer_spec.rb",
 "spec/fixtures",
 "spec/fixtures/attachments",
 "spec/fixtures/attachments/couchdb.png",
 "spec/fixtures/attachments/test.html",
 "spec/fixtures/views",
 "spec/fixtures/views/lib.js",
 "spec/fixtures/views/test_view",
 "spec/fixtures/views/test_view/lib.js",
 "spec/fixtures/views/test_view/only-map.js",
 "spec/fixtures/views/test_view/test-map.js",
 "spec/fixtures/views/test_view/test-reduce.js",
 "spec/spec.opts",
 "spec/spec_helper.rb",
 "utils/remap.rb",
 "utils/subset.rb"]
  s.has_rdoc = "true"
  s.specification_version = 2
  s.loaded = "false"
  s.email = "jchris@grabb.it"
  s.name = "couchrest"
  s.required_ruby_version = ">= 0"
  s.bindir = "bin"
  s.rubygems_version = "1.2.0"
  s.homepage = "http://github.com/jchris/couchrest"
  s.platform = "ruby"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.add_dependency "json", [">= 1.1.2"]
  s.add_dependency "rest-client", [">= 0.5"]
  s.add_dependency "extlib", [">= 0.9.6"]
  s.require_paths = ["lib"]
end