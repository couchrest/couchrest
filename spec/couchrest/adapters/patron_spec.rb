require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

if HTTP_LAYER == 'Patron'
  require File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'couchrest', 'core', 'adapters', 'patron')
  
  describe "PatronAdapter" do
  
    describe "shared sessions" do
      before(:all) do
        ::HttpAbstraction.get("http://127.0.0.1:5984/couchrest-test/#{__LINE__}")
      end
    
      it "should be able to create a session per DB" do
        ::HttpAbstraction.sessions.should be_an_instance_of(Hash)
        session = ::HttpAbstraction.sessions['http://127.0.0.1:5984']
        session.base_url.should == 'http://127.0.0.1:5984'
      end 
    
      it "should have unique, reusable sessions" do
        session_id = ::HttpAbstraction.sessions['http://127.0.0.1:5984'].object_id
        ::HttpAbstraction.get("http://127.0.0.1:5984/couchrest-test/#{__LINE__}")
        session_id.should == ::HttpAbstraction.sessions['http://127.0.0.1:5984'].object_id
        ::HttpAbstraction.get("http://127.0.0.1:5984/couchrest-test/#{__LINE__}")
        session_id.should == ::HttpAbstraction.sessions['http://127.0.0.1:5984'].object_id
        ::HttpAbstraction.get("http://localhost:5984/couchrest-test/#{__LINE__}")
        session_id.should_not == ::HttpAbstraction.sessions['http://localhost:5984'].object_id
      end
    end
  
  end 
end       