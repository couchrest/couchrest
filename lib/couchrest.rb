require "rubygems"
require 'json'
require 'rest_client'

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))
  
  
require 'couchrest/monkeypatches'

module CouchRest
  autoload :Server,       'couchrest/core/server'
  autoload :Database,     'couchrest/core/database'
  autoload :Pager,        'couchrest/helper/pager'
  autoload :FileManager,  'couchrest/helper/file_manager'
  
  def self.new(*opts)
    Server.new(*opts)
  end
end