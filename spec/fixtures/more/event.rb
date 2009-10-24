class Event < CouchRest::ExtendedDocument
  use_database DB
  
  property :subject
  property :occurs_at, :cast_as => 'Time', :init_method => 'parse'
  property :end_date,  :cast_as => 'Date', :init_method => 'parse'
  
  
end