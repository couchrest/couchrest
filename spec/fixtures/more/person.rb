class Person < Hash
  include ::CouchRest::CastedModel
  property :name, :type => ['String']
  
  def last_name
    name.last
  end
end