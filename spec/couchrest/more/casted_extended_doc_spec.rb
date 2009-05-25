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
    @driver = Driver.new(:name => 'Matt')
    @car    = Car.new(:name => 'Renault 306', :driver => @driver)
  end

  it "should retain all properties of the casted attribute" do
    @car.driver.should == @driver
  end
  
  it "should let the casted document know who casted it" do
    @car.driver.casted_by.should == @car
  end
end

describe "assigning a value to casted attribute after initializing an object" do

  before(:each) do
    @car    = Car.new(:name => 'Renault 306')
    @driver = Driver.new(:name => 'Matt')
  end
  
  it "should not create an empty casted object" do
    @car.driver.should be_nil
  end
  
  # Note that this isn't casting the attribute, it's just assigning it a value
  # (see "should not cast attribute")
  it "should let you assign the value" do
    @car.driver = @driver
    @car.driver.name.should == 'Matt'
  end
  
  it "should not cast attribute" do
    @car.driver = JSON.parse(JSON.generate(@driver))
    @car.driver.should_not be_instance_of(Driver)
  end

end

describe "casting an extended document from parsed JSON" do

  before(:each) do
    @driver = Driver.new(:name => 'Matt')
    @car    = Car.new(:name => 'Renault 306', :driver => @driver)
    @new_car = Car.new(JSON.parse(JSON.generate(@car)))
  end

  it "should cast casted attribute" do
    @new_car.driver.should be_instance_of(Driver)
  end
  
  it "should retain all properties of the casted attribute" do
    @new_car.driver.should == @driver
  end
end