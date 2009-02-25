class Person < Hash
  include ::CouchRest::CastedModel
  property :name
  
  def last_name
    name.last
  end
end