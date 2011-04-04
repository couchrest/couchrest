# CouchRest: CouchDB, close to the metal

CouchRest is based on [CouchDB's couch.js test
library](http://svn.apache.org/repos/asf/couchdb/trunk/share/www/script/couch.js),
which I find to be concise, clear, and well designed. CouchRest lightly wraps
CouchDB's HTTP API, managing JSON serialization, and remembering the URI-paths
to CouchDB's API endpoints so you don't have to.

CouchRest is designed to make a simple base for application and framework-specific object oriented APIs. CouchRest is Object-Mapper agnostic, the parsed JSON it returns from CouchDB shows up as subclasses of Ruby's Hash. Naked JSON, just as it was mean to be.

**Note: CouchRest only support CouchDB 0.9.0 or newer. Some features requires CouchDB 0.10.0 or newer.**

## Important Upgrade Notice

### 2011-04-04: Time#to_json no longer overwritten!

Now sticking to JSON standard format. Ensure you views using Time will be ordered correctly after upgrade!

## Easy Install

    $ sudo gem install couchrest
   
## Relax, it's RESTful

CouchRest rests on top of a HTTP abstraction layer using by default Heroku’s excellent REST Client Ruby HTTP wrapper.

## Modelling

For more complete modelling support based on Rails 3's ActiveModel, please checkout CouchRest's sister project: [CouchRest Model](https://github.com/couchrest/couchrest_model).

## Extended Document

As of May 2010 support for the popular CouchRest::ExtendedDocument mixin has been moved to its own gem: [couchrest_extended_document](http://github.com/couchrest/couchrest_extended_document).

If you're starting a new project however, we recommend you use the more actively maintained [CouchRest Model](https://github.com/couchrest/couchrest_model) project, supported by the same team of developers.

## Running the Specs

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory use bundler to install 
the dependencies and then run the tests:

    $ bundle install
    $ bundle exec spec spec

To date, the couchrest specs have been show to run on:

 * Ruby 1.8.7
 * Ruby 1.9.2
 * JRuby 1.5.6

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest](http://rdoc.info/projects/couchrest/couchrest)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest](http://wiki.github.com/couchrest/couchrest)

## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest/issues](http://github.com/couchrest/couchrest/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

