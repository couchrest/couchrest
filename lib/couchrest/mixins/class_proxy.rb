module CouchRest
  module Mixins
    module ClassProxy
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods

        # Return a proxy object which represents a model class on a
        # chosen database instance. This allows you to DRY operations
        # where a database is chosen dynamically.
        #  
        # ==== Example:
        #  
        #   db = CouchRest::Database.new(...)
        #   articles = Article.on(db)
        #
        #   articles.all { ... }
        #   articles.by_title { ... }
        #
        #   u = articles.get("someid")
        #
        #   u = articles.new(:title => "I like plankton")
        #   u.save    # saved on the correct database

        def on(database)
          Proxy.new(self, database)
        end
      end

      class Proxy #:nodoc:
        def initialize(klass, database)
          @klass = klass
          @database = database
        end
        
        # ExtendedDocument
        
        def new(*args)
          doc = @klass.new(*args)
          doc.database = @database
          doc
        end
        
        def method_missing(m, *args, &block)
          if has_view?(m)
            query = args.shift || {}
            view(m, query, *args, &block)
          else
            super
          end
        end
        
        # Mixins::DocumentQueries
        
        def all(opts = {}, &block)
          docs = @klass.all({:database => @database}.merge(opts), &block)
          docs.each { |doc| doc.database = @database if doc.respond_to?(:database) } if docs
          docs
        end
        
        def count(opts = {}, &block)
          @klass.all({:database => @database, :raw => true, :limit => 0}.merge(opts), &block)['total_rows']
        end
        
        def first(opts = {})
          doc = @klass.first({:database => @database}.merge(opts))
          doc.database = @database if doc && doc.respond_to?(:database)
          doc
        end
        
        def get(id)
          doc = @klass.get(id, @database)
          doc.database = @database if doc && doc.respond_to?(:database)
          doc
        end
        
        # Mixins::Views
        
        def has_view?(view)
          @klass.has_view?(view)
        end
        
        def view(name, query={}, &block)
          docs = @klass.view(name, {:database => @database}.merge(query), &block)
          docs.each { |doc| doc.database = @database if doc.respond_to?(:database) } if docs
          docs
        end
        
        def all_design_doc_versions
          @klass.all_design_doc_versions(@database)
        end
        
        def model_design_doc
          @klass.model_design_doc(@database)
        end
        
        def cleanup_design_docs!
          @klass.cleanup_design_docs!(@database)
        end
        
        # Mixins::DesignDoc
        
        def design_doc
          @klass.design_doc
        end
        
        def design_doc_fresh
          @klass.design_doc_fresh
        end
        
        def refresh_design_doc
          @klass.refresh_design_doc_on(@database)
        end
        
        def save_design_doc
          @klass.save_design_doc_on(@database)
        end
      end
    end
  end
end
