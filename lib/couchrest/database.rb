require 'cgi'
require "base64"

module CouchRest
  class Database

    # Server object we'll use to communicate with.
    attr_reader :server
    
    # Name of the database of we're using.
    attr_reader :name

    # Name of the database we can use in requests.
    attr_reader :path

    # How many documents should be cached before peforming the bulk save operation
    attr_accessor :bulk_save_cache_limit

    # Create a CouchRest::Database adapter for the supplied CouchRest::Server
    # and database name.
    #
    # ==== Parameters
    # server<CouchRest::Server>:: database host
    # name<String>:: database name
    #
    def initialize(server, name)
      @name     = name
      @server   = server
      @path     = "/#{CGI.escape(name)}"
      @bulk_save_cache = []
      @bulk_save_cache_limit = 500  # must be smaller than the uuid count
    end

    def connection
      server.connection
    end

    # A URI object for the exact location of this database
    def uri
      server.uri + path 
    end
    alias root uri

    # String of #root
    def to_s
      uri.to_s
    end

    # GET the database info from CouchDB
    def info
      connection.get path
    end

    # Compact the database, removing old document revisions and optimizing space use.
    def compact!
      connection.post "#{path}/_compact"
    end

    # Create the database
    def create!
      bool = server.create_db(path) rescue false
      bool && true
    end

    # Delete and re create the database
    def recreate!
      delete!
      create!
    rescue CouchRest::NotFound
    ensure
      create!
    end

    # Replicates via "pulling" from another database to this database. Makes no attempt to deal with conflicts.
    def replicate_from(other_db, continuous = false, create_target = false, doc_ids = nil)
      replicate(other_db, continuous, :target => name, :create_target => create_target, :doc_ids => doc_ids)
    end

    # Replicates via "pushing" to another database. Makes no attempt to deal with conflicts.
    def replicate_to(other_db, continuous = false, create_target = false, doc_ids = nil)
      replicate(other_db, continuous, :source => name, :create_target => create_target, :doc_ids => doc_ids)
    end

    # DELETE the database itself. This is not undoable and could be rather
    # catastrophic. Use with care!
    def delete!
      connection.delete path
    end


    # == Retrieving and saving single documents

    # GET a document from CouchDB, by id. Returns a Document, Design, or raises an exception
    # if the document does not exist.
    def get!(id, params = {})
      slug = escape_docid(id)
      url = CouchRest.paramify_url("#{path}/#{slug}", params)
      result = connection.get(url)
      return result unless result.is_a?(Hash)
      doc = if /^_design/ =~ result["_id"]
        Design.new(result)
      else
        Document.new(result)
      end
      doc.database = self
      doc
    end

    # GET the requested document by ID like `get!`, but returns nil if the document
    # does not exist.
    def get(*args)
      get!(*args)
    rescue CouchRest::NotFound
      nil
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
        return {'ok' => true} # Compatibility with Document#save
      elsif !bulk && @bulk_save_cache.length > 0
        bulk_save
      end
      result = if doc['_id']
        slug = escape_docid(doc['_id'])
        begin
          doc_path = "#{path}/#{slug}"
          doc_path << "?batch=ok" if batch
          connection.put doc_path, doc
        rescue CouchRest::NotFound
          puts "resource not found when saving even though an id was passed"
          slug = doc['_id'] = server.next_uuid
          connection.put "#{path}/#{slug}", doc
        end
      else
        slug = doc['_id'] = @server.next_uuid
        connection.put "#{path}/#{slug}", doc
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
    def bulk_save(docs = nil, opts = {})
      opts = { :use_uuids => true, :all_or_nothing => false }.update(opts)
      if docs.nil?
        docs = @bulk_save_cache
        @bulk_save_cache = []
      end
      if opts[:use_uuids]
        ids, noids = docs.partition{|d|d['_id']}
        uuid_count = [noids.length, @server.uuid_batch_count].max
        noids.each do |doc|
          nextid = server.next_uuid(uuid_count) rescue nil
          doc['_id'] = nextid if nextid
        end
      end
      request_body = {:docs => docs}
      if opts[:all_or_nothing]
        request_body[:all_or_nothing] = true
      end
      connection.post "#{path}/_bulk_docs", request_body
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
        @bulk_save_cache << { '_id' => doc['_id'], '_rev' => doc['_rev'], :_deleted => true }
        return bulk_save if @bulk_save_cache.length >= @bulk_save_cache_limit
        return {'ok' => true} # Mimic the non-deferred version
      end
      slug = escape_docid(doc['_id'])        
      connection.delete "#{path}/#{slug}?rev=#{doc['_rev']}"
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
      connection.copy "#{path}/#{slug}", destination
    end

    # Updates the given doc by yielding the current state of the doc
    # and trying to update update_limit times. Returns the doc
    # if successfully updated without hitting the limit.
    # If the limit is reached, the last execption will be raised.
    def update_doc(doc_id, params = {}, update_limit = 10)
      resp = {'ok' => false}
      last_fail = nil

      until resp['ok'] or update_limit <= 0
        doc = self.get(doc_id, params)
        yield doc
        begin
          resp = self.save_doc doc
        rescue CouchRest::RequestFailed => e
          if e.http_code == 409 # Update collision
            update_limit -= 1
            last_fail = e
          else
            raise e
          end
        end
      end

      raise last_fail unless resp['ok']
      doc
    end


    # == View and multi-document based queries

    # Query a CouchDB view as defined by a <tt>_design</tt> document. Accepts
    # paramaters as described in http://wiki.apache.org/couchdb/HttpViewApi
    def view(name, params = {}, payload = {}, &block)
      opts = {}
      params = params.dup
      payload['keys'] = params.delete(:keys) if params[:keys]

      # Continuous feeds need to be parsed differently
      opts[:continuous] = true if params['feed'] == 'continuous'

      # Try recognising the name, otherwise assume already prepared
      view_path = name_to_view_path(name)
      req_path = CouchRest.paramify_url("#{path}/#{view_path}", params)

      if payload.empty?
        connection.get req_path, opts, &block
      else
        connection.post req_path, payload, opts, &block
      end
    end

    # POST a temporary view function to CouchDB for querying. This is not
    # recommended, as you don't get any performance benefit from CouchDB's
    # materialized views. Can be quite slow on large databases.
    def temp_view(payload, params = {}, &block)
      view('_temp_view', params, payload, &block)
    end
    alias :slow_view :temp_view


    # Query the <tt>_all_docs</tt> view. Accepts all the same arguments as view.
    def all_docs(params = {}, payload = {}, &block)
      view("_all_docs", params, payload, &block)
    end
    alias :documents :all_docs

    # Query CouchDB's special <tt>_changes</tt> feed for the latest.
    # All standard CouchDB options can be provided.
    #
    # Warning: sending :feed => 'continuous' will cause your code to block
    # indefinetly while waiting for changes. You might want to look-up an
    # alternative to this.
    def changes(params = {}, payload = {}, &block)
      view("_changes", params, payload, &block)
    end

    # Query a CouchDB-Lucene search view
    def fti(name, params={})
      # -> http://localhost:5984/yourdb/_fti/YourDesign/by_name?include_docs=true&q=plop*'
      view("_fti/#{name}", params)
    end
    alias :search :fti

    # load a set of documents by passing an array of ids
    def get_bulk(ids)
      all_docs(:keys => ids, :include_docs => true)
    end
    alias :bulk_load :get_bulk


    # == Handling attachments

    # GET an attachment directly from CouchDB
    def fetch_attachment(doc, name)
      connection.get path_for_attachment(doc, name), :raw => true
    end

    # PUT an attachment directly to CouchDB, expects an IO object, or a string
    # that will be converted to a StringIO in the 'file' parameter.
    def put_attachment(doc, name, file, options = {})
      file = StringIO.new(file) if file.is_a?(String)
      connection.put path_for_attachment(doc, name), file, options
    end

    # DELETE an attachment directly from CouchDB
    def delete_attachment(doc, name, force=false)
      attach_path = path_for_attachment(doc, name)
      begin
        connection.delete(attach_path)
      rescue Exception => error
        if force
          # get over a 409
          doc = get(doc['_id'])
          attach_path = path_for_attachment(doc, name)
          connection.delete(attach_path)
        else
          error
        end
      end
    end

    private

    def replicate(other_db, continuous, options)
      raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(CouchRest::Database)
      raise ArgumentError, "must provide a target or source option" unless (options.key?(:target) || options.key?(:source))
      doc_ids = options.delete(:doc_ids)
      payload = options
      if options.has_key?(:target)
        payload[:source] = other_db.root.to_s
      else
        payload[:target] = other_db.root.to_s
      end
      payload[:continuous] = continuous
      payload[:doc_ids] = doc_ids if doc_ids
      
      # Use a short lived request here
      connection.post "_replicate", payload
    end

    def path_for_attachment(doc, name)
      docid = escape_docid(doc['_id'])
      name  = CGI.escape(name)
      rev   = doc['_rev'] ? "?rev=#{doc['_rev']}" : ''
      "#{path}/#{docid}/#{name}#{rev}"
    end

    def escape_docid id
      /^_design\/(.*)/ =~ id ? "_design/#{CGI.escape($1)}" : CGI.escape(id) 
    end

    def encode_attachments(attachments)
      attachments.each do |k,v|
        next if v['stub'] || v['data'].frozen?
        v['data'] = base64(v['data']).freeze
      end
      attachments
    end

    def base64(data)
      Base64.encode64(data).gsub(/\s/,'')
    end

    # Convert a simplified view name into a complete view path. If
    # the name already starts with a "_" no alterations will be made.
    def name_to_view_path(name)
      name =~ /^([^_].*?)\/(.*)$/ ? "_design/#{$1}/_view/#{$2}" : name
    end
  end
end
