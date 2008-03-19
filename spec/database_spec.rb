require File.dirname(__FILE__) + '/../lib/couch_rest'

describe CouchRest::Database do
  before(:each) do
    @cr = CouchRest.new("http://local.grabb.it:5984")
    begin
      @cr.create_db('couchrest-test')
    rescue RestClient::Request::RequestFailed
    end
  end
  describe "deleting one" do
    before(:each) do
      
    end
    it "should start with the test database" do
      @cr.databases.should include('couchrest-test')
    end
    it "should delete the database" do
      db = @cr.database('couchrest-test')
      r = db.delete!
      r.should == ""
      @cr.databases.should_not include('couchrest-test')
    end
  end

end