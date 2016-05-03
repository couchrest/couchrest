module CouchRest
  ConnectionSettings = Struct.new(
    :timeout,
    :read_timeout,
    :open_timeout,
    :ssl_client_cert,
    :ssl_client_key,
    :ssl_ca_file,
    :verify_ssl,
    :proxy
  )

  class Configuration
    DEFAULT_URL = 'http://127.0.0.1:5984'
    DEFAULT_UUID_BATCH_COUNT = 1000

    attr_accessor :server_url, :uuid_batch_count, :connection

    def initialize
      @connection = ConnectionSettings.new
      @server_url = DEFAULT_URL
      @uuid_batch_count = DEFAULT_UUID_BATCH_COUNT
    end
  end
end
