require 'rubygems'
require 'couchrest'

couch = CouchRest.new("http://127.0.0.1:5984")
db = couch.database('word-count-example')

puts "Now that we've parsed all those books into CouchDB, the queries we can run are incredibly flexible."
puts "\nThe simplest query we can run is the total word count for all words in all documents:"
puts "this will take a few minutes the first time. if it times out, just rerun this script in a few few minutes."
puts db.view('word_count/words').inspect

puts "\nWe can also narrow the query down to just one word, across all documents. Here is the count for 'flight' in all three books:"

word = 'flight'
params = {
  :startkey => [word], 
  :endkey => [word,{}]
  }

puts db.view('word_count/words',params).inspect

puts "\nWe scope the query using startkey and endkey params to take advantage of CouchDB's collation ordering. Here are the params for the last query:"
puts params.inspect

puts "\nWe can also count words on a per-title basis."

title = 'da-vinci'
params = {
  :key => [word, title]
  }
  
puts db.view('word_count/words',params).inspect


puts "\nHere are the params for 'flight' in the da-vinci book:"
puts params.inspect
puts
puts 'The url looks like this:'
puts 'http://127.0.0.1:5984/word-count-example/_view/word_count/count?key=["flight","da-vinci"]'
puts "\nTry dropping that in your browser..."