module CouchRest
  class Server
    attr_accessor :uri, :uuid_batch_count, :available_databases
    def initialize(server = 'http://127.0.0.1:5984', uuid_batch_count = 1000)
      case server
      when %r{\A(http://[^/]+)/(.*)\z}
        @uri, @prefix = $1, $2
      else   
        @uri, @prefix = server, ""
      end
      @uuid_batch_count = uuid_batch_count
    end

    # Add default prefix to database name
    def expand(name)
      @prefix + name
    end
  
    # Lists all "available" databases.
    # An available database, is a database that was specified
    # as avaiable by your code.
    # It allows to define common databases to use and reuse in your code
    def available_databases
      @available_databases ||= {}
    end
    
    # Adds a new available database and create it unless it already exists
    #
    # Example:
    #
    # @couch = CouchRest::Server.new
    # @couch.define_available_database(:default, "tech-blog")
    #
    def define_available_database(reference, db_name, create_unless_exists = true)
      available_databases[reference.to_sym] = create_unless_exists ? database!(db_name) : database(db_name)
    end
  
    # Checks that a database is set as available
    #
    # Example:
    #
    # @couch.available_database?(:default)
    #
    def available_database?(ref_or_name)
      ref_or_name.is_a?(Symbol) ? available_databases.keys.include?(ref_or_name) : available_databases.values.map{|db| db.name}.include?(expand(ref_or_name))
    end
  
    def default_database=(name, create_unless_exists = true)
      define_available_database(:default, name, create_unless_exists = true)
    end
    
    def default_database
      available_databases[:default]
    end
  
    # Lists all databases on the server
    def databases
      dbs = CouchRest.get "#{@uri}/_all_dbs"
      unless @prefix.empty?
        pfx = @prefix.gsub('/','%2F')
        dbs.reject! { |db| db.index(pfx) != 0 }
      end
      dbs
    end
  
    # Returns a CouchRest::Database for the given name
    def database(name)
      CouchRest::Database.new(self, expand(name))
    end
  
    # Creates the database if it doesn't exist
    def database!(name)
      create_db(name) rescue nil
      database(name)
    end
  
    # GET the welcome message
    def info
      CouchRest.get "#{@uri}/"
    end

    # Create a database
    def create_db(name)
      CouchRest.put "#{@uri}/#{expand(name).gsub('/','%2F')}"
      database(name)
    end

    # Restart the CouchDB instance
    def restart!
      CouchRest.post "#{@uri}/_restart"
    end

    # Retrive an unused UUID from CouchDB. Server instances manage caching a list of unused UUIDs.
    def next_uuid(count = @uuid_batch_count)
      @uuids ||= []
      if @uuids.empty?
        @uuids = CouchRest.get("#{@uri}/_uuids?count=#{count}")["uuids"]
      end
      @uuids.pop
    end

  end
end
