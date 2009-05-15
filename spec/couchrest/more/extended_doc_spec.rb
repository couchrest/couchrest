require File.dirname(__FILE__) + '/../../spec_helper'
require File.join(FIXTURE_PATH, 'more', 'article')
require File.join(FIXTURE_PATH, 'more', 'course')


describe "ExtendedDocument" do
  
  class WithDefaultValues < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :preset,       :default => {:right => 10, :top_align => false}
    property :set_by_proc,  :default => Proc.new{Time.now},       :cast_as => 'Time'
    property :tags,         :default => []
    property :read_only_with_default, :default => 'generic', :read_only => true
    property :name
    timestamps!
  end
  
  class WithCallBacks < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    property :name
    property :run_before_save
    property :run_after_save
    property :run_before_create
    property :run_after_create
    property :run_before_update
    property :run_after_update
    
    save_callback :before do |object| 
      object.run_before_save = true
    end
    save_callback :after do |object| 
      object.run_after_save = true
    end
    create_callback :before do |object| 
      object.run_before_create = true
    end
    create_callback :after do |object| 
      object.run_after_create = true
    end
    update_callback :before do |object| 
      object.run_before_update = true
    end
    update_callback :after do |object| 
      object.run_after_update = true
    end
  end
  
  class WithTemplateAndUniqueID < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    unique_id do |model|
      model['important-field']
    end
    property :preset, :default => 'value'
    property :has_no_default
  end

  class WithGetterAndSetterMethods < CouchRest::ExtendedDocument
    use_database TEST_SERVER.default_database
    
    property :other_arg
    def arg
      other_arg
    end

    def arg=(value)
      self.other_arg = "foo-#{value}"
    end
  end
  
  before(:each) do
    @obj = WithDefaultValues.new
  end
  
  describe "instance database connection" do
    it "should use the default database" do
      @obj.database.name.should == 'couchrest-test'
    end
    
    it "should override the default db" do
      @obj.database = TEST_SERVER.database!('couchrest-extendedmodel-test')
      @obj.database.name.should == 'couchrest-extendedmodel-test'
      @obj.database.delete!
    end
  end
  
  describe "a new model" do
    it "should be a new_record" do
      @obj = Basic.new
      @obj.rev.should be_nil
      @obj.should be_a_new_record
    end
    it "should be a new_document" do
      @obj = Basic.new
      @obj.rev.should be_nil
      @obj.should be_a_new_document
    end
  end
  
  describe "update attributes without saving" do
    before(:each) do
      a = Article.get "big-bad-danger" rescue nil
      a.destroy if a
      @art = Article.new(:title => "big bad danger")
      @art.save
    end
    it "should work for attribute= methods" do
      @art['title'].should == "big bad danger"
      @art.update_attributes_without_saving('date' => Time.now, :title => "super danger")
      @art['title'].should == "super danger"
    end
    
    it "should flip out if an attribute= method is missing" do
      lambda {
        @art.update_attributes_without_saving('slug' => "new-slug", :title => "super danger")        
      }.should raise_error
    end
    
    it "should not change other attributes if there is an error" do
      lambda {
        @art.update_attributes_without_saving('slug' => "new-slug", :title => "super danger")        
      }.should raise_error
      @art['title'].should == "big bad danger"
    end
  end
  
  describe "update attributes" do
    before(:each) do
      a = Article.get "big-bad-danger" rescue nil
      a.destroy if a
      @art = Article.new(:title => "big bad danger")
      @art.save
    end
    it "should save" do
      @art['title'].should == "big bad danger"
      @art.update_attributes('date' => Time.now, :title => "super danger")
      loaded = Article.get(@art.id)
      loaded['title'].should == "super danger"
    end
  end
  
  describe "with default" do
    it "should have the default value set at initalization" do
      @obj.preset.should == {:right => 10, :top_align => false}
    end
    
    it "should automatically call a proc default at initialization" do
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.set_by_proc.should == @obj.set_by_proc
      @obj.set_by_proc.should < Time.now
    end
    
    it "should let you overwrite the default values" do
      obj = WithDefaultValues.new(:preset => 'test')
      obj.preset = 'test'
    end
    
    it "should work with a default empty array" do
      obj = WithDefaultValues.new(:tags => ['spec'])
      obj.tags.should == ['spec']
    end
    
    it "should set default value of read-only property" do
      obj = WithDefaultValues.new
      obj.read_only_with_default.should == 'generic'
    end
  end
  
  describe "a doc with template values (CR::Model spec)" do
    before(:all) do
      WithTemplateAndUniqueID.all.map{|o| o.destroy(true)}
      WithTemplateAndUniqueID.database.bulk_delete
      @tmpl = WithTemplateAndUniqueID.new
      @tmpl2 = WithTemplateAndUniqueID.new(:preset => 'not_value', 'important-field' => '1')
    end
    it "should have fields set when new" do
      @tmpl.preset.should == 'value'
    end
    it "shouldn't override explicitly set values" do
      @tmpl2.preset.should == 'not_value'
    end
    it "shouldn't override existing documents" do
      @tmpl2.save
      tmpl2_reloaded = WithTemplateAndUniqueID.get(@tmpl2.id)
      @tmpl2.preset.should == 'not_value'
      tmpl2_reloaded.preset.should == 'not_value'
    end
  end
  
  describe "getting a model" do
    before(:all) do
      @art = Article.new(:title => 'All About Getting')
      @art.save
    end
    it "should load and instantiate it" do
      foundart = Article.get @art.id
      foundart.title.should == "All About Getting"
    end
  end

  describe "getting a model with a subobjects array" do
    before(:all) do
      course_doc = {
        "title" => "Metaphysics 200",
        "questions" => [
          {
            "q" => "Carve the ___ of reality at the ___.",
            "a" => ["beast","joints"]
          },{
            "q" => "Who layed the smack down on Leibniz's Law?",
            "a" => "Willard Van Orman Quine"
          }
        ]
      }
      r = Course.database.save_doc course_doc
      @course = Course.get r['id']
    end
    it "should load the course" do
      @course.title.should == "Metaphysics 200"
    end
    it "should instantiate them as such" do
      @course["questions"][0].a[0].should == "beast"
    end
  end
  
  describe "finding all instances of a model" do
    before(:all) do
      WithTemplateAndUniqueID.all.map{|o| o.destroy(true)}
      WithTemplateAndUniqueID.database.bulk_delete
      WithTemplateAndUniqueID.new('important-field' => '1').save
      WithTemplateAndUniqueID.new('important-field' => '2').save
      WithTemplateAndUniqueID.new('important-field' => '3').save
      WithTemplateAndUniqueID.new('important-field' => '4').save
    end
    it "should make the design doc" do
      WithTemplateAndUniqueID.all
      d = WithTemplateAndUniqueID.design_doc
      d['views']['all']['map'].should include('WithTemplateAndUniqueID')
    end
    it "should find all" do
      rs = WithTemplateAndUniqueID.all 
      rs.length.should == 4
    end
  end

  describe "finding the first instance of a model" do
    before(:each) do      
      @db = reset_test_db!
      WithTemplateAndUniqueID.new('important-field' => '1').save
      WithTemplateAndUniqueID.new('important-field' => '2').save
      WithTemplateAndUniqueID.new('important-field' => '3').save
      WithTemplateAndUniqueID.new('important-field' => '4').save
    end
    it "should make the design doc" do
      WithTemplateAndUniqueID.all
      d = WithTemplateAndUniqueID.design_doc
      d['views']['all']['map'].should include('WithTemplateAndUniqueID')
    end
    it "should find first" do
      rs = WithTemplateAndUniqueID.first
      rs['important-field'].should == "1"
    end
    it "should return nil if no instances are found" do
      WithTemplateAndUniqueID.all.each {|obj| obj.destroy }
      WithTemplateAndUniqueID.first.should be_nil
    end
  end
  
  describe "getting a model with a subobject field" do
    before(:all) do
      course_doc = {
        "title" => "Metaphysics 410",
        "professor" => {
          "name" => ["Mark", "Hinchliff"]
        },
        "final_test_at" => "2008/12/19 13:00:00 +0800"
      }
      r = Course.database.save_doc course_doc
      @course = Course.get r['id']
    end
    it "should load the course" do
      @course["professor"]["name"][1].should == "Hinchliff"
    end
    it "should instantiate the professor as a person" do
      @course['professor'].last_name.should == "Hinchliff"
    end
    it "should instantiate the final_test_at as a Time" do
      @course['final_test_at'].should == Time.parse("2008/12/19 13:00:00 +0800")
    end
  end
  
  describe "timestamping" do
    before(:each) do
      oldart = Article.get "saving-this" rescue nil
      oldart.destroy if oldart
      @art = Article.new(:title => "Saving this")
      @art.save
    end
    
    it "should define the updated_at and created_at getters and set the values" do
      @obj.save
      obj = WithDefaultValues.get(@obj.id)
      obj.should be_an_instance_of(WithDefaultValues)
      obj.created_at.should be_an_instance_of(Time)
      obj.updated_at.should be_an_instance_of(Time)
      obj.created_at.to_s.should == @obj.updated_at.to_s
    end 
    it "should set the time on create" do
      (Time.now - @art.created_at).should < 2
      foundart = Article.get @art.id
      foundart.created_at.should == foundart.updated_at
    end
    it "should set the time on update" do
      @art.save
      @art.created_at.should < @art.updated_at
    end
  end
  
  describe "basic saving and retrieving" do
    it "should work fine" do
      @obj.name = "should be easily saved and retrieved"
      @obj.save
      saved_obj = WithDefaultValues.get(@obj.id)
      saved_obj.should_not be_nil
    end
    
    it "should parse the Time attributes automatically" do
      @obj.name = "should parse the Time attributes automatically"
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.save
      @obj.set_by_proc.should be_an_instance_of(Time)
      saved_obj = WithDefaultValues.get(@obj.id)
      saved_obj.set_by_proc.should be_an_instance_of(Time)
    end
  end
  
  describe "saving a model" do
    before(:all) do
      @sobj = Basic.new
      @sobj.save.should == true
    end
    
    it "should save the doc" do
      doc = Basic.get(@sobj.id)
      doc['_id'].should == @sobj.id
    end
    
    it "should be set for resaving" do
      rev = @obj.rev
      @sobj['another-key'] = "some value"
      @sobj.save
      @sobj.rev.should_not == rev
    end
    
    it "should set the id" do
      @sobj.id.should be_an_instance_of(String)
    end
    
    it "should set the type" do
      @sobj['couchrest-type'].should == 'Basic'
    end
  end
  
  describe "saving a model with a unique_id configured" do
    before(:each) do
      @art = Article.new
      @old = Article.database.get('this-is-the-title') rescue nil
      Article.database.delete_doc(@old) if @old
    end
    
    it "should be a new document" do
      @art.should be_a_new_document
      @art.title.should be_nil
    end
    
    it "should require the title" do
      lambda{@art.save}.should raise_error
      @art.title = 'This is the title'
      @art.save.should == true
    end
    
    it "should not change the slug on update" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.title = 'new title'
      @art.save.should == true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should raise an error when the slug is taken" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art2 = Article.new(:title => 'This is the title!')
      lambda{@art2.save}.should raise_error
    end
    
    it "should set the slug" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should set the id" do
      @art.title = 'This is the title'
      @art.save.should == true
      @art.id.should == 'this-is-the-title'
    end
  end

  describe "saving a model with a unique_id lambda" do
    before(:each) do
      @templated = WithTemplateAndUniqueID.new
      @old = WithTemplateAndUniqueID.get('very-important') rescue nil
      @old.destroy if @old
    end
    
    it "should require the field" do
      lambda{@templated.save}.should raise_error
      @templated['important-field'] = 'very-important'
      @templated.save.should == true
    end
    
    it "should save with the id" do
      @templated['important-field'] = 'very-important'
      @templated.save.should == true
      t = WithTemplateAndUniqueID.get('very-important')
      t.should == @templated
    end
    
    it "should not change the id on update" do
      @templated['important-field'] = 'very-important'
      @templated.save.should == true
      @templated['important-field'] = 'not-important'
      @templated.save.should == true
      t = WithTemplateAndUniqueID.get('very-important')
      t.should == @templated
    end
    
    it "should raise an error when the id is taken" do
      @templated['important-field'] = 'very-important'
      @templated.save.should == true
      lambda{WithTemplateAndUniqueID.new('important-field' => 'very-important').save}.should raise_error
    end
    
    it "should set the id" do
      @templated['important-field'] = 'very-important'
      @templated.save.should == true
      @templated.id.should == 'very-important'
    end
  end
  
  describe "destroying an instance" do
    before(:each) do
      @dobj = Basic.new
      @dobj.save.should == true
    end
    it "should return true" do
      result = @dobj.destroy
      result.should == true
    end
    it "should be resavable" do
      @dobj.destroy
      @dobj.rev.should be_nil
      @dobj.id.should be_nil
      @dobj.save.should == true 
    end
    it "should make it go away" do
      @dobj.destroy
      lambda{Basic.get(@dobj.id)}.should raise_error
    end
  end
  
  
  describe "callbacks" do
    
    before(:each) do
      @doc = WithCallBacks.new
    end
    
    describe "save" do
      it "should run the after filter after saving" do
        @doc.run_after_save.should be_nil
        @doc.save.should be_true
        @doc.run_after_save.should be_true
      end
    end
    describe "create" do
      it "should run the before save filter when creating" do
        @doc.run_before_save.should be_nil
        @doc.create.should_not be_nil
        @doc.run_before_save.should be_true
      end
      it "should run the before create filter" do
        @doc.run_before_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_before_create.should be_true
      end
      it "should run the after create filter" do
        @doc.run_after_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_after_create.should be_true
      end
    end
    describe "update" do
      
      before(:each) do
        @doc.save
      end      
      it "should run the before update filter when updating an existing document" do
        @doc.run_before_update.should be_nil
        @doc.update
        @doc.run_before_update.should be_true
      end
      it "should run the after update filter when updating an existing document" do
        @doc.run_after_update.should be_nil
        @doc.update
        @doc.run_after_update.should be_true
      end
      it "should run the before update filter when saving an existing document" do
        @doc.run_before_update.should be_nil
        @doc.save
        @doc.run_before_update.should be_true
      end
      
    end
  end

  describe "getter and setter methods" do
    it "should try to call the arg= method before setting :arg in the hash" do
      @doc = WithGetterAndSetterMethods.new(:arg => "foo")
      @doc['arg'].should be_nil
      @doc[:arg].should be_nil
      @doc.other_arg.should == "foo-foo"
    end
  end
end
