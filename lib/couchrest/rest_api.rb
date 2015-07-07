module CouchRest

  #
  # CouchRest RestAPI
  #
  # Backwards compatible wrapper for instantiating a connection and performing
  # a request on demand.
  #
  # We recommend using `Server#connection` object directly if possible instead
  # of these class methods.
  #

  module RestAPI

    # Send a GET request.
    def get(url, options = {})
      connection(url, options) do |uri, conn|
        conn.get(uri.path, options)
      end
    end

    # Send a PUT request.
    def put(url, doc = nil, options = {})
      connection(url, options) do |uri, conn|
        conn.put(uri.path, doc, options)
      end
    end

    # Send a POST request.
    def post(url, doc = nil, options = {})
      connection(url, options) do |uri, conn|
        conn.post(uri.path, doc, options)
      end
    end

    # Send a DELETE request.
    def delete(url, options = {})
      connection(url, options) do |uri, conn|
        conn.delete(uri.path, options)
      end
    end

    # Send a COPY request to the URI provided.
    def copy(url, destination, options = {})
      connection(url, options) do |uri, conn|
        conn.copy(uri.path, destination, options)
      end
    end

    # Send a HEAD request.
    def head(url, options = {})
      connection(url, options) do |uri, conn|
        conn.head(uri.path, options)
      end
    end

    protected

    def connection(url, options)
      uri = URI url
      conn = CouchRest::Connection.new(uri, options)
      res = yield uri, conn
      conn.close
      res
    end

  end
end
