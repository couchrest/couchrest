#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

thoth_gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'jsmin'
  s.version  = '1.0.0'
  s.author   = 'Ryan Grove'
  s.email    = 'ryan@wonko.com'
  s.homepage = 'http://github.com/rgrove/jsmin/'
  s.platform = Gem::Platform::RUBY
  s.summary  = "Ruby implementation of Douglas Crockford's JSMin JavaScript " +
               "minifier."

  s.files        = FileList['{lib}/**/*', 'HISTORY'].to_a
  s.require_path = 'lib'
  s.has_rdoc     = true

  s.required_ruby_version = '>= 1.8.6'
end

Rake::GemPackageTask.new(thoth_gemspec) do |p|
  p.need_tar_gz = true
end

Rake::RDocTask.new do |rd|
  rd.main     = 'JSMin'
  rd.title    = 'JSMin'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('lib/**/*.rb')
end
