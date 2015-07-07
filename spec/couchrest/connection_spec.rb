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

    it "should not modify the provided URI" do
      uri = URI("http://localhost:5984/path/random?query=none#fragment")
      s = uri.to_s
      CouchRest::Connection.new(uri)
      expect(uri.to_s).to eql(s)
    end

    it "should clean the provided URI" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984/path/random?query=none#fragment")
      expect(conn.uri.to_s).to eql("http://localhost:5984")
    end

    it "should have instantiated an HTTP connection" do
      conn = CouchRest::Connection.new(URI "http://localhost:5984")
      expect(conn.http).to be_a(Net::HTTP::Persistent)
    end
    
    describe "with SSL options" do
      it "should leave the default if nothing set" do
        default = Net::HTTP::Persistent.new('test').verify_mode
        conn = CouchRest::Connection.new(URI "https://localhost:5984")
        expect(conn.http.verify_mode).to eql(default)
      end
      it "should support disabling SSL verify mode" do
        conn = CouchRest::Connection.new(URI("https://localhost:5984"), :verify_ssl => false)
        expect(conn.http.verify_mode).to eql(OpenSSL::SSL::VERIFY_NONE)
      end
      it "should support enabling SSL verify mode" do
        conn = CouchRest::Connection.new(URI("https://localhost:5984"), :verify_ssl => true)
        expect(conn.http.verify_mode).to eql(OpenSSL::SSL::VERIFY_PEER)
      end
      it "should support setting specific cert, key, and ca" do
        conn = CouchRest::Connection.new(URI("https://localhost:5984"),
          :ssl_client_cert => 'cert',
          :ssl_client_key  => 'key',
          :ssl_ca_file     => 'ca_file'
        )
        expect(conn.http.certificate).to eql('cert')
        expect(conn.http.private_key).to eql('key')
        expect(conn.http.ca_file).to eql('ca_file')
      end

    end

    describe "with timeout options" do
      it "should be set on the http object" do
        conn = CouchRest::Connection.new(URI("https://localhost:5984"),
                                         :timeout => 23,
                                         :open_timeout => 26
                                        )

        expect(conn.http.read_timeout).to eql(23)
        expect(conn.http.open_timeout).to eql(26)
      end
      it "should support read_timeout" do
        conn = CouchRest::Connection.new(URI("https://localhost:5984"),
                                         :read_timeout => 25
                                        )
        expect(conn.http.read_timeout).to eql(25)
      end 
    end
  
  end

  describe :get do
    
    let :doc do
      { '_id' => 'test-doc', 'name' => 'test document' }
    end
    let :uri do
      URI(DB.to_s + "/test-doc")
    end

    it "should send basic request" do
      DB.save_doc(doc)
      conn = CouchRest::Connection.new(uri)
      res = conn.get(uri.path)
      puts "RES: #{uri} #{res}"
      expect(res['name']).to eql(doc['name'])
    end

  end

  describe :close do

    it "should send a shutdown and end the session" do


    end

  end

end
