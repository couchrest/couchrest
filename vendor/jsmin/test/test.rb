require '../lib/jsmin'

File.open('jslint.js', 'r') do |input|
  File.open('out-ruby.js', 'w') {|output| output << JSMin.minify(input) }
end
