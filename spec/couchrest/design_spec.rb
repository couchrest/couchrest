require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Design do
  
  describe "defining a view" do
    it "should add a view to the design doc" do
      @des = CouchRest::Design.new
      method = @des.view_by :name
      expect(method).to eql "by_name"
      expect(@des["views"]["by_name"]).not_to be_nil
    end
  end
  
  describe "with an unsaved view" do
    before(:each) do
      @des = CouchRest::Design.new
      @des.view_by :name
    end
    it "should accept a name" do
      @des.name = "mytest"
      expect(@des.name).to eql "mytest"
    end
    it "should not save on view definition" do
      expect(@des.rev).to be_nil
    end
    it "should freak out on view access" do
      expect { @des.view :by_name }.to raise_error
    end
  end
  
  describe "saving" do
    before(:each) do
      @des = CouchRest::Design.new
      @des.view_by :name
      @des.database = reset_test_db!
    end
    it "should fail without a name" do
      expect(lambda{@des.save}).to raise_error(ArgumentError)
    end
    it "should work with a name" do
      @des.name = "myview"
      @des.save
    end
  end
  
  describe "when it's saved" do
    before(:each) do
      @db = reset_test_db!
      @db.bulk_save([{"name" => "x"},{"name" => "y"}])
      @des = CouchRest::Design.new
      @des.database = @db
      @des.view_by :name
    end
    it "should by queryable when it's saved" do
      @des.name = "mydesign"
      @des.save
      res = @des.view :by_name
      expect(res["rows"][0]["key"]).to eql "x"
    end
    it "should be queryable on specified database" do
      @des.name = "mydesign"
      @des.save
      @des.database = nil
      res = @des.view_on @db, :by_name
      expect(res["rows"][0]["key"]).to eql "x"
    end
  end
  
  describe "from a saved document" do
    before(:each) do
      @db = reset_test_db!
      @db.save_doc({
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
      expect(@des).to be_an_instance_of(CouchRest::Design)
    end
    it "should have a modifiable name" do
      expect(@des.name).to eql "test"
      @des.name = "supertest"
      expect(@des.id).to eql "_design/supertest"
    end
    it "should by queryable" do
      res = @des.view :by_name 
      expect(res["rows"][0]["key"]).to eql "a"
    end
  end
  
  describe "a view with default options" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :name, :descending => true
      @des.database = @db
      @des.save
      @db.bulk_save([{"name" => "a"},{"name" => "z"}])
    end
    it "should save them" do
      @d2 = @db.get(@des.id)
      expect(@d2["views"]["by_name"]["couchrest-defaults"]).to eql("descending" => true)
    end
    it "should use them" do
      res = @des.view :by_name
      expect(res["rows"].first["key"]).to eql "z"
    end
    it "should override them" do
      res = @des.view :by_name, :descending => false
      expect(res["rows"].first["key"]).to eql "a"
    end
  end
  
  describe "a view with multiple keys" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :name, :age
      @des.database = @db
      @des.save
      @db.bulk_save([{"name" => "a", "age" => 2},
        {"name" => "a", "age" => 4},{"name" => "z", "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_name_and_age
      expect(res["rows"].first["key"]).to eql ["a",2]
    end
  end

  describe "a view with nil and 0 values" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :code
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => nil, "age" => 4},{"code" => 0, "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_code
      expect(res["rows"][0]["key"]).to eql 0
      expect(res["rows"][1]["key"]).to eql "a"
      expect(res["rows"][2]).to be_nil
    end
  end

  describe "a view with nil and 0 values and :allow_nil" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :code, :allow_nil => true
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => nil, "age" => 4},{"code" => 0, "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_code
      expect(res["rows"][0]["key"]).to be_nil
      expect(res["rows"][1]["key"]).to eql 0
      expect(res["rows"][2]["key"]).to eql "a"
    end
  end


  describe "a view with a reduce function" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :code, :map => "function(d){ if(d['code']) { emit(d['code'], 1); } }", :reduce => "function(k,v,r){ return sum(v); }"
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => 'b', "age" => 4},{"code" => 'c', "age" => 9}])
    end
    it "should not set a default parameter" do
      expect(@des['views']['by_code']['couchrest-defaults']).to be_nil
    end
    it "should include reduce parameter in query" do
      # this would fail without it
      res = @des.view :by_code
      expect(res["rows"][0]["key"]).to eql 'a'
    end
    it "should allow reduce to be performed" do
      res = @des.view :by_code, :reduce => true
      expect(res["rows"][0]["value"]).to eql(3)
    end
    it "does not allow string keys to be passed to view as options" do
      expect(lambda{ @des.view :by_code, 'reduce' => true }).to raise_error(ArgumentError, /set as symbols/)
    end
  end

  describe "requesting info" do

    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new
      @des.name = "test"
      @des.view_by :code, :map => "function(d){ if(d['code']) { emit(d['code'], 1); } }", :reduce => "function(k,v,r){ return sum(v); }"
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => 'b', "age" => 4},{"code" => 'c', "age" => 9}])
    end

    it "should provide a summary info hash" do
      info = @des.info
      expect(info['name']).to eql("test")
      expect(info).to include("view_index")
    end

  end

end
