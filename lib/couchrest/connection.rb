module CouchRest

  # Handle connections to the CouchDB server and provide a set of HTTP based methods to
  # perform requests.
  #
  # All connection are persistent. A connection cannot be re-used to connect to other servers.
  #
  class Connection

    attr_accessor :uri, :status, :http

    def initialize(uri)
      self.status = :new
      http = Net::HTTP::Persistent.new 'couchrest'
    end

    # Send a GET request.
    def get(path, options = {})
      execute(path, :get, options)
    end

    # Send a PUT request.
    def put(path, doc = nil, options = {})
      execute(path, :put, options, doc)
    end

    # Send a POST request.
    def post(path, doc = nil, options = {})
      execute(path, :post, options, doc)
    end

    # Send a DELETE request.
    def delete(path, options = {})
      execute(path, :delete, options)
    end

    # Send a COPY request to the URI provided.
    def copy(path, destination, options = {})
      opts = options.nil? ? {} : options.dup
      # also copy headers!
      opts[:headers] = options[:headers].nil? ? {} : options[:headers].dup
      opts[:headers]['Destination'] = destination
      execute(path, :copy, opts)
    end

    # Send a HEAD request.
    def head(path, options = {})
      execute(path, :head, options)
    end

    # The default RestClient headers used in each request.
    def default_headers
      {
        :content_type => :json,
        :accept       => :json
      }
    end

    # Close the connection!
    def close

    end

    protected

    def execute(path, method, options, payload = nil)
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
        :raw => false,
        :head => (method == :head)
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
      opts = opts.update(:create_additions => true) if decode_json_objects
      (opts.delete(:raw) || opts.delete(:head)) ? result : MultiJson.decode(result, opts.update(:max_nesting => false))
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
