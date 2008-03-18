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
    def put uri, payload = nil
      response = RestClient.put(uri, payload)
      JSON.parse response
    end
  
    def get uri
      response = RestClient.get(uri)
      JSON.parse response
    end
    
    def delete uri
      response = RestClient.delete(uri)
      JSON.parse response
    end
  end
end
