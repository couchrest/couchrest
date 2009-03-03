require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join(FIXTURE_PATH, 'more', 'card')

class Car < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  
  property :name
  property :driver, :cast_as => 'Driver'
end

class Driver < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  # You have to add a casted_by accessor if you want to reach a casted extended doc parent
  attr_accessor :casted_by
  
  property :name
end

describe "casting an extended document" do
  
  before(:each) do
    @car    = Car.new(:name => 'Renault 306')
    @driver = Driver.new(:name => 'Matt')
  end
  
  # it "should not create an empty casted object" do
  #   @car.driver.should be_nil
  # end
  
  it "should let you assign the casted attribute after instantializing an object" do
    @car.driver = @driver
    @car.driver.name.should == 'Matt'
  end
  
  it "should let the casted document who casted it" do
    Car.new(:name => 'Renault 306', :driver => @driver)
    @car.driver.casted_by.should == @car
  end
  
end