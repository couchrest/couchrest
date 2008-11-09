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
    def new_record?
      !rev
    end

    # Saves the document to the db using create or update. Also runs the :save
    # callbacks. Sets the <tt>_id</tt> and <tt>_rev</tt> fields based on
    # CouchDB's response.
    def save
      raise ArgumentError, "doc.database required for saving" unless database
      if new_record?
        create
      else
        update
      end
    end

    # Deletes the document from the database. Runs the :delete callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    def destroy
      result = database.delete self
      if result['ok']
        self['_rev'] = nil
        self['_id'] = nil
      end
      result['ok']
    end

    protected

    # Saves a document for the first time, after running the before(:create)
    # callbacks, and applying the unique_id.
    def create
      set_unique_id if respond_to?(:set_unique_id) # hack
      save_doc
    end
    
    # Saves the document and runs the :update callbacks.
    def update
      save_doc
    end

    private

    def save_doc
      result = database.save self
      result['ok']
    end

  end

  
end