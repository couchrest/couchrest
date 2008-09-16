require 'rake'
require "rake/rdoctask"
require 'spec/rake/spectask'


spec = Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "0.9.8"
  s.date = "2008-09-11"
  s.summary = "Lean and RESTful interface to CouchDB."
  s.email = "jchris@grabb.it"
  s.homepage = "http://github.com/jchris/couchrest"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.has_rdoc = true
  s.authors = ["J. Chris Anderson"]
  s.files = %w( LICENSE README.rdoc Rakefile THANKS ) + Dir["{bin,examples,lib,spec,utils}/**/*"]
  s.extra_rdoc_files = %w( README.rdoc LICENSE THANKS )
  s.require_path = "lib"
  s.bindir = 'bin'
  s.executables << 'couchview'
  s.executables << 'couchdir'
  s.executables << 'couchapp'
  s.add_dependency("json", ">= 1.1.2")
  s.add_dependency("rest-client", ">= 0.5")
end

namespace :github do # thanks merb!
  desc "Update Github Gemspec"
  task :update_gemspec do
    skip_fields = %w(new_platform original_platform)
    integer_fields = %w(specification_version)

    result = "Gem::Specification.new do |s|\n"
    spec.instance_variables.each do |ivar|
      value = spec.instance_variable_get(ivar)
      name  = ivar.split("@").last
      next if skip_fields.include?(name) || value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
      if name == "dependencies"
        value.each do |d|
          dep, *ver = d.to_s.split(" ")
          result <<  "  s.add_dependency #{dep.inspect}, [#{ /\(([^\,]*)/ . match(ver.join(" "))[1].inspect}]\n"
        end
      else        
        case value
        when Array
          value =  name != "files" ? value.inspect : value.inspect.split(",").join(",\n")
        when Fixnum
          # leave as-is
        when String
          value = value.to_i if integer_fields.include?(name)
          value = value.inspect
        else
          value = value.to_s.inspect
        end
        result << "  s.#{name} = #{value}\n"
      end
    end
    result << "end"
    File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << result}
  end
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc", "--dry-run"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Generate the rdoc"
Rake::RDocTask.new do |rdoc|
  files = ["README.rdoc", "LICENSE", "lib/**/*.rb"]
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc"
  rdoc.title = "CouchRest: Ruby CouchDB, close to the metal"
end

desc "Generate the gemspec"




task :default => :spec
