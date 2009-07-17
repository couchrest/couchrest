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
  class MissingAdapter < StandardError; end
  
  # use the Adapter name
  # ==== example:
  # HttpAbstraction.use_adapter('RestClient')
  # HttpAbstraction.use_adapter('Patron')
  def self.use_adapter(name)
    require "couchrest/core/adapters/#{name.downcase}"
    begin
      adapter = self.const_get("#{name}Adapter")
      HttpAbstraction.send(:include, adapter)
      instance_variable_set("@adapter", name)
    rescue
      raise MissingAdapter, "#{name} adapter couldn't be loaded"
    end  
  end
  
  def self.adapter
    instance_variable_get("@adapter")
  end
  
  # # Here is the API you need to implement if you want to write a new adapter
  # # See adapters/restclient.rb for more information.
  #
  # def self.proxy=(url)
  # end
  #      
  # def self.proxy
  # end
  #
  # def self.get(uri, headers={})
  # end
  # 
  # def self.post(uri, payload, headers={})
  # end
  # 
  # def self.put(uri, payload, headers={})
  # end
  # 
  # def self.delete(uri, headers={})
  # end
  # 
  # def self.copy(uri, headers)
  # end
 
end 

# ::HttpAbstraction.use_adapter('RestClient')