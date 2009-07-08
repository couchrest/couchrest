# CouchRest: CouchDB, close to the metal

CouchRest is based on [CouchDB's couch.js test
library](http://svn.apache.org/repos/asf/couchdb/trunk/share/www/script/couch.js),
which I find to be concise, clear, and well designed. CouchRest lightly wraps
CouchDB's HTTP API, managing JSON serialization, and remembering the URI-paths
to CouchDB's API endpoints so you don't have to.

CouchRest is designed to make a simple base for application and framework-specific object oriented APIs. CouchRest is Object-Mapper agnostic, the parsed JSON it returns from CouchDB shows up as subclasses of Ruby's Hash. Naked JSON, just as it was mean to be.

Note: CouchRest only support CouchDB 0.9.0 or newer.

## Easy Install

Easy Install is moving to RubyForge, heads up for the gem.

### Relax, it's RESTful

The core of Couchrest is Heroku’s excellent REST Client Ruby HTTP wrapper.
REST Client takes all the nastyness of Net::HTTP and gives is a pretty face,
while still giving you more control than Open-URI. I recommend it anytime
you’re interfacing with a well-defined web service.

### Running the Specs

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory run `rake`, or `autotest`
(requires RSpec and optionally ZenTest for autotest support).

## Examples

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

## CouchRest::Model

CouchRest::Model has been deprecated and replaced by CouchRest::ExtendedDocument


## CouchRest::ExtendedDocument

### Callbacks

`CouchRest::ExtendedDocuments` instances have 2 callbacks already defined for you:
    `create_callback`, `save_callback`, `update_callback` and `destroy_callback`
    
In your document inherits from `CouchRest::ExtendedDocument`, define your callback as follows:

    save_callback :before, :generate_slug_from_name
    
CouchRest uses a mixin you can find in lib/mixins/callbacks which is extracted from Rails 3, here are some simple usage examples:

    save_callback :before, :before_method
    save_callback :after,  :after_method, :if => :condition
    save_callback :around {|r| stuff; yield; stuff }
    
Check the mixin or the ExtendedDocument class to see how to implement your own callbacks.

### Casting

Often, you will want to store multiple objects within a document, to be able to retrieve your objects when you load the document, 
you can define some casting rules. 

    property :casted_attribute, :cast_as => 'WithCastedModelMixin'
    property :keywords,         :cast_as => ["String"]

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