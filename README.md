# CouchRest: CouchDB, close to the metal [![Build Status](https://travis-ci.org/couchrest/couchrest.png)](https://travis-ci.org/couchrest/couchrest)

CouchRest is based on [CouchDB's couch.js test
library](http://svn.apache.org/repos/asf/couchdb/trunk/share/www/script/couch.js),
which I find to be concise, clear, and well designed. CouchRest lightly wraps
CouchDB's HTTP API, managing JSON serialization, and remembering the URI-paths
to CouchDB's API endpoints so you don't have to.

CouchRest is designed to make a simple base for application and framework-specific object oriented APIs. CouchRest is Object-Mapper agnostic, the parsed JSON it returns from CouchDB shows up as subclasses of Ruby's Hash. Naked JSON, just as it was mean to be.

## CouchDB Version

Tested on latest stable release (1.6.X), but little has changed in the last few year and should work on older versions. Also known to work fine on [Cloudant](http://cloudant.com).

## Install

    $ sudo gem install couchrest

## Modelling

For more complete modelling support based on ActiveModel, please checkout CouchRest's sister project: [CouchRest Model](https://github.com/couchrest/couchrest_model).

## Running the Specs

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory use bundler to install 
the dependencies and then run the tests:

    $ bundle install
    $ bundle exec rake

To date, the couchrest specs have been shown to run on:

 * MRI Ruby 1.9.3 and later
 * JRuby

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest](http://rdoc.info/projects/couchrest/couchrest)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest](http://wiki.github.com/couchrest/couchrest)

## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest/issues](http://github.com/couchrest/couchrest/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [https://twitter.com/search?q=couchrest](https://twitter.com/search?q=couchrest)

