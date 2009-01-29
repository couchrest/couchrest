module CouchRest
  module Mixins
    module Views
    
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
    
      def copy(dest)
        raise ArgumentError, "doc.database required to copy" unless database
        result = database.copy_doc(self, dest)
        result['ok']
      end
    
      def move(dest)
        raise ArgumentError, "doc.database required to copy" unless database
        result = database.move_doc(self, dest)
        result['ok']
      end
    
    end
  end
end