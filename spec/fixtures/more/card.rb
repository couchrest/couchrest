class Card < CouchRest::ExtendedDocument  
  use_database TEST_SERVER.default_database
  property :first_name
  property :last_name,        :alias     => :family_name
  property :read_only_value,  :read_only => true
  
end