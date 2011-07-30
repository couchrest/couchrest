#
# CouchRest::Attributes
#
# When included, provide the owner with an attributes hash and
# accessors that forward calls to it.
#
# Provides the basic functionality of Hash without actually being
# a Hash using Ruby's standard Forwardable module.
#
module CouchRest

  module Attributes
    extend Forwardable

    # Initialize a new CouchRest Document and prepare 
    # a hidden attributes hash.
    #
    # When inherting a Document, it is essential that the 
    # super method is called before you own changes to ensure
    # that the attributes hash has been initialized before
    # you attempt to use it.
    def initialize(attrs = nil)
      attrs.each{|k,v| self[k] = v} unless attrs.nil?
    end

    # Hash equivilent methods to access the attributes
    def_delegators :_attributes, :to_a, :==, :eql?, :keys, :values, :each,
      :reject, :reject!, :empty?, :clear, :merge, :merge!,
      :encode_json, :as_json, :to_json, :frozen?

    def []=(key, value)
      _attributes[key.to_s] = value
    end
    def [](key)
      _attributes[key.to_s]
    end
    def has_key?(key)
      _attributes.has_key?(key.to_s)
    end
    def delete(key)
      _attributes.delete(key.to_s)
    end
    def dup
      new = super
      @_attributes = @_attributes.dup
      new
    end
    def clone
      new = super
      @_attributes = @_attributes.dup
      new
    end
    def to_hash
      _attributes
    end

    # Provide JSON data hash that can be stored in the database.
    # Will go through each attribute value and request the `as_couch_json` method
    # on each if available, or return the value as-is.
    def as_couch_json
      _attributes.inject({}) {|h, (k,v)| h[k] = v.respond_to?(:as_couch_json) ? v.as_couch_json : v; h}
    end

    # Freeze the object's attributes instead of the actual document.
    # This prevents further modifications to stored data, but does allow access
    # to local variables useful for callbacks or cached data.
    def freeze
      _attributes.freeze; self
    end

    # Provide details of the current keys in the reponse. Based on ActiveRecord::Base.
    def inspect
      attributes_as_nice_string = self.keys.collect { |key|
        "#{key}: #{self[key].inspect}"
      }.compact.join(", ")
      "#<#{self.class} #{attributes_as_nice_string}>"
    end

    protected

    # Define accessor for _attributes hash that will instantiate the
    # model if this has not already been done.
    def _attributes
      @_attributes ||= {}
    end

  end

end
