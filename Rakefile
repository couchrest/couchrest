require 'rake'
require "rake/rdoctask"
require 'rake/gempackagetask'
require File.join(File.expand_path(File.dirname(__FILE__)),'lib','couchrest')


begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end

spec = Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = CouchRest::VERSION
  s.date = "2008-11-22"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@apache.org"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = true
  s.authors = ["J. Chris Anderson", "Matt Aimonetti"]
  s.files = %w( LICENSE README.md Rakefile THANKS.md ) + 
    Dir["{examples,lib,spec,utils}/**/*"] - 
    Dir["spec/tmp"]
  s.extra_rdoc_files = %w( README.md LICENSE THANKS.md )
  s.require_path = "lib"
  s.add_dependency("json", ">= 1.1.2")
  s.add_dependency("rest-client", ">= 0.5")
  s.add_dependency("mime-types", ">= 1.15")
end


desc "Create .gemspec file (useful for github)"
task :gemspec do
  filename = "#{spec.name}.gemspec"
  File.open(filename, "w") do |f|
    f.puts spec.to_ruby
  end
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem locally"
task :install => [:package] do
  sh %{sudo gem install pkg/couchrest-#{CouchRest::VERSION}}
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Generate the rdoc"
Rake::RDocTask.new do |rdoc|
  files = ["README.rdoc", "LICENSE", "lib/**/*.rb"]
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc"
  rdoc.title = "CouchRest: Ruby CouchDB, close to the metal"
end

desc "Run the rspec"
task :default => :spec
