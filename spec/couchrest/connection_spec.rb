require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Connection do


  let(:simple_response) { "{\"ok\":true}" }
  let(:parser) { MultiJson }
  let(:parser_opts) { {:max_nesting => false} }

  it "should exist" do
    conn = CouchRest::Connection.new(URI "http://localhost:5984")
    expect(conn).to respond_to :get
    expect(conn).to respond_to :put
    expect(conn).to respond_to :post
    expect(conn).to respond_to :copy
    expect(conn).to respond_to :delete
    expect(conn).to respond_to :head
  end

  describe "initialization" do

    it "should clean the provided URI" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984/path/random?query=none#fragment")
      expect(conn.uri.to_s).to eql("http://localhost:5984")
    end

    it "should have instantiated an HTTP connection" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984")
      expect(conn.http).to be_a(Net::HTTP::Persistent)
    end
    
    describe "with SSL options" do
      it "should support SSL verify mode" do

      end

      it "should support setting specific cert, key, and ca" do
        keys = [:ssl_client_cert, :ssl_client_key, :ssl_ca_file]
      end

    end

    describe "with timeout options" do
      it "should be set on the http object" do

      end
    end
  
  end

  describe :get do
    it "should send basic request" do
      
    end

  end

  describe :close do

    it "should send a shutdown and end the session" do


    end

  end

end
