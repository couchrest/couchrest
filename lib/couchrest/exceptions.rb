#
# CouchRest Exception Handling
#
# Restricted set of HTTP error response we'd expect from a CouchDB server. If we don't have a specific error handler,
# a generic Exception will be returned with the #http_code attribute set.
#
# Implementation based on [rest-client exception handling](https://github.com/rest-client/rest-client/blob/master/lib/restclient/exceptions.rb).
#
module CouchRest

 STATUSES = {
              200 => 'OK',
              201 => 'Created',
              202 => 'Accepted',

              304 => 'Not Modified',

              400 => 'Bad Request',
              401 => 'Unauthorized',
              403 => 'Forbidden',
              404 => 'Not Found',
              405 => 'Method Not Allowed',
              406 => 'Not Acceptable',
              409 => 'Conflict',
              412 => 'Precondition Failed',
              415 => 'Unsupported Media Type',
              416 => 'Requested Range Not Satisfiable',
              417 => 'Expectation Failed',

              500 => 'Internal Server Error',
  } 

  # This is the base CouchRest exception class. Rescue it if you want to
  # catch any exception that your request might raise.
  # You can get the status code by e.http_code, or see anything about the
  # response via e.response.
  # For example, the entire result body (which is
  # probably an HTML error page) is e.response.
  class Exception < RuntimeError
    attr_accessor :response
    attr_accessor :original_exception
    attr_writer :message

    def initialize response = nil, initial_response_code = nil
      @response = response
      @message = nil
      @initial_response_code = initial_response_code
    end

    def http_code
      # return integer for compatibility
      if @response
        @response.code.to_i
      else
        @initial_response_code
      end
    end

    def http_headers
      @response.headers if @response
    end

    def http_body
      @response.body if @response
    end

    def inspect
      "#{message}: #{http_body}"
    end

    def to_s
      inspect
    end

    def message
      @message || self.class.default_message
    end

    def self.default_message
      self.name
    end
  end

  # The request failed with an error code not managed by the code
  class RequestFailed < Exception
    def message
      "HTTP status code #{http_code}"
    end

    def to_s
      message
    end
  end

  module Exceptions
    EXCEPTIONS_MAP = {}
  end

  STATUSES.each_pair do |code, message|
    klass = Class.new(RequestFailed) do
      send(:define_method, :message) {"#{http_code ? "#{http_code} " : ''}#{message}"}
    end
    klass_constant = const_set message.delete(' \-\''), klass
    Exceptions::EXCEPTIONS_MAP[code] = klass_constant
  end

  # Base class for request timeouts.
  class Timeout < Exception
    def initialize(message=nil, original_exception=nil)
      super(nil, nil)
      self.message = message if message
      self.original_exception = original_exception if original_exception
    end
  end

  # Timeout when connecting to a server. Typically wraps Net::OpenTimeout (in
  # ruby 2.0 or greater).
  class OpenTimeout < Timeout
    def self.default_message
      'Timed out connecting to server'
    end
  end

  # Timeout when reading from a server. Typically wraps Net::ReadTimeout (in
  # ruby 2.0 or greater).
  class ReadTimeout < Timeout
    def self.default_message
      'Timed out reading data from server'
    end
  end

  # The server broke the connection prior to the request completing.  Usually
  # this means it crashed, or sometimes that your network connection was
  # severed before it could complete.
  class ServerBrokeConnection < Exception
    def initialize(message = 'Server broke connection')
      super nil, nil
      self.message = message
    end
  end

  class SSLCertificateNotVerified < Exception
    def initialize(message)
      super nil, nil
      self.message = message
    end
  end

end
