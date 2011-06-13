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
      @_attributes = {}
      attrs.each{|k,v| self[k] = v} unless attrs.nil?
    end

    # Hash equivilent methods to access the attributes
    def_delegators :@_attributes, :to_a, :==, :eql?, :keys, :values, :each,
      :reject, :reject!, :empty?, :clear, :merge, :merge!,
      :encode_json, :as_json, :to_json

    def []=(key, value)
      @_attributes[key.to_s] = value
    end
    def [](key)
      @_attributes[key.to_s]
    end
    def has_key?(key)
      @_attributes.has_key?(key.to_s)
    end
    def delete(key)
      @_attributes.delete(key.to_s)
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
      @_attributes
    end

  end

end
