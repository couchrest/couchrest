require File.join(FIXTURE_PATH, 'more', 'question')
require File.join(FIXTURE_PATH, 'more', 'person')

class Course < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  
  property :title, :cast_as => 'String'
  property :questions, :cast_as => ['Question']
  property :professor, :cast_as => 'Person'
  property :participants, :type => ['Object']
  property :ends_at, :type => 'Time'
  property :estimate, :type => 'Float'
  property :hours, :type => 'Integer'
  property :profit, :type => 'BigDecimal'
  property :started_on, :type => 'Date'
  property :updated_at, :type => 'DateTime'
  property :active, :type => 'Boolean'
  property :klass, :type => 'Class'
  
  view_by :title
  view_by :dept, :ducktype => true
end
