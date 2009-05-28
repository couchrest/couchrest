class Invoice < CouchRest::ExtendedDocument  
  # Include the validation module to get access to the validation methods
  include CouchRest::Validation
  
  # Set the default database to use
  use_database DB
  
  # Official Schema
  property :client_name
  property :employee_name
  property :location
  
  # Validation
  validates_present :client_name, :employee_name
  validates_present :location, :message => "Hey stupid!, you forgot the location"
  
end