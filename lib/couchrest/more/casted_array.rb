#
# Wrapper around Array so that the casted_by attribute is set in all
# elements of the array.
#

module CouchRest
  class CastedArray < Array
    attr_accessor :casted_by
    
    def << obj
      obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
      super(obj)
    end
    
    def push(obj)
      obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
      super(obj)
    end
    
    def []= index, obj
      obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
      super(index, obj)
    end
  end
end
