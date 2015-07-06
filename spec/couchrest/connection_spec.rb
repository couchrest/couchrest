require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Connection do


  let(:simple_response) { "{\"ok\":true}" }
  let(:parser) { MultiJson }
  let(:parser_opts) { {:max_nesting => false} }

  it "should exist" do
    conn = CouchRest::Connection.new(URI "http://localhost:5984")
    conn.should respond_to :get
    conn.should respond_to :put
    conn.should respond_to :post
    conn.should respond_to :copy
    conn.should respond_to :delete
    conn.should respond_to :head
  end

  describe "initialization" do

    it "should clean the provided URI" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984/path/random?query=none#fragment")
      conn.uri.to_s.should eql("http://localhost:5984/")
    end

    it "should have instantiated an HTTP connection" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984")
      conn.http.should be_a(Net::HTTP::Persistent)
    end
  
  end

end
