
#
# CouchRest::Document
#
# Provides basic functions for controlling documents returned from
# the CouchDB database and provides methods to act as a wrapper around
# a Hash of @_attributes.
#
# The idea is to provide the basic functionality of a Hash, just
# enought to support the needs of CouchRest, but not inherit all
# of the functionality found in a basic Hash.
#
# A Response is similar to Rails' HashWithIndifferentAccess as all
# requests will convert the keys into Symbols and be stored in the
# master hash as such.
#

module CouchRest
  class Document
    include CouchRest::Attributes
    include CouchRest::Attachments
    extend CouchRest::InheritableAttributes

    couchrest_inheritable_accessor :database
    attr_accessor :database

    def id
      self['_id']
    end
    def id=(id)
      self['_id'] = id
    end
    def rev
      self['_rev']
    end

    # returns true if the document has never been saved
    def new?
      !rev
    end
    alias :new_document? :new?

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

    # Returns the CouchDB uri for the document
    def uri(append_rev = false)
      return nil if new?
      couch_uri = "#{database.root}/#{CGI.escape(id)}"
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

    class << self
      # override the CouchRest::Model-wide default_database
      # This is not a thread safe operation, do not change the model
      # database at runtime.
      def use_database(db)
        self.database = db
      end
    end

  end

end
