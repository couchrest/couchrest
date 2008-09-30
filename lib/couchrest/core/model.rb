module CouchRest
  module Model
    class << self
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
      
      def database
        self.class.database
      end
      
      def id
        doc['_id']
      end
      
      def rev
        doc['_rev']
      end
      
      def new_record?
        !doc['_rev']
      end
      
      def save
        if new_record?
          create
        else
          update
        end
      end

      protected
      
      def create
        set_uniq_id if respond_to?(:set_uniq_id) # hack
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
      def use_database db
        @database = db
      end
      
      def database
        @database || CouchRest::Model.default_database
      end
      
      def get id
        doc = database.get id
        new(doc)
      end
      
      def key_accessor *keys
        key_writer *keys
        key_reader *keys
      end
      
      def key_writer *keys
        keys.each do |method|
          key = method.to_s
          define_method "#{method}=" do |value|
            doc[key] = value
          end
        end
      end
      
      def key_reader *keys
        keys.each do |method|
          key = method.to_s
          define_method method do
            doc[key]
          end
        end
      end
      
      def timestamps!
        before(:create) do
          doc['updated_at'] = doc['created_at'] = Time.now
        end                  
        before(:update) do   
          doc['updated_at'] = Time.now
        end
      end
      
      def uniq_id method
        define_method :set_uniq_id do
          doc['_id'] ||= self.send(method)
        end
      end
      
    end # module ClassMethods

    module MagicViews
      def view_by *keys
        type = self.to_s
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

        method_name = "by_#{keys.join('_and_')}"
        
        @@design_doc ||= default_design_doc
        @@design_doc['views'][method_name] = {
          'map' => map_function
        }

        @@design_doc_fresh = false
        
        self.meta_class.instance_eval do
          define_method method_name do |args|
            args ||= {}
            unless @@design_doc_fresh
              refresh_design_doc
            end
            raw = args.delete(:raw)
            view_name = "#{type}/#{method_name}"

            if raw
              fetch_view(view_name)
            else
              view = fetch_view(view_name)
              # TODO this can be optimized once the include-docs patch is applied
              view['rows'].collect{|r|new(database.get(r['id']))}
            end
          end
        end
      end
      
      private
      
      def fetch_view view_name
        retryable = true
        begin
          database.view(view_name)
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