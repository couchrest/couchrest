class CouchRest
  class Database
    attr_accessor :host, :name
    def initialize host, name
      @name = name
      @host = host
    end
    
    def delete!
      CouchRest.delete "#{host}/#{name}"
    end
  end
end