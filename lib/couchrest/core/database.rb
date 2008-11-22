require 'cgi'
require "base64"

module CouchRest
  class Database
    attr_reader :server, :host, :name, :root
     
    # Create a CouchRest::Database adapter for the supplied CouchRest::Server
    # and database name.
    #  
    # ==== Parameters
    # server<CouchRest::Server>:: database host
    # name<String>:: database name
    #
    def initialize server, name
      @name = name
      @server = server
      @host = server.uri
      @root = "#{host}/#{name}"
      @streamer = Streamer.new(self)
    end
    
    # returns the database's uri
    def to_s
      @root
    end
    
    # GET the database info from CouchDB
    def info
      CouchRest.get @root
    end
    
    # Query the <tt>_all_docs</tt> view. Accepts all the same arguments as view.
    def documents params = {}
      keys = params.delete(:keys)
      url = CouchRest.paramify_url "#{@root}/_all_docs", params
      if keys
        CouchRest.post(url, {:keys => keys})
      else
        CouchRest.get url
      end
    end
  
    # POST a temporary view function to CouchDB for querying. This is not
    # recommended, as you don't get any performance benefit from CouchDB's
    # materialized views. Can be quite slow on large databases.
    def temp_view funcs, params = {}
      keys = params.delete(:keys)
      funcs = funcs.merge({:keys => keys}) if keys
      url = CouchRest.paramify_url "#{@root}/_temp_view", params
      JSON.parse(RestClient.post(url, funcs.to_json, {"Content-Type" => 'application/json'}))
    end
  
    # Query a CouchDB view as defined by a <tt>_design</tt> document. Accepts
    # paramaters as described in http://wiki.apache.org/couchdb/HttpViewApi
    def view name, params = {}, &block
      keys = params.delete(:keys)
      url = CouchRest.paramify_url "#{@root}/_view/#{name}", params
      if keys
        CouchRest.post(url, {:keys => keys})
      else
        if block_given?
          @streamer.view(name, params, &block)
        else
          CouchRest.get url
        end
      end
    end
    
    # GET a document from CouchDB, by id. Returns a Ruby Hash.
    def get id
      slug = CGI.escape(id) 
      hash = CouchRest.get("#{@root}/#{slug}")
      doc = if /^_design/ =~ hash["_id"]
        Design.new(hash)
      else
        Document.new(hash)
      end
      doc.database = self
      doc
    end
    
    # GET an attachment directly from CouchDB
    def fetch_attachment doc, name
      doc = CGI.escape(doc)
      name = CGI.escape(name)
      RestClient.get "#{@root}/#{doc}/#{name}"
    end
    
    # PUT an attachment directly to CouchDB
    def put_attachment doc, name, file, options = {}
      docid = CGI.escape(doc['_id'])
      name = CGI.escape(name)
      uri = if doc['_rev']
        "#{@root}/#{docid}/#{name}?rev=#{doc['_rev']}"
      else
        "#{@root}/#{docid}/#{name}"
      end
        
      JSON.parse(RestClient.put(uri, file, options))
    end
    
    # Save a document to CouchDB. This will use the <tt>_id</tt> field from
    # the document as the id for PUT, or request a new UUID from CouchDB, if
    # no <tt>_id</tt> is present on the document. IDs are attached to
    # documents on the client side because POST has the curious property of
    # being automatically retried by proxies in the event of network
    # segmentation and lost responses.
    def save doc
      if doc['_attachments']
        doc['_attachments'] = encode_attachments(doc['_attachments'])
      end
      result = if doc['_id']
        slug = CGI.escape(doc['_id'])
        CouchRest.put "#{@root}/#{slug}", doc
      else
        begin
          slug = doc['_id'] = @server.next_uuid
          CouchRest.put "#{@root}/#{slug}", doc
        rescue #old version of couchdb
          CouchRest.post @root, doc
        end
      end
      if result['ok']
        doc['_id'] = result['id']
        doc['_rev'] = result['rev']
        doc.database = self if doc.respond_to?(:database=)
      end
      result
    end
    
    # POST an array of documents to CouchDB. If any of the documents are
    # missing ids, supply one from the uuid cache.
    def bulk_save docs
      ids, noids = docs.partition{|d|d['_id']}
      uuid_count = [noids.length, @server.uuid_batch_count].max
      noids.each do |doc|
        nextid = @server.next_uuid(uuid_count) rescue nil
        doc['_id'] = nextid if nextid
      end
      CouchRest.post "#{@root}/_bulk_docs", {:docs => docs}
    end
    
    # DELETE the document from CouchDB that has the given <tt>_id</tt> and
    # <tt>_rev</tt>.
    def delete doc
      raise ArgumentError, "_id and _rev required for deleting" unless doc['_id'] && doc['_rev']
      
      slug = CGI.escape(doc['_id'])
      CouchRest.delete "#{@root}/#{slug}?rev=#{doc['_rev']}"
    end
    
    # DELETE the database itself. This is not undoable and could be rather
    # catastrophic. Use with care!
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
