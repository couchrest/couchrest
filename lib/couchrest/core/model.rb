module CouchRest
  # CouchRest::Model provides an ORM-like interface for CouchDB documents. It avoids all usage of <tt>method_missing</tt>, and tries to strike a balance between usability and magic. See CouchRest::Model::MagicViews#view_by for documentation about the view-generation system. For the other class methods, inspiried by DataMapper and ActiveRecord, see CouchRest::Model::ClassMethods. The InstanceMethods are pretty basic.
  # 
  # ==== Example
  # 
  # This is an example class using CouchRest::Model. It is taken from the spec/couchrest/core/model_spec.rb file, which may be even more up to date than this example.
  # 
  #   class Article
  #     include CouchRest::Model
  #     use_database CouchRest.database!('http://localhost:5984/couchrest-model-test')
  #     unique_id :slug
  #
  #     view_by :date, :descending => true
  #     view_by :user_id, :date
  #
  #     view_by :tags,
  #       :map => 
  #         "function(doc) {
  #           if (doc.type == 'Article' && doc.tags) {
  #             doc.tags.forEach(function(tag){
  #               emit(tag, 1);
  #             });
  #           }
  #         }",
  #       :reduce => 
  #         "function(keys, values, rereduce) {
  #           return sum(values);
  #         }"  
  #
  #     key_writer :date
  #     key_reader :slug, :created_at, :updated_at
  #     key_accessor :title, :tags
  #
  #     timestamps!
  #
  #     before(:create, :generate_slug_from_title)  
  #     def generate_slug_from_title
  #       doc['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'')
  #     end
  #   end
  module Model
    class << self
      # this is the CouchRest::Database that model classes will use unless they override it with <tt>use_database</tt>
      attr_accessor :default_database
    end
    
    # instance methods on the model classes
    module InstanceMethods
      attr_accessor :doc
      
      def initialize keys = {}
        self.doc = {}
        keys.each do |k,v|
          doc[k.to_s] = v
        end
        unless doc['_id'] && doc['_rev']
          init_doc
        end
      end
      
      # returns the database used by this model's class
      def database
        self.class.database
      end
      
      # alias for doc['_id']
      def id
        doc['_id']
      end

      # alias for doc['_rev']      
      def rev
        doc['_rev']
      end
      
      # returns true if the doc has never been saved
      def new_record?
        !doc['_rev']
      end
      
      # save the doc to the db using create or update
      def save
        if new_record?
          create
        else
          update
        end
      end

      protected
      
      def create
        set_unique_id if respond_to?(:set_unique_id) # hack
        save_doc
      end
      
      def update
        save_doc
      end
      
      private
      
      def save_doc
        result = database.save doc
        if result['ok']
          doc['_id'] = result['id']
          doc['_rev'] = result['rev']
        end
        result['ok']
      end
      
      def init_doc
        doc['type'] = self.class.to_s
      end
    end # module InstanceMethods
    
    # these show up as class methods on models that include CouchRest::Model
    module ClassMethods
      # override the CouchRest::Model-wide default_database
      def use_database db
        @database = db
      end
      
      # returns the CouchRest::Database instance that this class uses
      def database
        @database || CouchRest::Model.default_database
      end
      
      # load a document from the database
      def get id
        doc = database.get id
        new(doc)
      end
      
      # Defines methods for reading and writing from fields in the document. Uses key_writer and key_reader internally.
      def key_accessor *keys
        key_writer *keys
        key_reader *keys
      end
      
      # For each argument key, define a method <tt>key=</tt> that sets the corresponding field on the CouchDB document.
      def key_writer *keys
        keys.each do |method|
          key = method.to_s
          define_method "#{method}=" do |value|
            doc[key] = value
          end
        end
      end

      # For each argument key, define a method <tt>key</tt> that reads the corresponding field on the CouchDB document.      
      def key_reader *keys
        keys.each do |method|
          key = method.to_s
          define_method method do
            doc[key]
          end
        end
      end
      
      # Automatically set <tt>updated_at</tt> and <tt>created_at</tt> fields on the document whenever saving occurs. CouchRest uses a pretty decent time format by default. See Time#to_json
      def timestamps!
        before(:create) do
          doc['updated_at'] = doc['created_at'] = Time.now
        end                  
        before(:update) do   
          doc['updated_at'] = Time.now
        end
      end
      
      # Name a method that will be called before the document is first saved, which returns a string to be used for the document's <tt>_id</tt>. Because CouchDB enforces a constraint that each id must be unique, this can be used to enforce eg: uniq usernames. Note that this id must be globally unique across all document types which share a database, so if you'd like to scope uniqueness to this class, you should use the class name as part of the unique id.
      def unique_id method
        define_method :set_unique_id do
          doc['_id'] ||= self.send(method)
        end
      end
      
    end # module ClassMethods

    module MagicViews
      
      # Define a CouchDB view. The name of the view will be the concatenation of <tt>by</tt> and the keys joined by <tt>_and_</tt>
      # 
      # ==== Example views:
      # 
      #   class Post
      #     # view with default options
      #     # query with Post.by_date
      #     view_by :date, :descending => true
      # 
      #     # view with compound sort-keys
      #     # query with Post.by_user_id_and_date
      #     view_by :user_id, :date
      # 
      #     # view with custom map/reduce functions
      #     # query with Post.by_tags :reduce => true
      #     view_by :tags,                                                
      #       :map =>                                                     
      #         "function(doc) {                                          
      #           if (doc.type == 'Post' && doc.tags) {                   
      #             doc.tags.forEach(function(tag){                       
      #               emit(doc.tag, 1);                                   
      #             });                                                   
      #           }                                                       
      #         }",                                                       
      #       :reduce =>                                                  
      #         "function(keys, values, rereduce) {                       
      #           return sum(values);                                     
      #         }"                                                        
      #   end
      # 
      # <tt>view_by :date</tt> will create a view defined by this Javascript function:
      # 
      #   function(doc) {
      #     if (doc.type == 'Post' && doc.date) {
      #       emit(doc.date, null);
      #     }
      #   }
      # 
      # It can be queried by calling <tt>Post.by_date</tt> which accepts all valid options for CouchRest::Database#view. In addition, calling with the <tt>:raw => true</tt> option will return the view rows themselves. By default <tt>Post.by_date</tt> will return the documents included in the generated view.
      # 
      # CouchRest::Database#view options can be applied at view definition time as defaults, and they will be curried and used at view query time. Or they can be overridden at query time.
      # 
      # Custom views can be queried with <tt>:reduce => true</tt> to return reduce results. The default for custom views is to query with <tt>:reduce => false</tt>.
      # 
      # To understand the capabilities of this view system more compeletly, it is recommended that you read the RSpec file at <tt>spec/core/model.rb</tt>.
      def view_by *keys
        opts = keys.pop if keys.last.is_a?(Hash)
        opts ||= {}
        type = self.to_s

        method_name = "by_#{keys.join('_and_')}"
        @@design_doc ||= default_design_doc
        
        if opts[:map]
          view = {}
          view['map'] = opts.delete(:map)
          if opts[:reduce]
            view['reduce'] = opts.delete(:reduce)
            opts[:reduce] = false
          end
          @@design_doc['views'][method_name] = view
        else
          doc_keys = keys.collect{|k|"doc['#{k}']"}
          key_protection = doc_keys.join(' && ')
          key_emit = doc_keys.length == 1 ? "#{doc_keys.first}" : "[#{doc_keys.join(', ')}]"
          map_function = <<-JAVASCRIPT
          function(doc) {
            if (doc.type == '#{type}' && #{key_protection}) {
              emit(#{key_emit}, null);
            }
          }
          JAVASCRIPT
          @@design_doc['views'][method_name] = {
            'map' => map_function
          }
        end
        
        @@design_doc_fresh = false
        
        self.meta_class.instance_eval do
          define_method method_name do |*args|
            query = opts.merge(args[0] || {})
            query[:raw] = true if query[:reduce]
            unless @@design_doc_fresh
              refresh_design_doc
            end
            raw = query.delete(:raw)
            view_name = "#{type}/#{method_name}"

            view = fetch_view(view_name, query)
            if raw
              view
            else
              # TODO this can be optimized once the include-docs patch is applied
              view['rows'].collect{|r|new(database.get(r['id']))}
            end
          end
        end
      end
      
      private
      
      def fetch_view view_name, opts
        retryable = true
        begin
          database.view(view_name, opts)
        # the design doc could have been deleted by a rouge process
        rescue RestClient::ResourceNotFound => e
          if retryable
            refresh_design_doc
            retryable = false
            retry
          else
            raise e
          end
        end
      end
      
      def design_doc_id
        "_design/#{self.to_s}"
      end
      
      def default_design_doc
        {
          "_id" => design_doc_id,
          "language" => "javascript",
          "views" => {}
        }
      end
      
      def refresh_design_doc
        saved = database.get(design_doc_id) rescue nil
        if saved
          @@design_doc['views'].each do |name, view|
            saved['views'][name] = view
          end
          database.save(saved)
        else
          database.save(@@design_doc)
        end
        @@design_doc_fresh = true
      end
      
    end # module MagicViews
    
    module Callbacks
      def self.included(model)
        model.class_eval <<-EOS, __FILE__, __LINE__
          include Extlib::Hook
          register_instance_hooks :save, :create, :update #, :destroy
        EOS
      end
    end # module Callbacks
    
    # bookkeeping section
    
    # load the code into the model class
    def self.included(model)
      model.send(:include, InstanceMethods)
      model.extend ClassMethods
      model.extend MagicViews
      model.send(:include, Callbacks)
    end
    
  end # module Model
end # module CouchRest