class Card < CouchRest::ExtendedDocument  
  # Include the validation module to get access to the validation methods
  include CouchRest::Validation
  # set the auto_validation before defining the properties
  auto_validate!
  
  # Set the default database to use
  use_database DB
  
  # Official Schema
  property :first_name
  property :last_name,        :alias     => :family_name
  property :read_only_value,  :read_only => true
  property :cast_alias,       :cast_as   =>  'Person',  :alias  => :calias

  
  timestamps!
  
  # Validation
  validates_presence_of :first_name
  
end