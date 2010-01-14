require 'rake'
require "rake/rdoctask"
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

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "couchrest"
    gemspec.summary = "Lean and RESTful interface to CouchDB."
    gemspec.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
    gemspec.email = "jchris@apache.org"
    gemspec.homepage = "http://github.com/couchrest/couchrest"
    gemspec.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos"]
    gemspec.extra_rdoc_files = %w( README.md LICENSE THANKS.md )
    gemspec.files = %w( LICENSE README.md Rakefile THANKS.md history.txt) + Dir["{examples,lib,spec,utils}/**/*"] - Dir["spec/tmp"]
    gemspec.has_rdoc = true
    gemspec.add_dependency("rest-client", ">= 0.5")
    gemspec.add_dependency("mime-types", ">= 1.15")
    gemspec.version = CouchRest::VERSION
    gemspec.date = "2008-11-22"
    gemspec.require_path = "lib"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_opts = ["--color"]
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

module Rake
  def self.remove_task(task_name)
    Rake.application.instance_variable_get('@tasks').delete(task_name.to_s)
  end
end

Rake.remove_task("github:release")
Rake.remove_task("release")