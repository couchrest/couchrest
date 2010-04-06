require 'digest/md5'

module CouchRest
  module Mixins
    module DesignDoc
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        def design_doc
          @design_doc ||= Design.new(default_design_doc)
        end
    
        # Use when something has been changed, like a view, so that on the next request
        # the design docs will be updated.
        def req_design_doc_refresh
          @design_doc_fresh = { }
        end
        
        def design_doc_id
          "_design/#{design_doc_slug}"
        end

        def design_doc_slug
          self.to_s
        end

        def default_design_doc
          {
            "language" => "javascript",
            "views" => {
              'all' => {
                'map' => "function(doc) {
                  if (doc['couchrest-type'] == '#{self.to_s}') {
                    emit(doc['_id'],1);
                  }
                }"
              }
            }
          }
        end

        def refresh_design_doc(db = database)
          unless design_doc_fresh(db)
            reset_design_doc(db)
            save_design_doc(db)
          end
        end

        # Save the design doc onto a target database in a thread-safe way,
        # not modifying the model's design_doc
        def save_design_doc(db = database)
          update_design_doc(Design.new(design_doc), db)
        end

        protected

        def design_doc_fresh(db, fresh = nil)
          @design_doc_fresh ||= {}
          if fresh.nil? 
            @design_doc_fresh[db.uri] || false
          else
            @design_doc_fresh[db.uri] = fresh
          end
        end

        def reset_design_doc(db)
          current = db.get(design_doc_id) rescue nil
          design_doc['_id']  = design_doc_id
          if current.nil?
            design_doc.delete('_rev')
          else
            design_doc['_rev'] = current['_rev']
          end
          design_doc_fresh(db, true)
        end

        # Writes out a design_doc to a given database, returning the
        # updated design doc
        def update_design_doc(design_doc, db)
          saved = db.get(design_doc['_id']) rescue nil
          if saved
            design_doc['views'].each do |name, view|
              saved['views'][name] = view
            end
            db.save_doc(saved)
            saved
          else
            design_doc.database = db
            design_doc.save
            design_doc
          end
        end
        
      end # module ClassMethods
      
    end
  end
end
