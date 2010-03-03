require 'mime/types'
require File.join(File.dirname(__FILE__), "property")
require File.join(File.dirname(__FILE__), '..', 'mixins', 'extended_document_mixins')
require "enumerator"

module CouchRest
  
  # Same as CouchRest::Document but with properties and validations
  class ExtendedDocument < Document
    include CouchRest::Callbacks
    include CouchRest::Mixins::DocumentQueries    
    include CouchRest::Mixins::Views
    include CouchRest::Mixins::DesignDoc
    include CouchRest::Mixins::ExtendedAttachments
    include CouchRest::Mixins::ClassProxy
    include CouchRest::Mixins::Collection
		include CouchRest::Mixins::AttributeProtection

    def self.subclasses
      @subclasses ||= []
    end
    
    def self.inherited(subklass)
      super
      subklass.send(:include, CouchRest::Mixins::Properties)
      subklass.class_eval <<-EOS, __FILE__, __LINE__ + 1
        def self.inherited(subklass)
          super
          subklass.properties = self.properties.dup
        end
      EOS
      subclasses << subklass
    end
    
    # Accessors
    attr_accessor :casted_by
    
    # Callbacks
    define_callbacks :create, "result == :halt"
    define_callbacks :save, "result == :halt"
    define_callbacks :update, "result == :halt"
    define_callbacks :destroy, "result == :halt"

    # Creates a new instance, bypassing attribute protection
    #
    # ==== Returns
    #  a document instance
    def self.create_from_database(passed_keys={})
      new(passed_keys, :directly_set_attributes => true)      
    end
    
    def initialize(passed_keys={}, options={})
      apply_defaults # defined in CouchRest::Mixins::Properties
      remove_protected_attributes(passed_keys) unless options[:directly_set_attributes]
      directly_set_attributes(passed_keys) unless passed_keys.nil?
      super(passed_keys)
      cast_keys      # defined in CouchRest::Mixins::Properties
      unless self['_id'] && self['_rev']
        self['couchrest-type'] = self.class.to_s
      end
    end
    
    # Defines an instance and save it directly to the database 
    # 
    # ==== Returns
    #  returns the reloaded document
    def self.create(options)
      instance = new(options)
      instance.create
      instance
    end
    
    # Defines an instance and save it directly to the database 
    # 
    # ==== Returns
    #  returns the reloaded document or raises an exception
    def self.create!(options)
      instance = new(options)
      instance.create!
      instance
    end
    
    # Automatically set <tt>updated_at</tt> and <tt>created_at</tt> fields
    # on the document whenever saving occurs. CouchRest uses a pretty
    # decent time format by default. See Time#to_json
    def self.timestamps!
      class_eval <<-EOS, __FILE__, __LINE__ + 1
        property(:updated_at, :read_only => true, :cast_as => 'Time', :auto_validation => false)
        property(:created_at, :read_only => true, :cast_as => 'Time', :auto_validation => false)
        
        set_callback :save, :before do |object|
          object['updated_at'] = Time.now
          object['created_at'] = object['updated_at'] if object.new?
        end
      EOS
    end
    
    # Name a method that will be called before the document is first saved,
    # which returns a string to be used for the document's <tt>_id</tt>.
    # Because CouchDB enforces a constraint that each id must be unique,
    # this can be used to enforce eg: uniq usernames. Note that this id
    # must be globally unique across all document types which share a
    # database, so if you'd like to scope uniqueness to this class, you
    # should use the class name as part of the unique id.
    def self.unique_id method = nil, &block
      if method
        define_method :set_unique_id do
          self['_id'] ||= self.send(method)
        end
      elsif block
        define_method :set_unique_id do
          uniqid = block.call(self)
          raise ArgumentError, "unique_id block must not return nil" if uniqid.nil?
          self['_id'] ||= uniqid
        end
      end
    end
    
    # Temp solution to make the view_by methods available
    def self.method_missing(m, *args, &block)
      if has_view?(m)
        query = args.shift || {}
        view(m, query, *args, &block)
      else
        super
      end
    end
    
    ### instance methods
    
    # Returns the Class properties
    #
    # ==== Returns
    # Array:: the list of properties for the instance
    def properties
      self.class.properties
    end
    
    # Gets a reference to the actual document in the DB
    # Calls up to the next document if there is one,
    # Otherwise we're at the top and we return self
    def base_doc
      return self if base_doc?
      @casted_by.base_doc
    end
    
    # Checks if we're the top document
    def base_doc?
      !@casted_by
    end
    
    # Takes a hash as argument, and applies the values by using writer methods
    # for each key. It doesn't save the document at the end. Raises a NoMethodError if the corresponding methods are
    # missing. In case of error, no attributes are changed.    
    def update_attributes_without_saving(hash)
      # remove attributes that cannot be updated, silently ignoring them
      # which matches Rails behavior when, for instance, setting created_at.
      # make a copy, we don't want to change arguments
      attrs = hash.dup
      %w[_id _rev created_at updated_at].each {|attr| attrs.delete(attr)}
      check_properties_exist(attrs)
			set_attributes(attrs)
    end
    alias :attributes= :update_attributes_without_saving

    # Takes a hash as argument, and applies the values by using writer methods
    # for each key. Raises a NoMethodError if the corresponding methods are
    # missing. In case of error, no attributes are changed.
    def update_attributes(hash)
      update_attributes_without_saving hash
      save
    end

    # for compatibility with old-school frameworks
    alias :new_record? :new?
    alias :new_document? :new?
    
    # Trigger the callbacks (before, after, around)
    # and create the document
    # It's important to have a create callback since you can't check if a document
    # was new after you saved it
    #
    # When creating a document, both the create and the save callbacks will be triggered.
    def create(bulk = false)
      caught = catch(:halt)  do
        _run_create_callbacks do
            _run_save_callbacks do
              create_without_callbacks(bulk)
          end
        end
      end
    end
    
    # unlike save, create returns the newly created document
    def create_without_callbacks(bulk =false)
      raise ArgumentError, "a document requires a database to be created to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      (result["ok"] == true) ? self : false
    end
    
    # Creates the document in the db. Raises an exception
    # if the document is not created properly.
    def create!
      raise "#{self.inspect} failed to save" unless self.create
    end
    
    # Trigger the callbacks (before, after, around)
    # only if the document isn't new
    def update(bulk = false)
      caught = catch(:halt)  do
        if self.new?
          save(bulk)
        else
          _run_update_callbacks do
            _run_save_callbacks do
              save_without_callbacks(bulk)
            end
          end
        end
      end
    end
    
    # Trigger the callbacks (before, after, around)
    # and save the document
    def save(bulk = false)
      caught = catch(:halt)  do
        if self.new?
          _run_save_callbacks do
            save_without_callbacks(bulk)
          end
        else
          update(bulk)
        end
      end
    end
    
    # Overridden to set the unique ID.
    # Returns a boolean value
    def save_without_callbacks(bulk = false)
      raise ArgumentError, "a document requires a database to be saved to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      mark_as_saved 
      result["ok"] == true
    end
    
    # Saves the document to the db using save. Raises an exception
    # if the document is not saved properly.
    def save!
      raise "#{self.inspect} failed to save" unless self.save
      true
    end

    # Deletes the document from the database. Runs the :destroy callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    def destroy(bulk=false)
      caught = catch(:halt)  do
        _run_destroy_callbacks do
          result = database.delete_doc(self, bulk)
          if result['ok']
            self.delete('_rev')
            self.delete('_id')
          end
          result['ok']
        end
      end
    end
    
    protected
    
    # Set document_saved flag on all casted models to true
    def mark_as_saved
      self.each do |key, prop|
        if prop.is_a?(Array)
          prop.each do |item|
            if item.respond_to?(:document_saved)
              item.send(:document_saved=, true)
            end
          end
        elsif prop.respond_to?(:document_saved)
          prop.send(:document_saved=, true)
        end
      end
    end

		private

		def check_properties_exist(attrs)
      attrs.each do |attribute_name, attribute_value|
        raise NoMethodError, "#{attribute_name}= method not available, use property :#{attribute_name}" unless self.respond_to?("#{attribute_name}=")
      end      
		end
    
    def directly_set_attributes(hash)
      hash.each do |attribute_name, attribute_value|
        if self.respond_to?("#{attribute_name}=")
          self.send("#{attribute_name}=", hash.delete(attribute_name))
        end
      end
    end
    
		def set_attributes(hash)
			attrs = remove_protected_attributes(hash)
			directly_set_attributes(attrs)
		end
  end
end
