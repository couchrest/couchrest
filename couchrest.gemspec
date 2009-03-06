# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couchrest}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J. Chris Anderson", "Matt Aimonetti"]
  s.date = %q{2008-11-22}
  s.description = %q{CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments.}
  s.email = %q{jchris@apache.org}
  s.extra_rdoc_files = ["README.md", "LICENSE", "THANKS.md"]
  s.files = ["LICENSE", "README.md", "Rakefile", "THANKS.md", "examples/model", "examples/model/example.rb", "examples/word_count", "examples/word_count/markov", "examples/word_count/views", "examples/word_count/views/books", "examples/word_count/views/books/chunked-map.js", "examples/word_count/views/books/united-map.js", "examples/word_count/views/markov", "examples/word_count/views/markov/chain-map.js", "examples/word_count/views/markov/chain-reduce.js", "examples/word_count/views/word_count", "examples/word_count/views/word_count/count-map.js", "examples/word_count/views/word_count/count-reduce.js", "examples/word_count/word_count.rb", "examples/word_count/word_count_query.rb", "examples/word_count/word_count_views.rb", "lib/couchrest", "lib/couchrest/commands", "lib/couchrest/commands/generate.rb", "lib/couchrest/commands/push.rb", "lib/couchrest/core", "lib/couchrest/core/database.rb", "lib/couchrest/core/design.rb", "lib/couchrest/core/document.rb", "lib/couchrest/core/response.rb", "lib/couchrest/core/server.rb", "lib/couchrest/core/view.rb", "lib/couchrest/helper", "lib/couchrest/helper/pager.rb", "lib/couchrest/helper/streamer.rb", "lib/couchrest/mixins", "lib/couchrest/mixins/attachments.rb", "lib/couchrest/mixins/callbacks.rb", "lib/couchrest/mixins/design_doc.rb", "lib/couchrest/mixins/document_queries.rb", "lib/couchrest/mixins/extended_attachments.rb", "lib/couchrest/mixins/extended_document_mixins.rb", "lib/couchrest/mixins/properties.rb", "lib/couchrest/mixins/validation.rb", "lib/couchrest/mixins/views.rb", "lib/couchrest/mixins.rb", "lib/couchrest/monkeypatches.rb", "lib/couchrest/more", "lib/couchrest/more/casted_model.rb", "lib/couchrest/more/extended_document.rb", "lib/couchrest/more/property.rb", "lib/couchrest/support", "lib/couchrest/support/blank.rb", "lib/couchrest/support/class.rb", "lib/couchrest/validation", "lib/couchrest/validation/auto_validate.rb", "lib/couchrest/validation/contextual_validators.rb", "lib/couchrest/validation/validation_errors.rb", "lib/couchrest/validation/validators", "lib/couchrest/validation/validators/absent_field_validator.rb", "lib/couchrest/validation/validators/confirmation_validator.rb", "lib/couchrest/validation/validators/format_validator.rb", "lib/couchrest/validation/validators/formats", "lib/couchrest/validation/validators/formats/email.rb", "lib/couchrest/validation/validators/formats/url.rb", "lib/couchrest/validation/validators/generic_validator.rb", "lib/couchrest/validation/validators/length_validator.rb", "lib/couchrest/validation/validators/method_validator.rb", "lib/couchrest/validation/validators/numeric_validator.rb", "lib/couchrest/validation/validators/required_field_validator.rb", "lib/couchrest.rb", "spec/couchrest", "spec/couchrest/core", "spec/couchrest/core/couchrest_spec.rb", "spec/couchrest/core/database_spec.rb", "spec/couchrest/core/design_spec.rb", "spec/couchrest/core/document_spec.rb", "spec/couchrest/core/server_spec.rb", "spec/couchrest/helpers", "spec/couchrest/helpers/pager_spec.rb", "spec/couchrest/helpers/streamer_spec.rb", "spec/couchrest/more", "spec/couchrest/more/casted_extended_doc_spec.rb", "spec/couchrest/more/casted_model_spec.rb", "spec/couchrest/more/extended_doc_attachment_spec.rb", "spec/couchrest/more/extended_doc_spec.rb", "spec/couchrest/more/extended_doc_view_spec.rb", "spec/couchrest/more/property_spec.rb", "spec/couchrest/support", "spec/couchrest/support/class_spec.rb", "spec/fixtures", "spec/fixtures/attachments", "spec/fixtures/attachments/couchdb.png", "spec/fixtures/attachments/README", "spec/fixtures/attachments/test.html", "spec/fixtures/couchapp", "spec/fixtures/couchapp/_attachments", "spec/fixtures/couchapp/_attachments/index.html", "spec/fixtures/couchapp/doc.json", "spec/fixtures/couchapp/foo", "spec/fixtures/couchapp/foo/bar.txt", "spec/fixtures/couchapp/foo/test.json", "spec/fixtures/couchapp/test.json", "spec/fixtures/couchapp/views", "spec/fixtures/couchapp/views/example-map.js", "spec/fixtures/couchapp/views/example-reduce.js", "spec/fixtures/couchapp-test", "spec/fixtures/couchapp-test/my-app", "spec/fixtures/couchapp-test/my-app/_attachments", "spec/fixtures/couchapp-test/my-app/_attachments/index.html", "spec/fixtures/couchapp-test/my-app/foo", "spec/fixtures/couchapp-test/my-app/foo/bar.txt", "spec/fixtures/couchapp-test/my-app/views", "spec/fixtures/couchapp-test/my-app/views/example-map.js", "spec/fixtures/couchapp-test/my-app/views/example-reduce.js", "spec/fixtures/more", "spec/fixtures/more/article.rb", "spec/fixtures/more/card.rb", "spec/fixtures/more/course.rb", "spec/fixtures/more/event.rb", "spec/fixtures/more/invoice.rb", "spec/fixtures/more/person.rb", "spec/fixtures/more/question.rb", "spec/fixtures/more/service.rb", "spec/fixtures/views", "spec/fixtures/views/lib.js", "spec/fixtures/views/test_view", "spec/fixtures/views/test_view/lib.js", "spec/fixtures/views/test_view/only-map.js", "spec/fixtures/views/test_view/test-map.js", "spec/fixtures/views/test_view/test-reduce.js", "spec/spec.opts", "spec/spec_helper.rb", "utils/remap.rb", "utils/subset.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jchris/couchrest}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Lean and RESTful interface to CouchDB.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.1.2"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0.5"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.15"])
    else
      s.add_dependency(%q<json>, [">= 1.1.2"])
      s.add_dependency(%q<rest-client>, [">= 0.5"])
      s.add_dependency(%q<mime-types>, [">= 1.15"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.1.2"])
    s.add_dependency(%q<rest-client>, [">= 0.5"])
    s.add_dependency(%q<mime-types>, [">= 1.15"])
  end
end
