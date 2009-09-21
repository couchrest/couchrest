class Event < CouchRest::ExtendedDocument
  use_database DB
  
  property :subject
  property :occurs_at, :cast_as => 'Time', :send => 'parse'
  property :end_date,  :cast_as => 'Date', :send => 'parse'
  
  
end