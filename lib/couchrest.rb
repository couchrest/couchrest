require "rubygems"
require 'json'
require 'rest_client'

$:.unshift File.expand_path(File.dirname(__FILE__))


require 'monkeypatches'
require 'couchrest/server'
require 'couchrest/database'


module CouchRest
  def self.new(*opts)
    Server.new(*opts)
  end
end