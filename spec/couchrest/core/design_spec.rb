require File.dirname(__FILE__) + '/../../spec_helper'

describe CouchRest::Design do
  
  # before(:each) do
  #   @db = reset_test_db!
  # end
  
  describe "defining a view" do
    # before(:each) do
    #   @design_docs = @db.documents :startkey => "_design/", 
    #     :endkey => "_design/\u9999"
    # end
    it "should add a view to the design doc" do
      @des = CouchRest::Design.new
      method = @des.view_by :name
      method.should == "by_name"
      @des["views"]["by_name"].should_not be_nil
    end
    
  end
  
  describe "with an unsaved view" do
    before(:each) do
      @des = CouchRest::Design.new
      method = @des.view_by :name
    end
    it "should accept a slug" do
      @des.slug = "mytest"
      @des.slug.should == "mytest"
    end
    it "should not save on view definition" do
      @des.rev.should be_nil
    end
    it "should freak out on view access" do
      lambda{@des.view :by_name}.should raise_error
    end
  end
  
  describe "when it's saved" do
    before(:each) do
      @db = reset_test_db!
      @db.bulk_save([{"name" => "x"},{"name" => "y"}])
      @des = CouchRest::Design.new
      @des.database = @db
      method = @des.view_by :name
    end
    it "should become angry when saved without a slug" do
      lambda{@des.save}.should raise_error
    end
    it "should by queryable when it's saved" do
      @des.slug = "mydesign"
      @des.save
      res = @des.view :by_name
      res["rows"][0]["key"].should == "x"
    end
  end
  
  describe "from a saved document" do
    before(:all) do
      @db = reset_test_db!
      @db.save({
        "_id" => "_design/test",
        "views" => {
          "by_name" => {
            "map" => "function(doc){if (doc.name) emit(doc.name, null)}"
          }
        }
      })
      @db.bulk_save([{"name" => "a"},{"name" => "b"}])
      @des = @db.get "_design/test"
    end
    it "should be a Design" do
      @des.should be_an_instance_of CouchRest::Design
    end
    it "should have a slug" do
      @des.slug.should == "test"
      @des.slug = "supertest"
      @des.id.should == "_design/supertest"
    end
    it "should by queryable" do
      res = @des.view :by_name 
      res["rows"][0]["key"].should == "a"
    end
  end
end