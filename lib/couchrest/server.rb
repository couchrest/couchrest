module CouchRest
  class Server

    # URI object of the link to the server we're using.
    attr_reader :uri
    
    # Number of UUIDs to fetch from the server when preparing to save new
    # documents. Set to 1000 by default.
    attr_reader :uuid_batch_count

    # Accessor for the current internal array of UUIDs ready to be used when
    # saving new documents. See also #next_uuid.
    attr_reader :uuids

    # Connection object prepared on initialization
    attr_reader :connection

    # The connection options we should use to connect with
    attr_reader :connection_options

    def initialize(server = 'http://127.0.0.1:5984', opts = {})
      @uri = prepare_uri(server).freeze
      if opts.is_a?(Integer)
        # Backwards compatibility
        @uuid_batch_count = opts
        @connection_options = {}
      else
        @uuid_batch_count = opts.delete(:uuid_batch_count)
        @connection_options = opts
      end
      @uuid_batch_count ||= 1000
      @connection = Connection.new(uri, connection_options)
    end

    # Lists all databases on the server
    def databases
      connection.get "_all_dbs"
    end

    # Returns a CouchRest::Database for the given name
    def database(name)
      CouchRest::Database.new(self, name)
    end

    # Creates the database if it doesn't exist
    def database!(name)
      connection.head name # Check if the URL is valid
      database(name)
    rescue CouchRest::NotFound # Thrown if the HTTP HEAD fails
      create_db(name)
    end

    # GET the welcome message
    def info
      connection.get ""
    end

    # Create a database
    def create_db(name)
      connection.put name
      database(name)
    end

    # Restart the CouchDB instance
    def restart!
      connection.post "_restart"
    end

    # Retrive an unused UUID from CouchDB. Server instances manage caching a list of unused UUIDs.
    def next_uuid(count = @uuid_batch_count)
      if uuids.nil? || uuids.empty?
        @uuids = connection.get("_uuids?count=#{count}")["uuids"]
      end
      uuids.pop
    end

    protected

    def prepare_uri(url)
      uri = URI(url)
      uri.path     = ""
      uri.query    = nil
      uri.fragment = nil
      uri
    end

  end
end
