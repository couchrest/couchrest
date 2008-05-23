require File.dirname(__FILE__) + '/../deps/rest-client/lib/rest_client'
require "rubygems"
gem "json"
begin
  require "json/ext"
rescue LoadError
  $stderr.puts "C version of json (fjson) could not be loaded, using pure ruby one"
  require "json/pure"
end
require File.dirname(__FILE__) + '/database'

class CouchRest
  attr_accessor :uri
  def initialize server
    @uri = server
  end
  
  # list all databases on the server
  def databases
    CouchRest.get "#{@uri}/_all_dbs"
  end
  
  def database name
    CouchRest::Database.new(@uri, name)
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

  class << self
    def put uri, doc = nil
      payload = JSON.unparse doc if doc
      JSON.parse(RestClient.put(uri, payload))
    end
  
    def get uri
      JSON.parse(RestClient.get(uri))
    end
    
    def post uri, doc = nil
      payload = JSON.unparse doc if doc
      JSON.parse(RestClient.post(uri, payload))
    end
    
    def delete uri
      JSON.parse(RestClient.delete(uri))
    end
    
    def paramify_url url, params = nil
      if params
        query = params.collect do |k,v|
          v = JSON.unparse(v) if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end
  end
  
end


