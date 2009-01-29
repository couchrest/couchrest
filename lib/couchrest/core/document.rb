module CouchRest
  class Response < Hash
    def initialize keys = {}
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

    attr_accessor :database

    # alias for self['_id']
    def id
      self['_id']
    end

    # alias for self['_rev']      
    def rev
      self['_rev']
    end

    # returns true if the document has never been saved
    def new_document?
      !rev
    end

    # Saves the document to the db using create or update. Also runs the :save
    # callbacks. Sets the <tt>_id</tt> and <tt>_rev</tt> fields based on
    # CouchDB's response.
    # If <tt>bulk</tt> is <tt>true</tt> (defaults to false) the document is cached for bulk save.
    def save(bulk = false)
      raise ArgumentError, "doc.database required for saving" unless database
      result = database.save_doc self, bulk
      result['ok']
    end

    # Deletes the document from the database. Runs the :delete callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    # If <tt>bulk</tt> is <tt>true</tt> (defaults to false) the document won't 
    # actually be deleted from the db until bulk save.
    def destroy(bulk = false)
      raise ArgumentError, "doc.database required to destroy" unless database
      result = database.delete_doc(self, bulk)
      if result['ok']
        self['_rev'] = nil
        self['_id'] = nil
      end
      result['ok']
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
    
    # saves an attachment directly to couchdb
    def put_attachment(name, file, options={})
      raise ArgumentError, "doc.database required to put_attachment" unless database
      result = database.put_attachment(self, name, file, options)
      self['_rev'] = result['rev']
      result['ok']
    end
    
    # returns an attachment's data
    def fetch_attachment(name)
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
