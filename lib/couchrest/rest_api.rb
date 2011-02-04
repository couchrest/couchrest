module RestAPI

  def default_headers
    {
      :content_type => :json,
      :accept       => :json
    }
  end

  def put(uri, doc = nil)
    payload = MultiJson.encode(doc) if doc
    begin
      MultiJson.decode(RestClient.put(uri, payload, default_headers))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a PUT request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def get(uri)
    begin
      MultiJson.decode(RestClient.get(uri, default_headers), :max_nesting => false)
    rescue => e
      if $DEBUG
        raise "Error while sending a GET request #{uri}\n: #{e}"
      else
        raise e
      end
    end
  end

  def post(uri, doc = nil)
    payload = MultiJson.encode(doc) if doc
    begin
      MultiJson.decode(RestClient.post(uri, payload, default_headers))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a POST request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def delete(uri)
    MultiJson.decode(RestClient.delete(uri, default_headers))
  end

  def copy(uri, destination)
    MultiJson.decode(RestClient::Request.execute( :method => :copy,
                                            :url => uri,
                                            :headers => default_headers.merge('Destination' => destination)
                                          ).to_s)
  end

end
