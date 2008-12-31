require 'rubygems'
require 'couchrest'

# set the source db and map view
source = CouchRest.new("http://127.0.0.1:5984").database('source-db')
source_view = 'mydesign/view-map'

# set the target db
target = CouchRest.new("http://127.0.0.1:5984").database('target-db')


pager = CouchRest::Pager.new(source)

# pager will yield once per uniq key in the source view

pager.key_reduce(source_view, 10000) do |key, values|
  # create a doc from the key and the values
  example_doc = {
    :key => key,
    :values => values.uniq
  }

  target.save(example_doc)
  
  # keep us up to date with progress
  puts k if (rand > 0.9)
end
