module CouchRest
  class Response < Hash
    def initialize(keys = {})
      keys.each do |k,v|
        self[k.to_s] = v
      end
    end
    def []= key, value
      super(key.to_s, value)
    end
    def [] key
      super(key.to_s)
    end
  end
  
  class Document < Response
    include CouchRest::Mixins::Views

    attr_accessor :database
    @@database = nil
    
    # override the CouchRest::Model-wide default_database
    # This is not a thread safe operation, do not change the model
    # database at runtime.
    def self.use_database(db)
      @@database = db
    end
    
    def self.database
      @@database
    end
    
    def id
      self['_id']
    end
    
    def rev
      self['_rev']
    end
    
    # copies the document to a new id. If the destination id currently exists, a rev must be provided.
    # <tt>dest</tt> can take one of two forms if overwriting: "id_to_overwrite?rev=revision" or the actual doc
    # hash with a '_rev' key
    def copy(dest)
      raise ArgumentError, "doc.database required to copy" unless database
      result = database.copy_doc(self, dest)
      result['ok']
    end
    
    # moves the document to a new id. If the destination id currently exists, a rev must be provided.
    # <tt>dest</tt> can take one of two forms if overwriting: "id_to_overwrite?rev=revision" or the actual doc
    # hash with a '_rev' key
    def move(dest)
      raise ArgumentError, "doc.database required to copy" unless database
      result = database.move_doc(self, dest)
      result['ok']
    end
    
    # Returns the CouchDB uri for the document
    def uri(append_rev = false)
      return nil if new_document?
      couch_uri = "http://#{database.uri}/#{CGI.escape(id)}"
      if append_rev == true
        couch_uri << "?rev=#{rev}"
      elsif append_rev.kind_of?(Integer)
        couch_uri << "?rev=#{append_rev}"
      end
      couch_uri
    end
    
    # Returns the document's database
    def database
      @database || self.class.database
    end
    
    # saves an attachment directly to couchdb
    def put_attachment(name, file, options={})
      raise ArgumentError, "doc must be saved" unless self.rev
      raise ArgumentError, "doc.database required to put_attachment" unless database
      result = database.put_attachment(self, name, file, options)
      self['_rev'] = result['rev']
      result['ok']
    end
    
    # returns an attachment's data
    def fetch_attachment(name)
      raise ArgumentError, "doc must be saved" unless self.rev
      raise ArgumentError, "doc.database required to put_attachment" unless database
      database.fetch_attachment(self, name)
    end
    
    # deletes an attachment directly from couchdb
    def delete_attachment(name)
      raise ArgumentError, "doc.database required to delete_attachment" unless database
      result = database.delete_attachment(self, name)
      self['_rev'] = result['rev']
      result['ok']
    end
  end
  
end
