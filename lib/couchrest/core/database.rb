require 'cgi'
require "base64"

module CouchRest
  class Database
    attr_reader :server, :host, :name, :root, :uri
    attr_accessor :bulk_save_cache_limit
     
    # Create a CouchRest::Database adapter for the supplied CouchRest::Server
    # and database name.
    #  
    # ==== Parameters
    # server<CouchRest::Server>:: database host
    # name<String>:: database name
    #
    def initialize(server, name)
      @name = name
      @server = server
      @host = server.uri
      @uri  = "/#{name.gsub('/','%2F')}"
      @root = host + uri
      @streamer = Streamer.new(self)
      @bulk_save_cache = []
      @bulk_save_cache_limit = 500  # must be smaller than the uuid count
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
    def documents(params = {})
      keys = params.delete(:keys)
      url = CouchRest.paramify_url "#{@root}/_all_docs", params
      if keys
        CouchRest.post(url, {:keys => keys})
      else
        CouchRest.get url
      end
    end
  
    # load a set of documents by passing an array of ids
    def get_bulk(ids)
      documents(:keys => ids, :include_docs => true)
    end
    alias :bulk_load :get_bulk
  
    # POST a temporary view function to CouchDB for querying. This is not
    # recommended, as you don't get any performance benefit from CouchDB's
    # materialized views. Can be quite slow on large databases.
    def slow_view(funcs, params = {})
      keys = params.delete(:keys)
      funcs = funcs.merge({:keys => keys}) if keys
      url = CouchRest.paramify_url "#{@root}/_temp_view", params
      JSON.parse(HttpAbstraction.post(url, funcs.to_json, {"Content-Type" => 'application/json'}))
    end
    
    # backwards compatibility is a plus
    alias :temp_view :slow_view
  
    # Query a CouchDB view as defined by a <tt>_design</tt> document. Accepts
    # paramaters as described in http://wiki.apache.org/couchdb/HttpViewApi
    def view(name, params = {}, &block)
      keys = params.delete(:keys)
      name = name.split('/') # I think this will always be length == 2, but maybe not...
      dname = name.shift
      vname = name.join('/')
      url = CouchRest.paramify_url "#{@root}/_design/#{dname}/_view/#{vname}", params
      if keys
        CouchRest.post(url, {:keys => keys})
      else
        if block_given?
          @streamer.view("_design/#{dname}/_view/#{vname}", params, &block)
        else
          CouchRest.get url
        end
      end
    end
    
    # GET a document from CouchDB, by id. Returns a Ruby Hash.
    def get(id, params = {})
      slug = escape_docid(id)
      url = CouchRest.paramify_url("#{@root}/#{slug}", params)
      result = CouchRest.get(url)
      return result unless result.is_a?(Hash)
      doc = if /^_design/ =~ result["_id"]
        Design.new(result)
      else
        Document.new(result)
      end
      doc.database = self
      doc
    end
    
    # GET an attachment directly from CouchDB
    def fetch_attachment(doc, name)
      uri = url_for_attachment(doc, name)
      HttpAbstraction.get uri
    end
    
    # PUT an attachment directly to CouchDB
    def put_attachment(doc, name, file, options = {})
      docid = escape_docid(doc['_id'])
      uri = url_for_attachment(doc, name)
      JSON.parse(HttpAbstraction.put(uri, file, options))
    end
    
    # DELETE an attachment directly from CouchDB
    def delete_attachment(doc, name, force=false)
      uri = url_for_attachment(doc, name)
      # this needs a rev
      begin
        JSON.parse(HttpAbstraction.delete(uri))
      rescue Exception => error
        if force
          # get over a 409
          doc = get(doc['_id'])
          uri = url_for_attachment(doc, name)
          JSON.parse(HttpAbstraction.delete(uri))
        else
          error
        end
      end
    end

    # Save a document to CouchDB. This will use the <tt>_id</tt> field from
    # the document as the id for PUT, or request a new UUID from CouchDB, if
    # no <tt>_id</tt> is present on the document. IDs are attached to
    # documents on the client side because POST has the curious property of
    # being automatically retried by proxies in the event of network
    # segmentation and lost responses.
    #
    # If <tt>bulk</tt> is true (false by default) the document is cached for bulk-saving later.
    # Bulk saving happens automatically when #bulk_save_cache limit is exceded, or on the next non bulk save.
    #
    # If <tt>batch</tt> is true (false by default) the document is saved in
    # batch mode, "used to achieve higher throughput at the cost of lower
    # guarantees. When [...] sent using this option, it is not immediately
    # written to disk. Instead it is stored in memory on a per-user basis for a
    # second or so (or the number of docs in memory reaches a certain point).
    # After the threshold has passed, the docs are committed to disk. Instead
    # of waiting for the doc to be written to disk before responding, CouchDB
    # sends an HTTP 202 Accepted response immediately. batch=ok is not suitable
    # for crucial data, but it ideal for applications like logging which can
    # accept the risk that a small proportion of updates could be lost due to a
    # crash."
    def save_doc(doc, bulk = false, batch = false)
      if doc['_attachments']
        doc['_attachments'] = encode_attachments(doc['_attachments'])
      end
      if bulk
        @bulk_save_cache << doc
        bulk_save if @bulk_save_cache.length >= @bulk_save_cache_limit
        return {"ok" => true} # Compatibility with Document#save
      elsif !bulk && @bulk_save_cache.length > 0
        bulk_save
      end
      result = if doc['_id']
        slug = escape_docid(doc['_id'])
        begin     
          uri = "#{@root}/#{slug}"
          uri << "?batch=ok" if batch
          CouchRest.put uri, doc
        rescue HttpAbstraction::ResourceNotFound
          p "resource not found when saving even tho an id was passed"
          slug = doc['_id'] = @server.next_uuid
          CouchRest.put "#{@root}/#{slug}", doc
        end
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
    
    # Save a document to CouchDB in bulk mode. See #save_doc's +bulk+ argument.
    def bulk_save_doc(doc)
      save_doc(doc, true)
    end

    # Save a document to CouchDB in batch mode. See #save_doc's +batch+ argument.
    def batch_save_doc(doc)
      save_doc(doc, false, true)
    end
    
    # POST an array of documents to CouchDB. If any of the documents are
    # missing ids, supply one from the uuid cache.
    #
    # If called with no arguments, bulk saves the cache of documents to be bulk saved.
    def bulk_save(docs = nil, use_uuids = true)
      if docs.nil?
        docs = @bulk_save_cache
        @bulk_save_cache = []
      end
      if (use_uuids) 
        ids, noids = docs.partition{|d|d['_id']}
        uuid_count = [noids.length, @server.uuid_batch_count].max
        noids.each do |doc|
          nextid = @server.next_uuid(uuid_count) rescue nil
          doc['_id'] = nextid if nextid
        end
      end
      CouchRest.post "#{@root}/_bulk_docs", {:docs => docs}
    end
    alias :bulk_delete :bulk_save
    
    # DELETE the document from CouchDB that has the given <tt>_id</tt> and
    # <tt>_rev</tt>.
    #
    # If <tt>bulk</tt> is true (false by default) the deletion is recorded for bulk-saving (bulk-deletion :) later.
    # Bulk saving happens automatically when #bulk_save_cache limit is exceded, or on the next non bulk save.
    def delete_doc(doc, bulk = false)
      raise ArgumentError, "_id and _rev required for deleting" unless doc['_id'] && doc['_rev']      
      if bulk
        @bulk_save_cache << { '_id' => doc['_id'], '_rev' => doc['_rev'], '_deleted' => true }
        return bulk_save if @bulk_save_cache.length >= @bulk_save_cache_limit
        return { "ok" => true } # Mimic the non-deferred version
      end
      slug = escape_docid(doc['_id'])        
      CouchRest.delete "#{@root}/#{slug}?rev=#{doc['_rev']}"
    end
    
    # COPY an existing document to a new id. If the destination id currently exists, a rev must be provided.
    # <tt>dest</tt> can take one of two forms if overwriting: "id_to_overwrite?rev=revision" or the actual doc
    # hash with a '_rev' key
    def copy_doc(doc, dest)
      raise ArgumentError, "_id is required for copying" unless doc['_id']
      slug = escape_docid(doc['_id'])        
      destination = if dest.respond_to?(:has_key?) && dest['_id'] && dest['_rev']
        "#{dest['_id']}?rev=#{dest['_rev']}"
      else
        dest
      end
      CouchRest.copy "#{@root}/#{slug}", destination
    end
    
    # Updates the given doc by yielding the current state of the doc
    # and trying to update update_limit times. Returns the new doc
    # if the doc was successfully updated without hitting the limit
    def update_doc(doc_id, params = {}, update_limit=10)
      resp = {'ok' => false}
      new_doc = nil
      last_fail = nil

      until resp['ok'] or update_limit <= 0
        doc = self.get(doc_id, params)  # grab the doc
        new_doc = yield doc # give it to the caller to be updated
        begin
          resp = self.save_doc new_doc # try to PUT the updated doc into the db
        rescue RestClient::RequestFailed => e
          if e.http_code == 409 # Update collision
            update_limit -= 1
            last_fail = e
          else # some other error
            raise e
          end
        end
      end

      raise last_fail unless resp['ok']
      new_doc
    end
    
    # Compact the database, removing old document revisions and optimizing space use.
    def compact!
      CouchRest.post "#{@root}/_compact"
    end
    
    # Create the database
    def create!
      bool = server.create_db(@name) rescue false
      bool && true
    end
    
    # Delete and re create the database
    def recreate!
      delete!
      create!
    rescue RestClient::ResourceNotFound
    ensure
      create!
    end
    
    # Replicates via "pulling" from another database to this database. Makes no attempt to deal with conflicts.
    def replicate_from other_db
      raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(CouchRest::Database)
      CouchRest.post "#{@host}/_replicate", :source => other_db.root, :target => name
    end
    
    # Replicates via "pushing" to another database. Makes no attempt to deal with conflicts.
    def replicate_to other_db
      raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(CouchRest::Database)
      CouchRest.post "#{@host}/_replicate", :target => other_db.root, :source => name
    end
    
    # DELETE the database itself. This is not undoable and could be rather
    # catastrophic. Use with care!
    def delete!
      clear_extended_doc_fresh_cache
      CouchRest.delete @root
    end

    private
    
    def clear_extended_doc_fresh_cache
      ::CouchRest::ExtendedDocument.subclasses.each{|klass| klass.design_doc_fresh = false if klass.respond_to?(:design_doc_fresh=) }
    end

    def uri_for_attachment(doc, name)
      if doc.is_a?(String)
        puts "CouchRest::Database#fetch_attachment will eventually require a doc as the first argument, not a doc.id"
        docid = doc
        rev = nil
      else
        docid = doc['_id']
        rev = doc['_rev']
      end
      docid = escape_docid(docid)
      name = CGI.escape(name)
      rev = "?rev=#{doc['_rev']}" if rev
      "/#{docid}/#{name}#{rev}"
    end

    def url_for_attachment(doc, name)
      @root + uri_for_attachment(doc, name)
    end
    
    def escape_docid id      
      /^_design\/(.*)/ =~ id ? "_design/#{CGI.escape($1)}" : CGI.escape(id) 
    end

    def encode_attachments(attachments)
      attachments.each do |k,v|
        next if v['stub']
        v['data'] = base64(v['data'])
      end
      attachments
    end

    def base64(data)
      Base64.encode64(data).gsub(/\s/,'')
    end
  end
end
