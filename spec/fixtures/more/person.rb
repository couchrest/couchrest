class Person < Hash
  include ::CouchRest::CastedModel
  property :name
  property :pet, :cast_as => 'Cat'
  
  def last_name
    name.last
  end
end