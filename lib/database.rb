require 'cgi'

class CouchRest
  class Database
    attr_accessor :host, :name
    def initialize host, name
      @name = name
      @host = host
      @root = "#{host}/#{name}"
    end
    
    def documents
      view "_all_docs"
    end
  
    def temp_view func
      # CouchRest.post "#{@root}/_temp_view", func
      # headers: {"Content-Type": "text/javascript"},
      # ripping from CouchRest because leaky abstraction.
      # payload = JSON.unparse doc if doc
      JSON.parse(RestClient.post("#{@root}/_temp_view", func, {"Content-Type" => "text/javascript"}))
    end
  
    def view name
      CouchRest.get "#{@root}/#{name}"      
    end
  
    def get id
      slug = CGI.escape(id)
      CouchRest.get "#{@root}/#{slug}"
    end
    
    # PUT or POST depending on precense of _id attribute
    def save doc
      if doc['_id']
        slug = CGI.escape(doc['_id'])
        CouchRest.put "#{@root}/#{slug}", doc
      else
        CouchRest.post "#{@root}", doc
      end
    end
    
    def bulk_save docs
      CouchRest.post "#{@root}/_bulk_docs", docs
    end
    
    def delete doc
      slug = CGI.escape(doc['_id'])
      CouchRest.delete "#{@root}/#{slug}?rev=#{doc['_rev']}"
    end
    
    def delete!
      CouchRest.delete @root
    end
  end
end