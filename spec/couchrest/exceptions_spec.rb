require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Exception do
  it "returns a 'message' equal to the class name if the message is not set, because 'message' should not be nil" do
    e = CouchRest::Exception.new
    expect(e.message).to eq "CouchRest::Exception"
  end

  it "returns the 'message' that was set" do
    e = CouchRest::Exception.new
    message = "An explicitly set message"
    e.message = message
    expect(e.message).to eq message
  end

  it "sets the exception message to ErrorMessage" do
    expect(CouchRest::ResourceNotFound.new.message).to eq 'Not Found'
  end

  it "contains exceptions in CouchRest" do
    expect(CouchRest::Unauthorized.new).to be_a_kind_of(RestClient::Exception)
    expect(CouchRest::ServerBrokeConnection.new).to be_a_kind_of(RestClient::Exception)
  end
end

describe CouchRest::ServerBrokeConnection do
  it "should have a default message of 'Server broke connection'" do
    e = CouchRest::ServerBrokeConnection.new
    expect(e.message).to eq 'Server broke connection'
  end
end

describe CouchRest::RequestFailed do
  before do
    @response = double('HTTP Response', :code => '500')
  end

  it "stores the http response on the exception" do
    response = "response"
    begin
      raise CouchRest::RequestFailed, response
    rescue CouchRest::RequestFailed => e
      expect(e.response).to eq response
    end
  end

  it "http_code convenience method for fetching the code as an integer" do
    expect(CouchRest::RequestFailed.new(@response).http_code).to eq 500
  end

  it "http_body convenience method for fetching the body (decoding when necessary)" do
    expect(CouchRest::RequestFailed.new(@response).http_code).to eq 500
    expect(CouchRest::RequestFailed.new(@response).message).to eq 'HTTP status code 500'
  end

  it "shows the status code in the message" do
    expect(CouchRest::RequestFailed.new(@response).to_s).to match(/500/)
  end
end

describe CouchRest::ResourceNotFound do
  it "also has the http response attached" do
    response = "response"
    begin
      raise CouchRest::ResourceNotFound, response
    rescue CouchRest::ResourceNotFound => e
      expect(e.response).to eq response
    end
  end

  it 'stores the body on the response of the exception' do
    body = "body"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      CouchRest.get "www.example.com"
      raise
    rescue CouchRest::ResourceNotFound => e
      expect(e.response.body).to eq body
    end
  end
end

