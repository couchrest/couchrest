require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require "rake/rdoctask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'couchrest'

begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
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
