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

require 'rest_client'
require 'multi_json'

# Not sure why this is required, so removed until a reason is found!
$:.unshift File.dirname(__FILE__) unless
 $:.include?(File.dirname(__FILE__)) ||
 $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'couchrest/monkeypatches'
require 'couchrest/rest_api'
require 'couchrest/support/inheritable_attributes'

require 'forwardable'

# = CouchDB, close to the metal
module CouchRest
  autoload :Attributes,   'couchrest/attributes'
  autoload :Server,       'couchrest/server'
  autoload :Database,     'couchrest/database'
  autoload :Document,     'couchrest/document'
  autoload :Design,       'couchrest/design'
  autoload :Model,        'couchrest/model'
  autoload :Pager,        'couchrest/helper/pager'
  autoload :Streamer,     'couchrest/helper/streamer'
  autoload :Attachments,  'couchrest/helper/attachments'
  autoload :Upgrade,      'couchrest/helper/upgrade'

  # we extend CouchRest with the RestAPI module which gives us acess to
  # the get, post, put, delete and copy
  CouchRest.extend(::CouchRest::RestAPI)

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
      when /^(https?:\/\/)(.*)\/(.*)\/(.*)/
        scheme = $1
        host = $2
        db = $3
        docid = $4
      when /^(https?:\/\/)(.*)\/(.*)/
        scheme = $1
        host = $2
        db = $3
      when /^(https?:\/\/)(.*)/
        scheme = $1
        host = $2
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
        :host => (scheme || "http://") + (host || "127.0.0.1:5984"),
        :database => db,
        :doc => docid
      }
    end

    # set proxy to use
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

    def paramify_url url, params = {}
      if params && !params.empty?
        query = params.collect do |k,v|
          v = MultiJson.encode(v) if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end
  end # class << self
end
# For the sake of backwards compatability, generate a dummy ExtendedDocument class
# which should be replaced by real library: couchrest_extended_document.
#
# Added 2010-05-10 by Sam Lown. Please remove at some point in the future.
#
class CouchRest::ExtendedDocument < CouchRest::Document

  def self.inherited(subclass)
    raise "ExtendedDocument is no longer included in CouchRest base driver, see couchrest_extended_document gem"
  end

end
