require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'
require "rake/rdoctask"

Bundler::GemHelper.install_tasks

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["--color"]
  spec.pattern = 'spec/**/*_spec.rb'
end

desc "Print specdocs"
RSpec::Core::RakeTask.new(:doc) do |spec|
  spec.rspec_opts = ["--format", "specdoc"]
  spec.pattern = 'spec/*_spec.rb'
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