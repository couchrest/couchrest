require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::RestAPI do

  describe "class methods" do

    subject { CouchRest }

    let :mock_conn do
      CouchRest::Connection.new(URI "http://mock")
    end

    it "should exist" do
      expect(subject).to respond_to :get
      expect(subject).to respond_to :put
      expect(subject).to respond_to :post
      expect(subject).to respond_to :copy
      expect(subject).to respond_to :delete
      expect(subject).to respond_to :head
    end

    describe "basic forwarding" do

      let :uri do
        URI("http://mock/db/doc")
      end

      it "should start and use connection" do
        expect(CouchRest::Connection).to receive(:new)
          .with(uri, {})
          .and_return(mock_conn)
  
        stub_request(:get, uri.to_s)
          .to_return(:body => {'_id' => 'test', 'name' => 'none'}.to_json)

        res = CouchRest.get(uri.to_s)
        expect(res['name']).to eql('none')
      end

      it "should start connection with options" do
        expect(CouchRest::Connection).to receive(:new)
          .with(uri, hash_including(:test => 'foo'))
          .and_return(mock_conn)
  
        stub_request(:get, uri.to_s)
          .to_return(:body => {'_id' => 'test', 'name' => 'none'}.to_json)

        res = CouchRest.get(uri.to_s, :test => 'foo')
        expect(res['name']).to eql('none')
      end

      it "should handle query parameters and send them to connection" do

        uri = URI("http://mock/db/doc?q=a")
        expect(CouchRest::Connection).to receive(:new)
          .with(uri, {})
          .and_return(mock_conn)
        stub_request(:get, uri.to_s)
          .to_return(:body => {'_id' => 'test', 'name' => 'none'}.to_json)
        res = CouchRest.get(uri.to_s)
        expect(res['name']).to eql('none')
      end

    end

    describe :delete do
    
      it "should delete a document" do
        res = CouchRest.post(DB.uri.to_s, {'name' => "TestDoc"})
        res = CouchRest.delete("#{DB.uri.to_s}/#{res['id']}?rev=#{res['rev']}")
        expect(res['ok']).to be_true
      end

    end

  end
end
