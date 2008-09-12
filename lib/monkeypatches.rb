
# this file must be loaded after the JSON gem

class Time
  # this date format sorts lexicographically
  # and is compatible with Javascript's new Date(time_string) constructor
  # note that sorting will break if you store times from multiple timezones
  # I like to add a ENV['TZ'] = 'UTC' to my apps

  def to_json(options = nil)
    %("#{strftime("%Y/%m/%d %H:%M:%S %z")}")
  end

  # this works to decode the outputted time format
  # copied from ActiveSupport
  # def self.parse string, fallback=nil
  #   d = DateTime.parse(string).new_offset
  #   self.utc(d.year, d.month, d.day, d.hour, d.min, d.sec)
  # rescue
  #   fallback
  # end
end