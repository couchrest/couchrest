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
# note that sorting will break if you store times from multiple timezones
# I like to add a ENV['TZ'] = 'UTC' to my apps
class Time
  def to_json(options = nil)
    %("#{strftime("%Y/%m/%d %H:%M:%S %z")}")
  end
  # this works to decode the outputted time format
  # from ActiveSupport
  # def self.parse string, fallback=nil
  #   d = DateTime.parse(string).new_offset
  #   self.utc(d.year, d.month, d.day, d.hour, d.min, d.sec)
  # rescue
  #   fallback
  # end
end