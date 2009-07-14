require 'couchrest/core/adapters/restclient'

# Abstraction layet for HTTP communications.
#                                           
# By defining a basic API that CouchRest is relying on,
# it allows for easy experimentations and implementations of various libraries.
# 
# Most of the API is based on the RestClient API that was used in the early version of CouchRest.
#
module HttpAbstraction
  
  # here is the list of exception expected by CouchRest
  # please convert the underlying errors in this set of known
  # exceptions.
  class ResourceNotFound < StandardError; end
  class RequestFailed < StandardError; end
  class RequestTimeout < StandardError; end
  class ServerBrokeConnection < StandardError; end
  class Conflict < StandardError; end
  
  
  # # Here is the API you need to implement if you want to write a new adapter
  # # See adapters/restclient.rb for more information.
  #
  # def self.proxy=(url)
  # end
  #      
  # def self.proxy
  # end
  #
  # def self.get(uri, headers=nil)
  # end
  # 
  # def self.post(uri, payload, headers=nil)
  # end
  # 
  # def self.put(uri, payload, headers=nil)
  # end
  # 
  # def self.delete(uri, headers=nil)
  # end
  # 
  # def self.copy(uri, headers)
  # end    
 
end

HttpAbstraction.extend(RestClientAdapter::API)