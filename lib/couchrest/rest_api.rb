module RestAPI

  def default_headers
    {
      :content_type => :json,
      :accept       => :json
    }
  end

  def put(uri, doc = nil, options = {})
    payload = doc.to_json if doc
    begin
      JSON.parse(RestClient::Request.execute({:method => :put, :url => uri, :payload => payload, :headers => default_headers}.merge(options)))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a PUT request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def get(uri, options = {})
    begin
      JSON.parse(RestClient::Request.execute({:method => :get, :url => uri, :headers => default_headers}.merge(options)), :max_nesting => false)
    rescue => e
      if $DEBUG
        raise "Error while sending a GET request #{uri}\n: #{e}"
      else
        raise e
      end
    end
  end

  def post(uri, doc = nil, options = {})
    payload = doc.to_json if doc
    begin
      JSON.parse(RestClient::Request.execute({:method => :post, :url => uri, :payload => payload, :headers => default_headers}.merge(options)))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a POST request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def delete(uri, options = {})
    JSON.parse(RestClient::Request.execute({:method => :delete, :url => uri, :headers => default_headers}.merge(options)))
  end

  def copy(uri, destination, options = {})
    JSON.parse(RestClient::Request.execute({:method => :copy,
                                            :url => uri,
                                            :headers => default_headers.merge('Destination' => destination)}.merge(options)
                                          ).to_s)
  end 

end
