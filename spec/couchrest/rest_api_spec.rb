require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::RestAPI do

  describe "class methods" do

    subject { CouchRest }

    let(:request) { RestClient::Request }
    let(:simple_response) { "{\"ok\":true}" }
    let(:parser) { MultiJson }
    let(:parser_opts) { {:max_nesting => false} }

    it "should exist" do
      should respond_to :get
      should respond_to :put
      should respond_to :post
      should respond_to :copy
      should respond_to :delete
      should respond_to :head
    end

    it "should provide default headers" do
      should respond_to :default_headers
      expect(CouchRest.default_headers).to be_a(Hash)
    end


    describe :get do
      it "should send basic request" do
        req = {:url => 'foo', :method => :get, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo')
      end

      it "should never modify options" do
        options = {:timeout => 1000}
        options.freeze
        expect(request).to receive(:execute).and_return(simple_response)
        expect(parser).to receive(:decode)
        expect { CouchRest.get('foo', options) }.to_not raise_error
      end


      it "should accept 'content_type' header" do
        req = {:url => 'foo', :method => :get, :headers => CouchRest.default_headers.merge(:content_type => :foo)}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo', :content_type => :foo)
      end

      it "should accept 'accept' header" do
        req = {:url => 'foo', :method => :get, :headers => CouchRest.default_headers.merge(:accept => :foo)}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo', :accept => :foo)
      end

      it "should forward RestClient options" do
        req = {:url => 'foo', :method => :get, :timeout => 1000, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo', :timeout => 1000)
      end

      it "should forward parser options" do
        req = {:url => 'foo', :method => :get, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts.merge(:random => 'foo'))
        CouchRest.get('foo', :random => 'foo')
      end

      it "should accept raw option" do
        req = {:url => 'foo', :method => :get, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to_not receive(:decode)
        expect(CouchRest.get('foo', :raw => true)).to eql(simple_response)
      end

      it "should allow override of method (not that you'd want to!)" do
        req = {:url => 'foo', :method => :fubar, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo', :method => :fubar)
      end

      it "should allow override of url (not that you'd want to!)" do
        req = {:url => 'foobardom', :method => :get, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.get('foo', :url => 'foobardom')
      end


      it "should forward an exception if raised" do
        expect(request).to receive(:execute).and_raise(RestClient::Exception)
        expect { CouchRest.get('foo') }.to raise_error(RestClient::Exception)
      end

      context 'when decode_json_objects is true' do
        class TestObject
          def self.json_create(args)
            new
          end
        end

        before(:each) do
          CouchRest.decode_json_objects = true
        end

        after(:each) do
          CouchRest.decode_json_objects = false
        end

        it 'should return the response as a Ruby object' do
          CouchRest.put "#{COUCHHOST}/#{TESTDB}/test", JSON.create_id => TestObject.to_s

          expect(CouchRest.get("#{COUCHHOST}/#{TESTDB}/test").class).to eql(TestObject)
        end
      end
    end

    describe :post do
      it "should send basic request" do
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers, :payload => 'data'}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:encode).with('data').and_return('data')
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', 'data')
      end

      it "should send basic request" do
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers, :payload => 'data'}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:encode).with('data').and_return('data')
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', 'data')
      end

      it "should send raw request" do
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers, :payload => 'data'}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to_not receive(:encode)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', 'data', :raw => true)
      end

      it "should not encode nil request" do
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to_not receive(:encode)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', nil)
      end

      it "should send raw request automatically if file provided" do
        f = File.open(FIXTURE_PATH + '/attachments/couchdb.png')
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers, :payload => f}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to_not receive(:encode)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', f)
        f.close
      end

      it "should send raw request automatically if Tempfile provided" do
        f = Tempfile.new('couchrest')
        req = {:url => 'foo', :method => :post, :headers => CouchRest.default_headers, :payload => f}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to_not receive(:encode)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', f)
        f.close
      end

      it "should use as_couch_json method if available" do
        h = {'foo' => 'bar'}
        doc = CouchRest::Document.new(h)
        expect(doc).to receive(:as_couch_json).and_return(h)
        expect(request).to receive(:execute).and_return(simple_response)
        expect(parser).to receive(:encode).with(h)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.post('foo', doc)
      end
    end


    describe :put do
      # Only test basic as practically same as post
      it "should send basic request" do
        req = {:url => 'foo', :method => :put, :headers => CouchRest.default_headers, :payload => 'data'}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:encode).with('data').and_return('data')
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.put('foo', 'data')
      end

    end

    describe :delete do
      it "should send basic request" do
        req = {:url => 'foo', :method => :delete, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.delete('foo')
      end
    end

    describe :copy do
      it "should send basic request" do
        headers = CouchRest.default_headers.merge(
          'Destination' => 'fooobar'
        )
        req = {:url => 'foo', :method => :copy, :headers => headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        expect(parser).to receive(:decode).with(simple_response, parser_opts)
        CouchRest.copy('foo', 'fooobar')
      end

      it "should never modify header options" do
        options = {:headers => {:content_type => :foo}}
        options.freeze
        expect(request).to receive(:execute).and_return(simple_response)
        expect(parser).to receive(:decode)
        expect { CouchRest.copy('foo', 'foobar', options) }.to_not raise_error
      end

    end

    describe :head do
      it "should send basic request" do
        req = {:url => 'foo', :method => :head, :headers => CouchRest.default_headers}
        expect(request).to receive(:execute).with(req).and_return(simple_response)
        CouchRest.head('foo')
      end
    end

  end

end
