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
  validates_presence_of :client_name, :employee_name
  validates_presence_of :location, :message => "Hey stupid!, you forgot the location"
  
end