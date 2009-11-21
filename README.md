# CouchRest: CouchDB, close to the metal

CouchRest is based on [CouchDB's couch.js test
library](http://svn.apache.org/repos/asf/couchdb/trunk/share/www/script/couch.js),
which I find to be concise, clear, and well designed. CouchRest lightly wraps
CouchDB's HTTP API, managing JSON serialization, and remembering the URI-paths
to CouchDB's API endpoints so you don't have to.

CouchRest is designed to make a simple base for application and framework-specific object oriented APIs. CouchRest is Object-Mapper agnostic, the parsed JSON it returns from CouchDB shows up as subclasses of Ruby's Hash. Naked JSON, just as it was mean to be.

Note: CouchRest only support CouchDB 0.9.0 or newer.

## Easy Install

    $ sudo gem install couchrest
   
Alternatively, you can install from Github:
    
    $ gem sources -a http://gems.github.com (you only have to do this once)
    $ sudo gem install couchrest-couchrest

### Relax, it's RESTful

CouchRest rests on top of a HTTP abstraction layer using by default Heroku’s excellent REST Client Ruby HTTP wrapper.
Other adapters can be added to support more http libraries.

### Running the Specs

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory run `rake`, or `autotest`
(requires RSpec and optionally ZenTest for autotest support).

## Examples (CouchRest Core)

Quick Start:

    # with !, it creates the database if it doesn't already exist
    @db = CouchRest.database!("http://127.0.0.1:5984/couchrest-test")
    response = @db.save_doc({:key => 'value', 'another key' => 'another value'})
    doc = @db.get(response['id'])
    puts doc.inspect

Bulk Save:

    @db.bulk_save([
        {"wild" => "and random"},
        {"mild" => "yet local"},
        {"another" => ["set","of","keys"]}
      ])
    # returns ids and revs of the current docs
    puts @db.documents.inspect 

Creating and Querying Views:

    @db.save_doc({
      "_id" => "_design/first", 
      :views => {
        :test => {
          :map => "function(doc){for(var w in doc){ if(!w.match(/^_/))emit(w,doc[w])}}"
          }
        }
      })
    puts @db.view('first/test')['rows'].inspect 


## CouchRest::ExtendedDocument  

CouchRest::ExtendedDocument is a DSL/ORM for CouchDB. Basically, ExtendedDocument seats on top of CouchRest Core to add the concept of Model.
ExtendedDocument offers a lot of the usual ORM tools such as optional yet defined schema, validation, callbacks, pagination, casting and much more.

### Model example

Check spec/couchrest/more and spec/fixtures/more for more examples

    class Article < CouchRest::ExtendedDocument
      use_database DB
      unique_id :slug

      view_by :date, :descending => true
      view_by :user_id, :date

      view_by :tags,
        :map => 
          "function(doc) {
            if (doc['couchrest-type'] == 'Article' && doc.tags) {
              doc.tags.forEach(function(tag){
                emit(tag, 1);
              });
            }
          }",
        :reduce => 
          "function(keys, values, rereduce) {
            return sum(values);
          }"  

      property :date
      property :slug, :read_only => true
      property :title
      property :tags, :cast_as => ['String']

      timestamps!

      save_callback :before, :generate_slug_from_title

      def generate_slug_from_title
        self['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'') if new?
      end
    end

### Callbacks

`CouchRest::ExtendedDocuments` instances have 4 callbacks already defined for you:
    `:validate`, `:create`, `:save`, `:update` and `:destroy`
    
`CouchRest::CastedModel` instances have 1 callback already defined for you:
    `:validate`
    
Define your callback as follows:

    set_callback :save, :before, :generate_slug_from_name
    
CouchRest uses a mixin you can find in lib/mixins/callbacks which is extracted from Rails 3, here are some simple usage examples:

    set_callback :save, :before, :before_method
    set_callback :save, :after,  :after_method, :if => :condition
    set_callback :save, :around {|r| stuff; yield; stuff }
    
    Or the aliased short version:
    
    before_save :before_method, :another_method
    after_save  :after_method, :another_method, :if => :condition
    around_save {|r| stuff; yield; stuff }
    
To halt the callback, simply return a :halt symbol in your callback method.
    
Check the mixin or the ExtendedDocument class to see how to implement your own callbacks.

### Properties

    property :last_name,        :alias     => :family_name
    property :read_only_value,  :read_only => true
    property :name,             :length    => 4...20
    property :price,            :type      => Integer
    
Attribute protection from mass assignment to CouchRest properties. There are two modes of protection:

1) Declare accessible properties, assume all the rest are protected 
    property :name,       :accessible => true
    property :admin       # this will be automatically protected

2) Declare protected properties, assume all the rest are accessible
    property :name        # this will not be protected
    property :admin,      :protected => true

Note: you cannot set both flags in a single class

### Casting

Often, you will want to store multiple objects within a document, to be able to retrieve your objects when you load the document, 
you can define some casting rules. 

    property :casted_attribute, :cast_as => 'WithCastedModelMixin'
    property :keywords,         :cast_as => ["String"]
    property :occurs_at,        :cast_as => 'Time', :init_method => 'parse
    property :end_date,         :cast_as => 'Date', :init_method => 'parse

If you want to cast an array of instances from a specific Class, use the trick shown above ["ClassName"]

### Pagination

Pagination is available in any ExtendedDocument classes. Here are some usage examples:

basic usage:

    Article.all.paginate(:page => 1, :per_page => 5)
    
note: the above query will look like: `GET /db/_design/Article/_view/all?include_docs=true&skip=0&limit=5&reduce=false` and only fetch 5 documents. 
    
Slightly more advance usage:
  
    Article.by_name(:startkey => 'a', :endkey => {}).paginate(:page => 1, :per_page => 5)
    
note: the above query will look like: `GET /db/_design/Article/_view/by_name?startkey=%22a%22&limit=5&skip=0&endkey=%7B%7D&include_docs=true`    
Basically, you can paginate through the articles starting by the letter a, 5 articles at a time.


Low level usage:        

    Article.paginate(:design_doc => 'Article', :view_name => 'by_date',
      :per_page => 3, :page => 2, :descending => true, :key => Date.today, :include_docs => true)
      
## Ruby on Rails

CouchRest is compatible with rails and can even be used a Rails plugin.
However, you might be interested in the CouchRest companion rails project:
[http://github.com/hpoydar/couchrest-rails](http://github.com/hpoydar/couchrest-rails)      
