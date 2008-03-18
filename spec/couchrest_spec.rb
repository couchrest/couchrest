require File.dirname(__FILE__) + '/../lib/couchrest'

describe Couchrest do

  before(:each) do
    @cr = Couchrest.new("http://local.grabb.it:5984")
  end

  describe "getting status" do
    it "should list databases" do
      @cr.databases.should be_an Array
      
    end
  end

  describe "successfully creating a database" do
    it "should start without a database" do
    end
    it "should PUT the database" do
      
    end
    it "should return the created databse" do
      
    end
  end

  describe "failing to create a database because the name is taken" do
    it "should start without a database" do
      
    end
    it "should PUT the database and raise an error" do
      
    end
    it "should not result in another database" do
      
    end
  end

end