class Event < CouchRest::ExtendedDocument
  use_database DB
  
  property :subject
  property :occurs_at, :cast_as => 'Time', :send => 'parse'
end