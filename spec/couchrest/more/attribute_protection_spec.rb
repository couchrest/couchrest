require File.expand_path("../../../spec_helper", __FILE__)

describe "ExtendedDocument", "no declarations" do
  class NoProtection < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name
    property :phone
  end

  it "should not protect anything through new" do
    user = NoProtection.new(:name => "will", :phone => "555-5555")

    user.name.should == "will"
    user.phone.should == "555-5555"
  end

  it "should not protect anything through attributes=" do
    user = NoProtection.new
    user.attributes = {:name => "will", :phone => "555-5555"}

    user.name.should == "will"
    user.phone.should == "555-5555"
  end
  
  it "should recreate from the database properly" do
    user = NoProtection.new
    user.name = "will"
    user.phone = "555-5555"
    user.save!
    
    user = NoProtection.get(user.id)
    user.name.should == "will"
    user.phone.should == "555-5555"
  end
end

describe "ExtendedDocument", "accessible flag" do
  class WithAccessible < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name, :accessible => true
    property :admin, :default => false
  end

  it "should recognize accessible properties" do
    props = WithAccessible.accessible_properties.map { |prop| prop.name}
    props.should include("name")
    props.should_not include("admin")
  end

  it "should protect non-accessible properties set through new" do
    user = WithAccessible.new(:name => "will", :admin => true) 

    user.name.should == "will"
    user.admin.should == false
  end

  it "should protect non-accessible properties set through attributes=" do
    user = WithAccessible.new
    user.attributes = {:name => "will", :admin => true}

    user.name.should == "will"
    user.admin.should == false
  end
end

describe "ExtendedDocument", "protected flag" do
  class WithProtected < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name
    property :admin, :default => false, :protected => true
  end

  it "should recognize protected properties" do
    props = WithProtected.protected_properties.map { |prop| prop.name}
    props.should_not include("name")
    props.should include("admin")
  end

  it "should protect non-accessible properties set through new" do
    user = WithProtected.new(:name => "will", :admin => true) 

    user.name.should == "will"
    user.admin.should == false
  end

  it "should protect non-accessible properties set through attributes=" do
    user = WithProtected.new
    user.attributes = {:name => "will", :admin => true}

    user.name.should == "will"
    user.admin.should == false
  end
end

describe "ExtendedDocument", "protected flag" do
  class WithBoth < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name, :accessible => true
    property :admin, :default => false, :protected => true
  end

  it "should raise an error when both are set" do
    lambda { WithBoth.new }.should raise_error 
  end
end

describe "ExtendedDocument", "from database" do
  class WithProtected < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name
    property :admin, :default => false, :protected => true
    view_by :name
  end
  
  before(:each) do
    @user = WithProtected.new
    @user.name = "will"
    @user.admin = true
    @user.save!
  end

  def verify_attrs(user)
    user.name.should  == "will"
    user.admin.should == true
  end

  it "ExtendedDocument#get should not strip protected attributes" do
    reloaded = WithProtected.get( @user.id )
    verify_attrs reloaded 
  end

  it "ExtendedDocument#get! should not strip protected attributes" do
    reloaded = WithProtected.get!( @user.id )
    verify_attrs reloaded 
  end

  it "ExtendedDocument#all should not strip protected attributes" do
    # all creates a CollectionProxy
    docs = WithProtected.all(:key => @user.id)
    docs.size.should == 1
    reloaded = docs.first
    verify_attrs reloaded 
  end

  it "views should not strip protected attributes" do
    docs = WithProtected.by_name(:startkey => "will", :endkey => "will")
    reloaded = docs.first
    verify_attrs reloaded 
  end
end
