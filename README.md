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
   
### Relax, it's RESTful

CouchRest rests on top of a HTTP abstraction layer using by default Heroku’s excellent REST Client Ruby HTTP wrapper.
Other adapters can be added to support more http libraries.

### Running the Specs

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory run `rake`, or `autotest`
(requires RSpec and optionally ZenTest for autotest support).

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest](http://rdoc.info/projects/couchrest/couchrest)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest](http://wiki.github.com/couchrest/couchrest)

## Contact

Please post bugs, suggestions and patches to the bug tracker at <http://jchris.lighthouseapp.com/projects/17807-couchrest/overview>.

Follow us on Twitter: http://twitter.com/couchrest

Also, check http://twitter.com/#search?q=%23couchrest
      
## Ruby on Rails

CouchRest is compatible with rails and can even be used a Rails plugin.
However, you might be interested in the CouchRest companion rails project:
[http://github.com/hpoydar/couchrest-rails](http://github.com/hpoydar/couchrest-rails)      
