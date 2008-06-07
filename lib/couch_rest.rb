require File.dirname(__FILE__) + '/../vendor/rest-client/lib/rest_client'
require "rubygems"
require 'json'


require File.dirname(__FILE__) + '/database'

class CouchRest
  attr_accessor :uri
  def initialize server = 'http://localhost:5984'
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


