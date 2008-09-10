require "rubygems"
require 'json'
require 'rest_client'

require File.dirname(__FILE__) + '/couch_rest'
require File.dirname(__FILE__) + '/database'
require File.dirname(__FILE__) + '/pager'
require File.dirname(__FILE__) + '/file_manager'
require File.dirname(__FILE__) + '/streamer'

# this has to come after the JSON gem

# this date format sorts lexicographically
# and is compatible with Javascript's new Date(time_string) constructor
class Time
  def to_json(options = nil)
    %("#{strftime("%Y/%m/%d %H:%M:%S %z")}")
  end
end