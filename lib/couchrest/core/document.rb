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

  end
  
end
