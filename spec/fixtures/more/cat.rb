class Cat < CouchRest::ExtendedDocument
  include ::CouchRest::Validation

  # Set the default database to use
  use_database DB

  property :name, :accessible => true
  property :toys, :cast_as => ['CatToy'], :default => [], :accessible => true
  property :favorite_toy, :cast_as => 'CatToy', :accessible => true
  property :number
end

class CatToy < Hash
  include ::CouchRest::CastedModel
  include ::CouchRest::Validation

  property :name

  validates_presence_of :name
end