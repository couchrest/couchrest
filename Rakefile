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
  s.authors = ["J. Chris Anderson"]
  s.files = %w( LICENSE README.md Rakefile THANKS.md ) + 
    Dir["{bin,examples,lib,spec,utils}/**/*"] - 
    Dir["spec/tmp"]
  s.extra_rdoc_files = %w( README.md LICENSE THANKS.md )
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'couchdir'
  s.add_dependency("json", ">= 1.1.2")
  s.add_dependency("rest-client", ">= 0.5")
  s.add_dependency("mime-types", ">= 1.15")
  s.add_dependency("extlib", ">= 0.9.6")
end


desc "create .gemspec file (useful for github)"
task :gemspec do
  filename = "#{spec.name}.gemspec"
  File.open(filename, "w") do |f|
    f.puts spec.to_ruby
  end
end

# desc "Update Github Gemspec"
# task :gemspec do
#   skip_fields = %w(new_platform original_platform)
#   integer_fields = %w(specification_version)
# 
#   result = "Gem::Specification.new do |s|\n"
#   spec.instance_variables.each do |ivar|
#     value = spec.instance_variable_get(ivar)
#     name  = ivar.split("@").last
#     next if skip_fields.include?(name) || value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
#     if name == "dependencies"
#       value.each do |d|
#         dep, *ver = d.to_s.split(" ")
#         result <<  "  s.add_dependency #{dep.inspect}, [#{ /\(([^\,]*)/ . match(ver.join(" "))[1].inspect}]\n"
#       end
#     else        
#       case value
#       when Array
#         value =  name != "files" ? value.inspect : value.inspect.split(",").join(",\n")
#       when Fixnum
#         # leave as-is
#       when String
#         value = value.to_i if integer_fields.include?(name)
#         value = value.inspect
#       else
#         value = value.to_s.inspect
#       end
#       result << "  s.#{name} = #{value}\n"
#     end
#   end
#   result << "end"
#   File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << result}
# end

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
