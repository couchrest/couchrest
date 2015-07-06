module CouchRest

  # Handle connections to the CouchDB server and provide a set of HTTP based methods to
  # perform requests.
  #
  # All connection are persistent. A connection cannot be re-used to connect to other servers.
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

    attr_accessor :uri, :status, :http

    def initialize(uri, options = {})
      raise "CouchRest::Connection.new requires URI::HTTP(S) parameter" unless uri.is_a?(URI::HTTP)
      self.status = :new
      self.uri = clean_uri(uri)
      prepare_http_connection(options)
    end

    # Send a GET request.
    def get(path, options = {})
      execute(Net::HTTP::Get, path, options)
    end

    # Send a PUT request.
    def put(path, doc = nil, options = {})
      execute(Net::HTTP::Put, path, options, doc)
    end

    # Send a POST request.
    def post(path, doc = nil, options = {})
      execute(Net::HTTP::Post, path, options, doc)
    end

    # Send a DELETE request.
    def delete(path, options = {})
      execute(Net::HTTP::Delete, path, options)
    end

    # Send a COPY request to the URI provided.
    def copy(path, destination, options = {})
      opts = options.nil? ? {} : options.dup
      # also copy headers!
      opts[:headers] = options[:headers].nil? ? {} : options[:headers].dup
      opts[:headers]['Destination'] = destination
      execute(Net::HTTP::Copy, path, opts)
    end

    # Send a HEAD request.
    def head(path, options = {})
      execute(Net::HTTP::Head, path, options)
    end

    # Close the connection. This will happen automatically if the current thread is
    # killed, so shouldn't be used under normal circumstances.
    def close
      http.shutdown
    end

    protected

    # Duplicate and remove excess baggage from the provided URI
    def clean_uri(uri)
      uri = uri.dup
      uri.path     = ""
      uri.query    = nil
      uri.fragment = nil
      uri
    end

    # Take a look at the options povided and try to apply them to the HTTP conneciton.
    # We try to maintain RestClient compatability here.
    def prepare_http_connection(opts)
      self.http = Net::HTTP::Persistent.new 'couchrest'

      if opts.include?(:verify_ssl)
        http.verify_mode = opts[:verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      end
      
      # SSL Certificate option mapping
      http.certificate = opts[:ssl_client_cert] if opts.include?(:ssl_client_cert)
      http.private_key = opts[:ssl_client_key] if opts.include?(:ssl_client_key)
      http.ca_file = opts[:ssl_ca_file] if opts.include?(:ssl_ca_file)
    end



    def execute(method, path, options, payload = nil)
      req = method.new(path)

      # Prepare the request headers
      DEFAULT_HEADERS.merge(parse_and_convert_request_headers(options)).each do |key, value|
        req[key] = value
      end

      # Prepare the request body, if provided
      req.body = payload_from_doc(payload, options) if payload

      begin
        parse_response(method, http.request(uri + path, req), options)

      rescue Exception => e
        if $DEBUG
          raise "Error while sending a #{method.to_s.upcase} request #{uri}\noptions: #{opts.inspect}\n#{e}"
        else
          raise e
        end
      end
    end

    # Check if the provided doc is nil or special IO device or temp file. If not,
    # encode it into a string.
    #
    # The options supported are:
    # * :raw TrueClass, if true the payload will not be altered.
    #
    def payload_from_doc(doc, opts = {})
      if opts[:raw] || doc.nil? || doc.is_a?(IO) || doc.is_a?(Tempfile)
        doc
      else
        MultiJson.encode(doc.respond_to?(:as_couch_json) ? doc.as_couch_json : doc)
      end
    end

    # Parse the response provided.
    def parse_response(method, result, opts)
      if opts[:raw] || method.is_a?(Net::HTTP::Head)
        # passthru
        result
      else
        MultiJson.load(result, prepare_json_load_options(opts))
      end
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

    # An array of all the options that should be passed through to restclient.
    # Anything not in this list will be passed to the JSON parser.
    def request_option_keys
      [ :method, :url, :payload, :headers, :timeout, :open_timeout ]
    end

    def parse_and_convert_request_headers(old_headers)
      headers = {}
      HEADER_CONTENT_SYMBOL_MAP.each do |sym, key|
        if old_headers.include?(sym)
          headers[key] = convert_content_type(headers[sym])
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

  end
end
