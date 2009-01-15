require 'rubygems'
require 'couchrest'

couch = CouchRest.new("http://127.0.0.1:5984")
db = couch.database('word-count-example')

word_count = {
  :map => 'function(doc){
    var words = doc.text.split(/\W/);
    words.forEach(function(word){
      if (word.length > 0) emit([word,doc.title],1);
    });
  }',
  :reduce => 'function(key,combine){
    return sum(combine);
  }'
}

db.delete db.get("_design/word_count") rescue nil

db.save({
  "_id" => "_design/word_count",
  :views => {
    :words => word_count
  }
})
