require 'spec_helper'

describe 'Configuration' do
  it 'should be possible to configure couchrest' do
    CouchRest.configure do |config|
      config.server_url = "http://localhost:5984"

      config.connection.timeout = 1000
      config.connection.open_timeout = 2000
      config.connection.read_timeout = 3000
    end

    expect(CouchRest.configuration.server_url).to eq('http://localhost:5984')
    expect(CouchRest.configuration.connection.timeout).to eq(1000)
    expect(CouchRest.configuration.connection.open_timeout).to eq(2000)
    expect(CouchRest.configuration.connection.read_timeout).to eq(3000)

    CouchRest.configure do |config|
      config.server_url = "http://www.example.com"
    end

    expect(CouchRest.configuration.server_url).to eq('http://www.example.com')
  end

  after do
    CouchRest.instance_variable_set('@configuration', CouchRest::Configuration.new)
  end
end
