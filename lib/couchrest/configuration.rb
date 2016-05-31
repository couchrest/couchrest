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

  PoolSettings = Struct.new(
    :timeout,
    :size
  )

  class Configuration
    DEFAULT_URL = 'http://127.0.0.1:5984'
    DEFAULT_UUID_BATCH_COUNT = 1000

    DEFAULT_POOL_TIMEOUT = 25
    DEFAULT_POOL_SIZE = 5

    attr_accessor :server_url, :uuid_batch_count, :connection, :pool

    def initialize
      @pool = PoolSettings.new
      @pool.timeout = DEFAULT_POOL_TIMEOUT
      @pool.size = DEFAULT_POOL_SIZE

      @connection = ConnectionSettings.new

      @server_url = DEFAULT_URL
      @uuid_batch_count = DEFAULT_UUID_BATCH_COUNT
    end
  end
end
