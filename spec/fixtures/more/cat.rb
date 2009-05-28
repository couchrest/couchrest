class Cat < CouchRest::ExtendedDocument
  include ::CouchRest::Validation

  # Set the default database to use
  use_database DB

  property :name
  property :toys, :cast_as => ['CatToy'], :default => []
end

class CatToy < Hash
  include ::CouchRest::CastedModel
  include ::CouchRest::Validation

  property :name

  validates_present :name
end