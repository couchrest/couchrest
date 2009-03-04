require 'digest/md5'

module CouchRest
  module Mixins
    module DesignDoc
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def design_doc_id
          "_design/#{design_doc_slug}"
        end

        def design_doc_slug
          return design_doc_slug_cache if (design_doc_slug_cache && design_doc_fresh)
          funcs = []
          design_doc ||= Design.new(default_design_doc)
          design_doc['views'].each do |name, view|
            funcs << "#{name}/#{view['map']}#{view['reduce']}"
          end
          md5 = Digest::MD5.hexdigest(funcs.sort.join(''))
          self.design_doc_slug_cache = "#{self.to_s}-#{md5}"
        end

        def default_design_doc
          {
            "language" => "javascript",
            "views" => {
              'all' => {
                'map' => "function(doc) {
                  if (doc['couchrest-type'] == '#{self.to_s}') {
                    emit(null,null);
                  }
                }"
              }
            }
          }
        end

        def refresh_design_doc
          did = design_doc_id
          saved = database.get(did) rescue nil
          if saved
            design_doc['views'].each do |name, view|
              saved['views'][name] = view
            end
            database.save_doc(saved)
            self.design_doc = saved
          else
            design_doc['_id'] = did
            design_doc.delete('_rev')
            design_doc.database = database
            design_doc.save
          end
          self.design_doc_fresh = true
        end
        
      end # module ClassMethods
      
    end
  end
end