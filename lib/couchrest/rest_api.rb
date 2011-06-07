module CouchRest

  module RestAPI

    def default_headers
      {
        :content_type => :json,
        :accept       => :json
      }
    end

    def get(uri, options = {})
      begin
        parse_response(RestClient.get(uri, default_headers), options.dup)
      rescue => e
        if $DEBUG
          raise "Error while sending a GET request #{uri}\n: #{e}"
        else
          raise e
        end
      end
    end

    def put(uri, doc = nil, options = {})
      opts = options.dup
      payload = payload_from_doc(doc, opts)
      begin
        parse_response(RestClient.put(uri, payload, default_headers.merge(opts)), opts)
      rescue Exception => e
        if $DEBUG
          raise "Error while sending a PUT request #{uri}\npayload: #{payload.inspect}\n#{e}"
        else
          raise e
        end
      end
    end

    def post(uri, doc = nil, options = {})
      opts = options.dup
      payload = payload_from_doc(doc, opts)
      begin
        parse_response(RestClient.post(uri, payload, default_headers.merge(opts)), opts)
      rescue Exception => e
        if $DEBUG
          raise "Error while sending a POST request #{uri}\npayload: #{payload.inspect}\n#{e}"
        else
          raise e
        end
      end
    end

    def delete(uri, options = {})
      parse_response(RestClient.delete(uri, default_headers), options.dup)
    end

    def copy(uri, destination, options = {})
      parse_response(RestClient::Request.execute( :method => :copy,
                                              :url => uri,
                                              :headers => default_headers.merge('Destination' => destination)
                                            ).to_s, options)
    end

    protected

    # Check if the provided doc is nil or special IO device or temp file. If not, 
    # encode it into a string.
    def payload_from_doc(doc, opts = {})
      (opts.delete(:raw) || doc.nil? || doc.is_a?(IO) || doc.is_a?(Tempfile)) ? doc : MultiJson.encode(doc)
    end

    # Parse the response provided.
    def parse_response(result, opts = {})
      opts.delete(:raw) ? result : MultiJson.decode(result, opts.update(:max_nesting => false))
    end

  end
end
