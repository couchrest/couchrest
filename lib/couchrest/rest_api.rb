module CouchRest

  # CouchRest RestAPI
  #
  # The basic low-level interface for all REST requests to the database. Everything must pass
  # through here before it is sent to the server.
  #
  # Five types of REST requests are supported: get, put, post, delete, and copy.
  #
  # Requests that do not have a payload, get, delete and copy, accept the URI and options parameters,
  # where as put and post both expect a document as the second parameter.
  #
  # The API will try to intelegently split the options between the JSON parser and RestClient API.
  #
  # The following options will be recognised as header options and automatically added
  # to the header hash:
  #
  # * :content_type, type of content to be sent, especially useful when sending files as this will set the file type. The default is :json.
  # * :accept, the content type to accept in the response. This should pretty much always be :json.
  #
  # The following request options are supported:
  #
  # * :method override the requested method (should not be used!).
  # * :url override the URL used in the request.
  # * :payload override the document or data sent in the message body (only PUT or POST).
  # * :headers any additional headers (overrides :content_type and :accept)
  # * :timeout and :open_timeout the time in miliseconds to wait for the request, see RestClient API for more details.
  # * :verify_ssl, :ssl_client_cert, :ssl_client_key, and :ssl_ca_file, SSL handling methods.
  #
  #
  # Any other remaining options will be sent to the MultiJSON backend except for the :raw option.
  #
  # When :raw is true in PUT and POST requests, no attempt will be made to convert the document payload to JSON. This is 
  # not normally necessary as IO and Tempfile objects will not be parsed anyway. The result of the request will
  # *always* be parsed.
  #
  # For all other requests, mainly GET, the :raw option will make no attempt to parse the result. This
  # is useful for receiving files from the database.
  #

  module RestAPI

    # Send a GET request.
    def get(uri, options = {})
      execute(uri, :get, options)
    end

    # Send a PUT request.
    def put(uri, doc = nil, options = {})
      execute(uri, :put, options, doc)
    end

    # Send a POST request.
    def post(uri, doc = nil, options = {})
      execute(uri, :post, options, doc)
    end

    # Send a DELETE request.
    def delete(uri, options = {})
      execute(uri, :delete, options)
    end

    # Send a COPY request to the URI provided.
    def copy(uri, destination, options = {})
      opts = options.nil? ? {} : options.dup
      # also copy headers!
      opts[:headers] = options[:headers].nil? ? {} : options[:headers].dup
      opts[:headers]['Destination'] = destination
      execute(uri, :copy, opts)
    end

    # The default RestClient headers used in each request.
    def default_headers
      {
        :content_type => :json,
        :accept       => :json
      }
    end

    private

    # Perform the RestClient request by removing the parse specific options, ensuring the 
    # payload is prepared, and sending the request ready to parse the response.
    def execute(url, method, options = {}, payload = nil)
      request, parser = prepare_and_split_options(url, method, options)
      # Prepare the payload if it is provided
      request[:payload] = payload_from_doc(payload, parser) if payload
      begin
        parse_response(RestClient::Request.execute(request), parser)
      rescue Exception => e
        if $DEBUG
          raise "Error while sending a #{method.to_s.upcase} request #{uri}\noptions: #{opts.inspect}\n#{e}"
        else
          raise e
        end
      end
    end

    # Prepare two hashes, one for the request to the REST backend and a second
    # for the JSON parser.
    #
    # Returns an array of request and parser options.
    #
    def prepare_and_split_options(url, method, options)
      request = {
        :url => url,
        :method => method,
        :headers => default_headers.merge(options[:headers] || {})
      }
      parser = {
        :raw => false
      }
      # Split the options
      (options || {}).each do |k,v|
        k = k.to_sym
        next if k == :headers # already dealt with
        if restclient_option_keys.include?(k)
          request[k] = v
        elsif header_option_keys.include?(k)
          request[:headers][k] = v
        else
          parser[k] = v
        end
      end
      [request, parser]
    end

    # Check if the provided doc is nil or special IO device or temp file. If not, 
    # encode it into a string.
    #
    # The options supported are:
    # * :raw TrueClass, if true the payload will not be altered.
    #
    def payload_from_doc(doc, opts = {})
      if (opts.delete(:raw) || doc.nil? || doc.is_a?(IO) || doc.is_a?(Tempfile))
        doc
      else
        MultiJson.encode(doc.respond_to?(:as_couch_json) ? doc.as_couch_json : doc)
      end
    end

    # Parse the response provided.
    def parse_response(result, opts = {})
      opts.delete(:raw) ? result : MultiJson.decode(result, opts.update(:max_nesting => false))
    end

    # An array of all the options that should be passed through to restclient.
    # Anything not in this list will be passed to the JSON parser.
    def restclient_option_keys
      [:method, :url, :payload, :headers, :timeout, :open_timeout,
        :verify_ssl, :ssl_client_cert, :ssl_client_key, :ssl_ca_file]
    end

    def header_option_keys
      [ :content_type, :accept ]
    end

  end
end
