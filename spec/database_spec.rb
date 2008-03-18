require File.dirname(__FILE__) + '/../lib/couchrest'

describe Couchrest::Database do
  before(:each) do
    @cr = Couchrest.new("http://local.grabb.it:5984")
  end
  describe "deleting one" do
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