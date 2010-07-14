module RestAPI

  def default_headers
    {
      :content_type => :json,
      :accept       => :json
    }
  end

  def put(uri, doc = nil)
    payload = doc.to_json if doc
    begin
      JSON.parse(HttpAbstraction.put(uri, payload, default_headers))
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
      JSON.parse(HttpAbstraction.get(uri, default_headers), :max_nesting => false)
    rescue => e
      if $DEBUG
        raise "Error while sending a GET request #{uri}\n: #{e}"
      else
        raise e
      end
    end
  end

  def post(uri, doc = nil)
    payload = doc.to_json if doc
    begin
      JSON.parse(HttpAbstraction.post(uri, payload, default_headers))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a POST request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def delete(uri)
    JSON.parse(HttpAbstraction.delete(uri, default_headers))
  end

  def copy(uri, destination) 
    JSON.parse(HttpAbstraction.copy(uri, default_headers.merge('Destination' => destination)))
  end 

end
