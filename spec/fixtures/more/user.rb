class User < CouchRest::ExtendedDocument
  # Set the default database to use
  use_database DB
  property :name, :accessible => true
  property :admin                     # this will be automatically protected
end

class SpecialUser < CouchRest::ExtendedDocument
  # Set the default database to use
  use_database DB
  property :name                      # this will not be protected
  property :admin, :protected => true
end

# There are two modes of protection
#  1) Declare accessible poperties, assume all the rest are protected 
#    property :name, :accessible => true
#    property :admin                     # this will be automatically protected
#
#  2) Declare protected properties, assume all the rest are accessible
#    property :name                      # this will not be protected
#    property :admin, :protected => true
