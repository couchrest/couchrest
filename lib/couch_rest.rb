class CouchRest
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
    create_db(path) rescue nil
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

  class << self
    def put uri, doc = nil
      payload = doc.to_json if doc
      JSON.parse(RestClient.put(uri, payload))
    end
  
    def get uri
      JSON.parse(RestClient.get(uri), :max_nesting => false)
    end
    
    def post uri, doc = nil
      payload = doc.to_json if doc
      JSON.parse(RestClient.post(uri, payload))
    end
    
    def delete uri
      JSON.parse(RestClient.delete(uri))
    end
    
    def paramify_url url, params = nil
      if params
        query = params.collect do |k,v|
          v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end
  end  
end
