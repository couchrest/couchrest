class Question < Hash
  include ::CouchRest::CastedModel
  
  property :q
  property :a
end