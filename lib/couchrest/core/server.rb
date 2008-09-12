module CouchRest
  class Server
    attr_accessor :uri, :uuid_batch_count
    def initialize server = 'http://localhost:5984', uuid_batch_count = 1000
      @uri = server
      @uuid_batch_count = uuid_batch_count
    end
  
    # ensure that a database exists
    # creates it if it isn't already there
    # returns it after it's been created
    def self.database! url
      uri = URI.parse url
      path = uri.path
      uri.path = ''
      cr = CouchRest.new(uri.to_s)
      cr.database!(path)
    end
  
    def self.database url
      uri = URI.parse url
      path = uri.path
      uri.path = ''
      cr = CouchRest.new(uri.to_s)
      cr.database(path)
    end
  
    # list all databases on the server
    def databases
      CouchRest.get "#{@uri}/_all_dbs"
    end
  
    def database name
      CouchRest::Database.new(self, name)
    end
  
    # creates the database if it doesn't exist
    def database! name
      create_db(name) rescue nil
      database name
    end
  
    # get the welcome message
    def info
      CouchRest.get "#{@uri}/"
    end

    # create a database
    def create_db name
      CouchRest.put "#{@uri}/#{name}"
      database name
    end

    # restart the couchdb instance
    def restart!
      CouchRest.post "#{@uri}/_restart"
    end

    def next_uuid count = @uuid_batch_count
      @uuids ||= []
      if @uuids.empty?
        @uuids = CouchRest.post("#{@uri}/_uuids?count=#{count}")["uuids"]
      end
      @uuids.pop
    end

  end
end
