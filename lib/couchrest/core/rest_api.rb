module RestAPI

  def put(uri, doc = nil)
    payload = doc.to_json if doc
    begin
      JSON.parse(HttpAbstraction.put(uri, payload))
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
      JSON.parse(HttpAbstraction.get(uri), :max_nesting => false)
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
      JSON.parse(HttpAbstraction.post(uri, payload))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a POST request #{uri}\npayload: #{payload.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def delete(uri)
    JSON.parse(HttpAbstraction.delete(uri))
  end

  def copy(uri, destination) 
    JSON.parse(HttpAbstraction.copy(uri, {'Destination' => destination}))
  end 

end