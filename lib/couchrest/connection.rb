module CouchRest

  # CouchRest Connection
  #
  # Handle connections to the CouchDB server and provide a set of HTTP based methods to
  # perform requests.
  #
  # All connections are persistent and thread safe. A connection cannot be re-used to connect to other servers once instantiated.
  #
  # Six types of REST requests are supported: get, put, post, delete, copy and head.
  #
  # Requests that do not have a payload like GET, DELETE and COPY, accept the URI and options parameters.
  # PUT and POST both expect a document as the second parameter.
  #
  # The API will share the options between the HTTP connection and JSON parser.
  #
  # When initializing a connection, the following options are available:
  #
  #  * `:timeout` (or `:read_timeout`) and `:open_timeout` the time in miliseconds to wait for the request, see the [Net HTTP Persistent documentation](http://docs.seattlerb.org/net-http-persistent/Net/HTTP/Persistent.html#attribute-i-read_timeout) for more details.
  #  * `:verify_ssl` verify ssl certificates (or not)
  #  * `:ssl_client_cert`, `:ssl_client_key` parameters controlling ssl client certificate authentication
  #  * `:ssl_ca_file` load additional CA certificates from a file (or directory)
  #
  # The following request options are supported:
  #
  #  * `:content_type`, type of content to be sent, especially useful when sending files as this will set the file type. The default is :json.
  #  * `:accept`, the content type to accept in the response. This should pretty much always be `:json`.
  #  * `:payload` override the document or data sent in the message body (only PUT or POST).
  #  * `:headers` any additional headers (overrides :content_type and :accept if provided).
  #
  # When :raw is true in PUT and POST requests, no attempt will be made to convert the document payload to JSON. This is
  # not normally necessary as IO and Tempfile objects will not be parsed anyway. The result of the request will
  # *always* be parsed.
  #
  # For all other requests, mainly GET, the :raw option will make no attempt to parse the result. This
  # is useful for receiving files from the database.
  #
  class Connection

    HEADER_CONTENT_SYMBOL_MAP = {
      :content_type => 'Content-Type',
      :accept       => 'Accept'
    }

    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    }

    KNOWN_PARSER_OPTIONS = [
      :max_nesting, :allow_nan, :quirks_mode, :create_additions
    ]

    SUCCESS_RESPONSE_CODES = [200, 201, 202, 204]

    attr_reader :uri, :last_response, :options, :http

    def initialize(uri, options = {})
      raise "CouchRest::Connection.new requires URI::HTTP(S) parameter" unless uri.is_a?(URI::HTTP)
      @uri = clean_uri(uri)
      @options = options.dup
      @http = prepare_http_connection
    end

    # Send a GET request.
    def get(path, options = {}, &block)
      execute('GET', path, options, nil, &block)
    end

    # Send a PUT request.
    def put(path, doc = nil, options = {})
      execute('PUT', path, options, doc)
    end

    # Send a POST request.
    def post(path, doc = nil, options = {}, &block)
      execute('POST', path, options, doc, &block)
    end

    # Send a DELETE request.
    def delete(path, options = {})
      execute('DELETE', path, options)
    end

    # Send a COPY request to the URI provided.
    def copy(path, destination, options = {})
      opts = options.nil? ? {} : options.dup
      opts[:headers] = options[:headers].nil? ? {} : options[:headers].dup
      opts[:headers]['Destination'] = destination
      execute('COPY', path, opts)
    end

    # Send a HEAD request.
    def head(path, options = {})
      options = options.merge(:head => true) # No parsing!
      execute('HEAD', path, options)
    end

    private

    # Duplicate and remove excess baggage from the provided URI
    def clean_uri(uri)
      uri = uri.dup
      uri.path     = ""
      uri.query    = nil
      uri.fragment = nil
      uri
    end

    # Take a look at the options povided and try to apply them to the HTTP conneciton.
    def prepare_http_connection
      conn = HTTPX.plugin(:persistent).plugin(:compression)
      if (proxy_uri = options[:proxy] || self.class.proxy)
        conn = conn.plugin(:proxy).with_proxy(uri: proxy_uri)
      end

      conn = set_http_connection_options(conn, options)
      conn
    end

    # Prepare the http connection options for HTTPX.
    # We try to maintain RestClient compatability in option names as this is what we used before.
    def set_http_connection_options(conn, opts)
      # Authentication
      unless uri.user.to_s.empty?
        conn = conn.plugin(:basic_authentication).basic_authentication(uri.user, uri.password)
      end

      # SSL Certificate option mapping
      @ssl_options = {}
      if opts.include?(:verify_ssl)
        @ssl_options[:verify_mode] = opts[:verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      end
      @ssl_options[:client_cert] = opts[:ssl_client_cert] if opts.include?(:ssl_client_cert)
      @ssl_options[:client_key]  = opts[:ssl_client_key]  if opts.include?(:ssl_client_key)
      @ssl_options[:ca_path] = (opts[:ssl_ca_file]) if opts.include?(:ssl_ca_file)

      # Timeout options

      conn = conn.with(
        timeout: { 
          operation_timeout: opts[:timeout],
          connect_timeout: opts[:open_timeout]
        }.compact
      )

      conn
      # conn.receive_timeout = opts[:timeout] 
      # conn.send_timeout    = opts[:read_timeout] if opts.include?(:read_timeout)
    end

    def execute(method, path, options, payload = nil, &block)
      req = {
        :method => method,
        :uri    => uri + path
      }

      # Prepare the request headers
      DEFAULT_HEADERS.merge(parse_and_convert_request_headers(options)).each do |key, value|
        req[:header] ||= {}
        req[:header][key] = value
      end

      # Prepare the request body, if provided
      unless payload.nil?
        req[:body] = payload_from_doc(req, payload, options)
      end

      send_and_parse_response(req, options, &block)
    end

    def send_and_parse_response(req, opts, &block)
      if block_given?
        parser = CouchRest::StreamRowParser.new(opts[:continuous] ? :feed : :array)
        response = send_request(req) do |chunk|
          parser.parse(chunk) do |doc|
            block.call(parse_body(doc, opts))
          end
        end
        handle_response_code(response)
        parse_body(parser.header, opts)
      else
        response = send_request(req)
        handle_response_code(response)
        parse_response(response, opts)
      end
    end

    # Send request, and leave a reference to the response for debugging purposes
    def send_request(req, &block)
      # require 'byebug'; byebug
      @last_response = @http.request(
        req[:method].downcase, 
        req[:uri], 
        {
          ssl: @ssl_options, 
          body: req[:body],
          headers: req[:header]
        }.compact
      )
      if block_given?
        @last_response.body.each(&block)
      end
      @last_response
    end

    def handle_response_code(response)
      raise_response_error(response) unless SUCCESS_RESPONSE_CODES.include?(response.status)
    end

    def parse_response(response, opts)
      if opts[:head]
        if opts[:raw]
          response.headers.to_h.map {|key, v| "#{key[0].upcase}#{key[1..-1]}: #{v}"}.join("\n")
        else
          response.headers.to_h.transform_keys {|key| "#{key[0].upcase}#{key[1..-1]}" }
        end
      else
        parse_body(response.body, opts)
      end
    end

    def parse_body(body, opts)
      if opts[:raw]
        # passthru
        body.to_s
      else
        MultiJson.load(body.to_s, prepare_json_load_options(opts))
      end
    end

    # Check if the provided doc is nil or special IO device or temp file. If not,
    # encode it into a string.
    #
    # The options supported are:
    # * :raw TrueClass, if true the payload will not be altered.
    #
    def payload_from_doc(req, doc, opts = {})
      if doc.is_a?(IO) || doc.is_a?(StringIO) || doc.is_a?(Tempfile) # attachments
        req[:header]['Content-Type'] = mime_for(req[:uri].path)
        doc.read # XXX in theory httpx supports streaming IO objects but spec failing
      elsif opts[:raw] || doc.nil?
        doc
      else
        MultiJson.encode(doc.respond_to?(:as_couch_json) ? doc.as_couch_json : doc)
      end
    end

    def mime_for(path)
      mime = MIME::Types.type_for path
      mime.empty? ? 'text/plain' : mime[0].content_type
    end

    def raise_response_error(response)
      exp = CouchRest::Exceptions::EXCEPTIONS_MAP[response.status]
      exp ||= CouchRest::RequestFailed
      raise exp.new(response)
    end

    def prepare_json_load_options(opts = {})
      options = {
        :create_additions => CouchRest.decode_json_objects, # For object conversion, if required
        :max_nesting      => false
      }
      KNOWN_PARSER_OPTIONS.each do |k|
        options[k] = opts[k] if opts.include?(k)
      end
      options
    end

    def parse_and_convert_request_headers(options)
      headers = options.include?(:headers) ? options[:headers].dup : {}
      HEADER_CONTENT_SYMBOL_MAP.each do |sym, key|
        if options.include?(sym)
          headers[key] = convert_content_type(options[sym])
        end
      end
      headers
    end

    def convert_content_type(type)
      if type.is_a?(Symbol)
        case type
        when :json
          'application/json'
        end
      else
        type
      end
    end

    class << self

      # Default proxy URL to use in all connections.
      attr_accessor :proxy

    end

  end
end
