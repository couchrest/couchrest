require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::Design do
  
  shared_examples_for "defining a view" do
    it "should add a view to the design doc" do
      method = @des.view_by :name
      method.should == "by_name"
      @des["views"]["by_name"].should_not be_nil
    end
  end
  
  shared_examples_for "with an unsaved view" do
    before(:each) do
      @des.view_by :name
    end
    it "should accept a name" do
      @des.name = "mytest"
      @des.name.should == "mytest"
    end
    it "should not save on view definition" do
      @des.rev.should be_nil
    end
    it "should freak out on view access" do
      lambda{@des.view :by_name}.should raise_error
    end
  end
  
  shared_examples_for "saving" do
    before(:each) do
      @des.view_by :name
      @des.database = reset_test_db!
    end
    it "should fail without a name" do
      lambda{@des.save}.should raise_error(ArgumentError)
    end
    it "should work with a name" do
      @des.name = "myview"
      @des.save
    end
  end
  
  shared_examples_for "when it's saved" do
    before(:each) do
      @db = reset_test_db!
      @db.bulk_save([{"name" => "x"},{"name" => "y"}])
      @des.database = @db
      @des.view_by :name
    end
    it "should by queryable when it's saved" do
      @des.name = "mydesign"
      @des.save
      res = @des.view :by_name
      res["rows"][0]["key"].should == "x"
    end
    it "should be queryable on specified database" do
      @des.name = "mydesign"
      @des.save
      @des.database = nil
      res = @des.view_on @db, :by_name
      res["rows"][0]["key"].should == "x"
    end
  end
  
  shared_examples_for "from a saved document" do
    it "should be a Design" do
      @des.should be_an_instance_of(CouchRest::Design)
    end
    it "should have a modifiable name" do
      @des.name.should == "test"
      @des.name = "supertest"
      @des.id.should == "_design/supertest"
    end
    it "should by queryable" do
      res = @des.view :by_name 
      res["rows"][0]["key"].should == "a"
    end
  end
  
  describe "from a saved javascript document" do
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
    
    it_should_behave_like "from a saved document"
  end
  
  describe "from a saved erlang document" do
    before(:each) do
      @db = reset_test_db!
      @db.save_doc({
        "_id" => "_design/test",
        "language" => "erlang",
        "views" => {
          "by_name" => {
            "map" => "fun({Doc}) -> Name = couch_util:get_value(<<\"name\">>, Doc), if (Name /= null) -> Emit(Name, null); true -> ok end end."
          }
        }
      })
      @db.bulk_save([{"name" => "a"},{"name" => "b"}])
      @des = @db.get "_design/test"
    end
    
    it_should_behave_like "from a saved document"
  end  
  
  shared_examples_for "a view with default options" do
    before(:each) do
      @db = reset_test_db!
      @des.name = "test"
      @des.view_by :name, :descending => true
      @des.database = @db
      @des.save
      @db.bulk_save([{"name" => "a"},{"name" => "z"}])
    end
    it "should save them" do
      @d2 = @db.get(@des.id)
      @d2["views"]["by_name"]["couchrest-defaults"].should == {"descending"=>true}
    end
    it "should use them" do
      res = @des.view :by_name
      res["rows"].first["key"].should == "z"
    end
    it "should override them" do
      res = @des.view :by_name, :descending => false
      res["rows"].first["key"].should == "a"
    end
  end
  
  shared_examples_for "a view with multiple keys" do
    before(:each) do
      @db = reset_test_db!
      @des.name = "test"
      @des.view_by :name, :age
      @des.database = @db
      @des.save
      @db.bulk_save([{"name" => "a", "age" => 2},
        {"name" => "a", "age" => 4},{"name" => "z", "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_name_and_age
      res["rows"].first["key"].should == ["a",2]
    end
  end
  
  shared_examples_for "a view with nil and 0 values" do
    before(:each) do
      @db = reset_test_db!
      @des.name = "test"
      @des.view_by :code
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => nil, "age" => 4},{"code" => 0, "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_code
      res["rows"][0]["key"].should == 0
      res["rows"][1]["key"].should == "a"
      res["rows"][2].should be_nil
    end
  end
  
  shared_examples_for "a view with nil and 0 values and :allow_nil" do
    before(:each) do
      @db = reset_test_db!
      @des.name = "test"
      @des.view_by :code, :allow_nil => true
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => nil, "age" => 4},{"code" => 0, "age" => 9}])
    end
    it "should work" do
      res = @des.view :by_code
      res["rows"][0]["key"].should == nil
      res["rows"][1]["key"].should == 0
      res["rows"][2]["key"].should == "a"
    end
  end
  
  describe "javascript" do
    before(:each) do
      @des = CouchRest::Design.new
    end
    
    it_should_behave_like "defining a view"
    it_should_behave_like "with an unsaved view"
    it_should_behave_like "saving"
    it_should_behave_like "when it's saved"
    it_should_behave_like "a view with default options"
    it_should_behave_like "a view with multiple keys"
    it_should_behave_like "a view with nil and 0 values"
    it_should_behave_like "a view with nil and 0 values and :allow_nil"
  end
  
  describe "erlang" do
    before(:each) do
      @des = CouchRest::Design.new(:language => :erlang)
    end
    
    it_should_behave_like "defining a view"
    it_should_behave_like "with an unsaved view"
    it_should_behave_like "saving"
    it_should_behave_like "when it's saved"
    it_should_behave_like "a view with default options"
    it_should_behave_like "a view with multiple keys"
    it_should_behave_like "a view with nil and 0 values"
    it_should_behave_like "a view with nil and 0 values and :allow_nil"
  end

  shared_examples_for "a view with a reduce function" do    
    it "should not set a default parameter" do
      @des['views']['by_code']['couchrest-defaults'].should be_nil
    end
    it "should include reduce parameter in query" do
      # this would fail without it
      res = @des.view :by_code
      res["rows"][0]["key"].should == 'a'
    end
    it "should allow reduce to be performed" do
      res = @des.view :by_code, :reduce => true
      res["rows"][0]["value"].should eql(3)
    end
    it "does not allow string keys to be passed to view as options" do
      lambda{ @des.view :by_code, 'reduce' => true }.should raise_error(ArgumentError, /set as symbols/)
    end
  end

  describe "a view with a javascript reduce function" do
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
    
    it_should_behave_like "a view with a reduce function"
  end
  
  describe "a view with an erlang reduce function" do
    before(:all) do
      @db = reset_test_db!
      @des = CouchRest::Design.new(:language => :erlang)
      @des.name = "test"
      @des.view_by :code, :map => "fun({Doc}) -> Code = couch_util:get_value(<<\"code\">>, Doc), if (Code /= null) -> Emit(Code, 1); true -> ok end end.", :reduce => "fun(Keys, Values, ReReduce) -> lists:sum(Values) end."
      @des.database = @db
      @des.save
      @db.bulk_save([{"code" => "a", "age" => 2},
        {"code" => 'b', "age" => 4},{"code" => 'c', "age" => 9}])
    end
    
    it_should_behave_like "a view with a reduce function"
  end

end
