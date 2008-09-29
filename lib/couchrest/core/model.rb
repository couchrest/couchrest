module CouchRest
  module Model
    class << self
      attr_accessor :default_database
    end
    
    # instance methods on the model classes
    module InstanceMethods
      attr_accessor :doc
      
      def initialize doc = {}
        self.doc = doc
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
      
      def save
        result = database.save doc
        if result['ok']
          doc['_id'] = result['id']
          doc['_rev'] = result['rev']
        end
        result['ok']
      end
      
      private
      
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
      
      def uniq_id method
        before_create do |model|
          model.doc['_id'] = model.send(method)
        end
      end
    end # module ClassMethods
    
    # bookkeeping section
    
    # load the code into the model class
    def self.included(klass)
      klass.extend ClassMethods
      klass.send(:include, InstanceMethods)
    end
    
    
  end # module Model
end # module CouchRest