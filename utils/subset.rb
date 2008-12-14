require 'rubygems'
require 'couchrest'

# subset.rb replicates a percentage of a database to a fresh database.
# use it to create a smaller dataset on which to prototype views.

# specify the source database
source = CouchRest.new("http://127.0.0.1:5984").database('source-db')

# specify the target database
target = CouchRest.new("http://127.0.0.1:5984").database('target-db')

# pager efficiently yields all view rows
pager = CouchRest::Pager.new(source)

pager.all_docs(1000) do |rows|  
  docs = rows.collect do |r|
    # the percentage of docs to clone
    next if rand > 0.1 
    doc = source.get(r['id'])
    doc.delete('_rev')
    doc      
  end.compact
  puts docs.length
  next if docs.empty?

  puts docs.first['_id']
  target.bulk_save(docs)
end

