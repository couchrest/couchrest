require 'patron'

module PatronAdapter
  
  def self.included(base)
    base.extend(::PatronAdapter::API)
  end
   
  module API
    
    # Patron API only
    def sessions
      @sessions ||= {}
    end
    
    # Patron API only
    # Since we are only accessing a very little amount of servers
    # we can reuse Patron's sessions
    #
    def reusable_session(host)
      if sessions.has_key?(host) 
        sessions[host]
      else       
        session = Patron::Session.new
        session.timeout             = 10
        session.base_url            = host
        session.headers['User-Agent']  = "CouchRest/#{::CouchRest::VERSION}"
        sessions[host]         = session
      end
    end
    
    # Patron API only
    # Extracts the host and uri for a given request
    #
    # ==== Parameters
    # url<String>:: the full request path
    # ==== Return
    # <Array>:: An array with the request host including the port and then the uri
    #
    def extract_host_and_uri(url)
      # Request examples
      # http://127.0.0.1:5984/_all_dbs
      # http://127.0.0.1:8080/_uuids?count=1000
      # http://127.0.0.1:5984/couchrest-test/bulkdoc
      # http://localhost:5984/couchrest-test/big-bad-danger
      # http://localhost/couchrest-test/_design/WithTemplateAndUniqueID
      url =~ /(http:\/\/.*?)(\/.*)/i
      [$1, $2]
    end
    
    def proxy=(url)
    end 
    
    def proxy
    end
  
    def get(url, headers={})
      host, uri = extract_host_and_uri(url)
      session = reusable_session(host)
      session.headers.merge!(headers)
      response = session.get(uri)
      # TODO handle errors
      response.body
    end
  
    def post(url, payload=nil, headers={})
      host, uri = extract_host_and_uri(url)
      session = reusable_session(host)
      session.headers.merge!(headers)
      response = session.post(uri, (payload || ''))
      # TODO handle errors
      response.body
    end
  
    def put(url, payload=nil, headers={})
      host, uri = extract_host_and_uri(url)
      session = reusable_session(host)
      session.headers.merge!(headers)
      response = session.put(uri, (payload || ''))
      # TODO handle errors
      response.body
    end
  
    def delete(url, headers={})
      host, uri = extract_host_and_uri(url)
      session = reusable_session(host)
      session.headers.merge!(headers)
      response = session.delete(uri)
      # TODO handle errors
      response.body
    end
  
    def copy(uri, headers)
      raise 'NotSupported' unless session.respond_to?(:copy)
      host, uri = extract_host_and_uri(url)
      session = reusable_session(host)
      session.headers.merge!(headers)
      response = session.copy(uri)
      # TODO handle errors
      response.body
    end
  end 
  
end