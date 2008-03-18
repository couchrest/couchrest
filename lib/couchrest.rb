require 'uri'

class Couchrest

  def initialize server
    @server = URI.parse server
  end

  def databases
    
  end

end
