require 'cgi'
require "base64"

module CouchRest
  class Database
    attr_reader :server, :host, :name, :root
     
    def initialize server, name
      @name = name
      @server = server
      @host = server.uri
      @root = "#{host}/#{name}"
    end
    
    def to_s
      @root
    end
    
    def info
      CouchRest.get @root
    end
    
    def documents params = nil
      url = CouchRest.paramify_url "#{@root}/_all_docs", params
      CouchRest.get url  
    end
  
    def temp_view funcs, params = nil
      url = CouchRest.paramify_url "#{@root}/_temp_view", params
      JSON.parse(RestClient.post(url, funcs.to_json, {"Content-Type" => 'application/json'}))
    end
  
    def view name, params = nil
      url = CouchRest.paramify_url "#{@root}/_view/#{name}", params
      CouchRest.get url
    end

    # experimental
    def search params = nil
      url = CouchRest.paramify_url "#{@root}/_search", params
      CouchRest.get url
    end
    # experimental
    def action action, params = nil
      url = CouchRest.paramify_url "#{@root}/_action/#{action}", params
      CouchRest.get url
    end
    
    def get id
      slug = CGI.escape(id) 
      CouchRest.get "#{@root}/#{slug}"
    end
    
    def fetch_attachment doc, name
      doc = CGI.escape(doc)
      name = CGI.escape(name)
      RestClient.get "#{@root}/#{doc}/#{name}"
    end
    
    # PUT or POST depending on presence of _id attribute
    def save doc
      if doc['_attachments']
        doc['_attachments'] = encode_attachments(doc['_attachments'])
      end
      if doc['_id']
        slug = CGI.escape(doc['_id'])
      else
        slug = doc['_id'] = @server.next_uuid
      end
      CouchRest.put "#{@root}/#{slug}", doc
    end
    
    def bulk_save docs
      ids, noids = docs.partition{|d|d['_id']}
      uuid_count = [noids.length, @server.uuid_batch_count].max
      noids.each do |doc|
        doc['_id'] = @server.next_uuid(uuid_count)
      end
      CouchRest.post "#{@root}/_bulk_docs", {:docs => docs}
    end
    
    def delete doc
      slug = CGI.escape(doc['_id'])
      CouchRest.delete "#{@root}/#{slug}?rev=#{doc['_rev']}"
    end
    
    def delete!
      CouchRest.delete @root
    end

    private

    def encode_attachments attachments
      attachments.each do |k,v|
        next if v['stub']
        v['data'] = base64(v['data'])
      end
      attachments
    end

    def base64 data
      Base64.encode64(data).gsub(/\s/,'')
    end
  end
end
