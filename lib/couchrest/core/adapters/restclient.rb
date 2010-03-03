module RestClientAdapter
   
  module API
    def proxy=(url)
      RestClient.proxy = url
    end 
    
    def proxy
      RestClient.proxy
    end
  
    def get(uri, headers={})
      RestClient.get(uri, headers).to_s
    end
  
    def post(uri, payload, headers={})
      RestClient.post(uri, payload, headers).to_s
    end
  
    def put(uri, payload, headers={})
      RestClient.put(uri, payload, headers).to_s
    end
  
    def delete(uri, headers={})
      RestClient.delete(uri, headers).to_s
    end
  
    def copy(uri, headers)
      RestClient::Request.execute(  :method   => :copy,
                                    :url      => uri,
                                    :headers  => headers).to_s
    end
  end 
  
end