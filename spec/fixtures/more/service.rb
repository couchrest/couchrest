class Service < CouchRest::ExtendedDocument  
  # Include the validation module to get access to the validation methods
  include CouchRest::Validation
  auto_validate!
  # Set the default database to use
  use_database TEST_SERVER.default_database
  
  # Official Schema
  property :name, :length => 4...20
  property :price, :type => Integer
  
end