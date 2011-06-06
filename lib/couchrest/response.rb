module CouchRest
  #
  # The most basic CouchRest object that acts as a wrapper around
  # a Hash of @_attributes.
  #
  # The idea is to provide the basic functionality of a Hash, just
  # enought to support the needs of CouchRest, but not inherit all
  # of the functionality found in a basic Hash.
  #
  class Response
    def initialize(pkeys = {})
      @_attributes = {}
      pkeys ||= {}
      pkeys.each do |k,v|
        self[k.to_s] = v
      end
    end
    def []=(key, value)
      @_attributes[key.to_s] = value
    end
    def [](key)
      @_attributes[key.to_s]
    end
    def keys
      @_attributes.keys
    end
    def as_json(*args)
      @_attributes.as_json(*args)
    end
    def to_json(*args)
      @_attributes.to_json(*args)
    end
  end
end
