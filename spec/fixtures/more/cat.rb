class Cat < CouchRest::ExtendedDocument
  include ::CouchRest::Validation

  # Set the default database to use
  use_database DB

  property :name
  property :toys, :cast_as => ['CatToy'], :default => []
  property :favorite_toy, :cast_as => 'CatToy'
end

class CatToy < Hash
  include ::CouchRest::CastedModel
  include ::CouchRest::Validation

  property :name

  validates_present :name
end