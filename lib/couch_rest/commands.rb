require File.join(File.dirname(__FILE__), "..", "couchrest")
  
%w(push generate).each do |filename|
  require File.join(File.dirname(__FILE__), "commands", filename)
end
