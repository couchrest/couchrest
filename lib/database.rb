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
      CouchRest.get "#{@root}/_all_docs"      
    end
  
    def temp_view funcs, params = nil
      url = CouchRest.paramify_url "#{@root}/_temp_view", params
      JSON.parse(RestClient.post(url, JSON.unparse(funcs), {"Content-Type" => 'application/json'}))
    end
  
    def view name, params = nil
      url = CouchRest.paramify_url "#{@root}/_view/#{name}", params
      CouchRest.get url
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
      CouchRest.post "#{@root}/_bulk_docs", {:docs => docs}
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