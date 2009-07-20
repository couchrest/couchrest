require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join(FIXTURE_PATH, 'more', 'person')
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'more', 'invoice')
require File.join(FIXTURE_PATH, 'more', 'service')
require File.join(FIXTURE_PATH, 'more', 'course')


describe "ExtendedDocument properties" do
  
  before(:each) do
    reset_test_db!
    @card = Card.new(:first_name => "matt")
  end
  
  it "should be accessible from the object" do
    @card.properties.should be_an_instance_of(Array)
    @card.properties.map{|p| p.name}.should include("first_name")
  end
  
  it "should let you access a property value (getter)" do
    @card.first_name.should == "matt"
  end
  
  it "should let you set a property value (setter)" do
    @card.last_name = "Aimonetti"
    @card.last_name.should == "Aimonetti"
  end
  
  it "should not let you set a property value if it's read only" do
    lambda{@card.read_only_value = "test"}.should raise_error
  end
  
  it "should let you use an alias for an attribute" do
    @card.last_name = "Aimonetti"
    @card.family_name.should == "Aimonetti"
    @card.family_name.should == @card.last_name
  end
  
  it "should let you use an alias for a casted attribute" do
    @card.cast_alias = Person.new(:name => "Aimonetti")
    @card.cast_alias.name.should == ["Aimonetti"]
    @card.calias.name.should == ["Aimonetti"]
    card = Card.new(:first_name => "matt", :cast_alias => {:name => "Aimonetti"})
    card.cast_alias.name.should == ["Aimonetti"]
    card.calias.name.should == ["Aimonetti"]
  end
  
  it "should be auto timestamped" do
    @card.created_at.should be_nil
    @card.updated_at.should be_nil
    @card.save.should be_true
    @card.created_at.should_not be_nil
    @card.updated_at.should_not be_nil
  end
  
  describe "validation" do
    before(:each) do
      @invoice = Invoice.new(:client_name => "matt", :employee_name => "Chris", :location => "San Diego, CA")
    end
    
    it "should be able to be validated" do
      @card.valid?.should == true
    end

    it "should let you validate the presence of an attribute" do
      @card.first_name = nil
      @card.should_not be_valid
      @card.errors.should_not be_empty
      @card.errors.on(:first_name).should == ["First name must not be blank"]
    end
    
    it "should let you look up errors for a field by a string name" do
      @card.first_name = nil
      @card.should_not be_valid
      @card.errors.on('first_name').should == ["First name must not be blank"]
    end

    it "should validate the presence of 2 attributes" do
      @invoice.clear
      @invoice.should_not be_valid
      @invoice.errors.should_not be_empty
      @invoice.errors.on(:client_name).first.should == "Client name must not be blank"
      @invoice.errors.on(:employee_name).should_not be_empty
    end
    
    it "should let you set an error message" do
      @invoice.location = nil
      @invoice.valid?
      @invoice.errors.on(:location).should == ["Hey stupid!, you forgot the location"]
    end
    
    it "should validate before saving" do
      @invoice.location = nil
      @invoice.should_not be_valid
      @invoice.save.should be_false
      @invoice.should be_new_document
    end
  end
  
  describe "autovalidation" do
    before(:each) do
      @service = Service.new(:name => "Coumpound analysis", :price => 3_000)
    end
    
    it "should be valid" do
      @service.should be_valid
    end
    
    it "should not respond to properties not setup" do
      @service.respond_to?(:client_name).should be_false
    end
    
    describe "property :name, :length => 4...20" do
      
      it "should autovalidate the presence when length is set" do
        @service.name = nil
        @service.should_not be_valid
        @service.errors.should_not be_nil
        @service.errors.on(:name).first.should == "Name must be between 4 and 19 characters long"
      end
    
      it "should autovalidate the correct length" do
        @service.name = "a"
        @service.should_not be_valid
        @service.errors.should_not be_nil
        @service.errors.on(:name).first.should == "Name must be between 4 and 19 characters long"
      end
    end
  end
  
  describe "casting" do
    before(:each) do
      @course = Course.new(:title => 'Relaxation')
    end

    describe "when value is nil" do
      it "leaves the value unchanged" do
        @course.title = nil
        @course['title'].should == nil
      end
    end

    describe "when type primitive is an Object" do
      it "it should not cast given value" do
        @course.participants = [{}, 'q', 1]
        @course['participants'].should eql([{}, 'q', 1])
      end
    end
    
    describe "when type primitive is a String" do
      it "keeps string value unchanged" do
        value = "1.0"
        @course.title = value
        @course['title'].should equal(value)
      end
      
      it "it casts to string representation of the value" do
        @course.title = 1.0
        @course['title'].should eql("1.0")
      end
    end

    describe 'when type primitive is a Float' do
      it 'returns same value if a float' do
        value = 24.0
        @course.estimate = value
        @course['estimate'].should equal(value)
      end

      it 'returns float representation of a zero string integer' do
        @course.estimate = '0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string integer' do
        @course.estimate = '24'
        @course['estimate'].should eql(24.0)
      end

      it 'returns float representation of a negative string integer' do
        @course.estimate = '-24'
        @course['estimate'].should eql(-24.0)
      end

      it 'returns float representation of a zero string float' do
        @course.estimate = '0.0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string float' do
        @course.estimate = '24.35'
        @course['estimate'].should eql(24.35)
      end

      it 'returns float representation of a negative string float' do
        @course.estimate = '-24.35'
        @course['estimate'].should eql(-24.35)
      end

      it 'returns float representation of a zero string float, with no leading digits' do
        @course.estimate = '.0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string float, with no leading digits' do
        @course.estimate = '.41'
        @course['estimate'].should eql(0.41)
      end

      it 'returns float representation of a zero integer' do
        @course.estimate = 0
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive integer' do
        @course.estimate = 24
        @course['estimate'].should eql(24.0)
      end

      it 'returns float representation of a negative integer' do
        @course.estimate = -24
        @course['estimate'].should eql(-24.0)
      end

      it 'returns float representation of a zero decimal' do
        @course.estimate = BigDecimal('0.0')
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive decimal' do
        @course.estimate = BigDecimal('24.35')
        @course['estimate'].should eql(24.35)
      end

      it 'returns float representation of a negative decimal' do
        @course.estimate = BigDecimal('-24.35')
        @course['estimate'].should eql(-24.35)
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.estimate = value
          @course['estimate'].should equal(value)
        end
      end
    end

    describe 'when type primitive is a Integer' do
      it 'returns same value if an integer' do
        value = 24
        @course.hours = value
        @course['hours'].should equal(value)
      end

      it 'returns integer representation of a zero string integer' do
        @course.hours = '0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string integer' do
        @course.hours = '24'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative string integer' do
        @course.hours = '-24'
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero string float' do
        @course.hours = '0.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string float' do
        @course.hours = '24.35'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative string float' do
        @course.hours = '-24.35'
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero string float, with no leading digits' do
        @course.hours = '.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string float, with no leading digits' do
        @course.hours = '.41'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a zero float' do
        @course.hours = 0.0
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive float' do
        @course.hours = 24.35
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative float' do
        @course.hours = -24.35
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero decimal' do
        @course.hours = '0.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive decimal' do
        @course.hours = '24.35'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative decimal' do
        @course.hours = '-24.35'
        @course['hours'].should eql(-24)
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.hours = value
          @course['hours'].should equal(value)
        end
      end
    end

    describe 'when type primitive is a BigDecimal' do
      it 'returns same value if a decimal' do
        value = BigDecimal('24.0')
        @course.profit = value
        @course['profit'].should equal(value)
      end

      it 'returns decimal representation of a zero string integer' do
        @course.profit = '0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string integer' do
        @course.profit = '24'
        @course['profit'].should eql(BigDecimal('24.0'))
      end

      it 'returns decimal representation of a negative string integer' do
        @course.profit = '-24'
        @course['profit'].should eql(BigDecimal('-24.0'))
      end

      it 'returns decimal representation of a zero string float' do
        @course.profit = '0.0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string float' do
        @course.profit = '24.35'
        @course['profit'].should eql(BigDecimal('24.35'))
      end

      it 'returns decimal representation of a negative string float' do
        @course.profit = '-24.35'
        @course['profit'].should eql(BigDecimal('-24.35'))
      end

      it 'returns decimal representation of a zero string float, with no leading digits' do
        @course.profit = '.0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string float, with no leading digits' do
        @course.profit = '.41'
        @course['profit'].should eql(BigDecimal('0.41'))
      end

      it 'returns decimal representation of a zero integer' do
        @course.profit = 0
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive integer' do
        @course.profit = 24
        @course['profit'].should eql(BigDecimal('24.0'))
      end

      it 'returns decimal representation of a negative integer' do
        @course.profit = -24
        @course['profit'].should eql(BigDecimal('-24.0'))
      end

      it 'returns decimal representation of a zero float' do
        @course.profit = 0.0
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive float' do
        @course.profit = 24.35
        @course['profit'].should eql(BigDecimal('24.35'))
      end

      it 'returns decimal representation of a negative float' do
        @course.profit = -24.35
        @course['profit'].should eql(BigDecimal('-24.35'))
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.profit = value
          @course['profit'].should equal(value)
        end
      end
    end

    describe 'when type primitive is a DateTime' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a DateTime instance from hash values' do
          @course.updated_at = {
            :year  => '2006',
            :month => '11',
            :day   => '23',
            :hour  => '12',
            :min   => '0',
            :sec   => '0'
          }
          result = @course['updated_at']

          result.should be_kind_of(DateTime)
          result.year.should eql(2006)
          result.month.should eql(11)
          result.day.should eql(23)
          result.hour.should eql(12)
          result.min.should eql(0)
          result.sec.should eql(0)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          @course.updated_at = 'Dec, 2006'
          @course['updated_at'].month.should == 12
        end
      end

      it 'does not typecast non-datetime values' do
        @course.updated_at = 'not-datetime'
        @course['updated_at'].should eql('not-datetime')
      end
    end

    describe 'when type primitive is a Date' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a Date instance from hash values' do
          @course.started_on = {
            :year  => '2007',
            :month => '3',
            :day   => '25'
          }
          result = @course['started_on']

          result.should be_kind_of(Date)
          result.year.should eql(2007)
          result.month.should eql(3)
          result.day.should eql(25)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          @course.started_on = 'Dec 20th, 2006'
          @course.started_on.month.should == 12
          @course.started_on.day.should == 20
          @course.started_on.year.should == 2006
        end
      end

      it 'does not typecast non-date values' do
        @course.started_on = 'not-date'
        @course['started_on'].should eql('not-date')
      end
    end

    describe 'when type primitive is a Time' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a Time instance from hash values' do
          @course.ends_at = {
            :year  => '2006',
            :month => '11',
            :day   => '23',
            :hour  => '12',
            :min   => '0',
            :sec   => '0'
          }
          result = @course['ends_at']

          result.should be_kind_of(Time)
          result.year.should  eql(2006)
          result.month.should eql(11)
          result.day.should   eql(23)
          result.hour.should  eql(12)
          result.min.should   eql(0)
          result.sec.should   eql(0)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          @course.ends_at = '22:24'
          @course['ends_at'].hour.should eql(22)
          @course['ends_at'].min.should eql(24)
        end
      end

      it 'does not typecast non-time values' do
        pending 'Time#parse is too permissive'
        @course.started_on = 'not-time'
        @course['ends_at'].should eql('not-time')
      end
    end

    describe 'when type primitive is a Class' do
      it 'returns same value if a class' do
        value = Course
        @course.klass = value
        @course['klass'].should equal(value)
      end

      it 'returns the class if found' do
        @course.klass = 'Course'
        @course['klass'].should eql(Course)
      end

      it 'does not typecast non-class values' do
        @course.klass = 'NoClass'
        @course['klass'].should eql('NoClass')
      end
    end
    
    describe 'when type primitive is a Boolean' do
      [ true, 'true', 'TRUE', '1', 1, 't', 'T' ].each do |value|
        it "returns true when value is #{value.inspect}" do
          @course.active = value
          @course['active'].should be_true
        end
      end

      [ false, 'false', 'FALSE', '0', 0, 'f', 'F' ].each do |value|
        it "returns false when value is #{value.inspect}" do
          @course.active = value
          @course['active'].should be_false
        end
      end

      [ 'string', 2, 1.0, BigDecimal('1.0'), DateTime.now, Time.now, Date.today, Class, Object.new, ].each do |value|
        it "does not typecast value #{value.inspect}" do
          @course.active = value
          @course['active'].should equal(value)
        end
      end
    end
  end
end
