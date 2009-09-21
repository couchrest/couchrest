require File.expand_path('../../../spec_helper', __FILE__)

describe "ExtendedDocument attachments" do
  
  describe "#has_attachment?" do
    before(:each) do
      reset_test_db!
      @obj = Basic.new
      @obj.save.should == true
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
    end
  
    it 'should return false if there is no attachment' do
      @obj.has_attachment?('bogus').should be_false
    end
  
    it 'should return true if there is an attachment' do
      @obj.has_attachment?(@attachment_name).should be_true
    end
  
    it 'should return true if an object with an attachment is reloaded' do
      @obj.save.should be_true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj.has_attachment?(@attachment_name).should be_true
    end
  
    it 'should return false if an attachment has been removed' do
      @obj.delete_attachment(@attachment_name)
      @obj.has_attachment?(@attachment_name).should be_false
    end
  end

  describe "creating an attachment" do
    before(:each) do
      @obj = Basic.new
      @obj.save.should == true
      @file_ext = File.open(FIXTURE_PATH + '/attachments/test.html')
      @file_no_ext = File.open(FIXTURE_PATH + '/attachments/README')
      @attachment_name = 'my_attachment'
      @content_type = 'media/mp3'
    end
  
    it "should create an attachment from file with an extension" do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name)
      @obj.save.should == true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj['_attachments'][@attachment_name].should_not be_nil
    end
  
    it "should create an attachment from file without an extension" do
      @obj.create_attachment(:file => @file_no_ext, :name => @attachment_name)
      @obj.save.should == true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj['_attachments'][@attachment_name].should_not be_nil
    end
  
    it 'should raise ArgumentError if :file is missing' do
      lambda{ @obj.create_attachment(:name => @attachment_name) }.should raise_error
    end
  
    it 'should raise ArgumentError if :name is missing' do
      lambda{ @obj.create_attachment(:file => @file_ext) }.should raise_error
    end
  
    it 'should set the content-type if passed' do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name, :content_type => @content_type)
      @obj['_attachments'][@attachment_name]['content_type'].should == @content_type
    end
  end

  describe 'reading, updating, and deleting an attachment' do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      @obj.save.should == true
      @file.rewind
      @content_type = 'media/mp3'
    end
  
    it 'should read an attachment that exists' do
      @obj.read_attachment(@attachment_name).should == @file.read
    end
  
    it 'should update an attachment that exists' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      @file.should_not == file
      @obj.update_attachment(:file => file, :name => @attachment_name)
      @obj.save
      reloaded_obj = Basic.get(@obj.id)
      file.rewind
      reloaded_obj.read_attachment(@attachment_name).should_not == @file.read
      reloaded_obj.read_attachment(@attachment_name).should == file.read
    end
  
    it 'should se the content-type if passed' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      @file.should_not == file
      @obj.update_attachment(:file => file, :name => @attachment_name, :content_type => @content_type)
      @obj['_attachments'][@attachment_name]['content_type'].should == @content_type
    end
  
    it 'should delete an attachment that exists' do
      @obj.delete_attachment(@attachment_name)
      @obj.save
      lambda{Basic.get(@obj.id).read_attachment(@attachment_name)}.should raise_error
    end
  end

  describe "#attachment_url" do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      @obj.save.should == true
    end
  
    it 'should return nil if attachment does not exist' do
      @obj.attachment_url('bogus').should be_nil
    end
  
    it 'should return the attachment URL as specified by CouchDB HttpDocumentApi' do
      @obj.attachment_url(@attachment_name).should == "#{Basic.database}/#{@obj.id}/#{@attachment_name}"
    end
    
    it 'should return the attachment URI' do
      @obj.attachment_uri(@attachment_name).should == "#{Basic.database.uri}/#{@obj.id}/#{@attachment_name}"
    end
    
  end
end
