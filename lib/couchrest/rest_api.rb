module CouchRest

  # CouchRest RestAPI
  #
  # The basic low-level interface for all REST requests to the database. Everything must pass
  # through here before it is sent to the server.
  #
  # Six types of REST requests are supported: get, put, post, delete, copy and head.
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

    # Send a HEAD request.
    def head(uri, options = {})
      execute(uri, :head, options)
    end

    protected

    def execute(uri, method, options, doc = nil)
      connection = CouchRest::Connection.new(uri)
      
      connection.close
    end

  end
end
