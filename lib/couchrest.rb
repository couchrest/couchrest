# Copyright 2008 J. Chris Anderson
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require "rubygems"
require 'json'
require 'rest_client'
# require 'extlib'

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))
  
  
require 'couchrest/monkeypatches'

# = CouchDB, close to the metal
module CouchRest
  autoload :Server,       'couchrest/core/server'
  autoload :Database,     'couchrest/core/database'
  autoload :Document,     'couchrest/core/document'
  autoload :Design,     'couchrest/core/design'
  autoload :View,         'couchrest/core/view'
  autoload :Model,        'couchrest/core/model'
  autoload :Pager,        'couchrest/helper/pager'
  autoload :FileManager,  'couchrest/helper/file_manager'
  autoload :Streamer,     'couchrest/helper/streamer'
  
  # The CouchRest module methods handle the basic JSON serialization 
  # and deserialization, as well as query parameters. The module also includes
  # some helpers for tasks like instantiating a new Database or Server instance.
  class << self

    # todo, make this parse the url and instantiate a Server or Database instance
    # depending on the specificity.
    def new(*opts)
      Server.new(*opts)
    end
    
    def parse url
      case url
      when /^http:\/\/(.*)\/(.*)\/(.*)/
        host = $1
        db = $2
        docid = $3
      when /^http:\/\/(.*)\/(.*)/
        host = $1
        db = $2
      when /^http:\/\/(.*)/
        host = $1
      when /(.*)\/(.*)\/(.*)/
        host = $1
        db = $2
        docid = $3
      when /(.*)\/(.*)/
        host = $1
        db = $2
      else
        db = url
      end

      db = nil if db && db.empty?

      {
        :host => host || "127.0.0.1:5984",
        :database => db,
        :doc => docid
      }
    end

    # set proxy for RestClient to use
    def proxy url
      RestClient.proxy = url
    end

    # ensure that a database exists
    # creates it if it isn't already there
    # returns it after it's been created
    def database! url
      parsed = parse url
      cr = CouchRest.new(parsed[:host])
      cr.database!(parsed[:database])
    end
  
    def database url
      parsed = parse url
      cr = CouchRest.new(parsed[:host])
      cr.database(parsed[:database])
    end
    
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
    
    def copy uri, destination
      JSON.parse(RestClient.copy(uri, {'Destination' => destination}))
    end
    
    def move uri, destination
      JSON.parse(RestClient.move(uri, {'Destination' => destination}))
    end
  
    def paramify_url url, params = {}
      if params && !params.empty?
        query = params.collect do |k,v|
          v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end
  end # class << self
end