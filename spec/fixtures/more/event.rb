class Event < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  
  property :subject
  property :occurs_at, :cast_as => 'Time', :send => 'parse'
end