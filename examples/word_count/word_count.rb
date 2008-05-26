require File.dirname(__FILE__) + '/../../couchrest'

couch = CouchRest.new("http://localhost:5984")
db = couch.database('word-count-example')
db.delete! rescue nil
db = couch.create_db('word-count-example')

['da-vinci.txt', 'outline-of-science.txt', 'ulysses.txt'].each do |book|
  title = book.split('.')[0]
  puts title
  File.open(File.join(File.dirname(__FILE__),book),'r') do |file|
    lines = []
    chunk = 0
    while line = file.gets
      lines << line
      if lines.length > 100
        db.save({
          :title => title,
          :chunk => chunk, 
          :text => lines.join('')
        })
        chunk += 1
        lines = []
      end
    end
  end
end
 
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
    :count => word_count,
    :words => {:map => word_count[:map]}
  }
})

puts "The books have been stored in your CouchDB. To initiate the MapReduce process, visit http://localhost:5984/_utils/ in your browser and click 'word-count-example', then select view 'words' or 'count'. The process could take about 15 minutes on an average MacBook."


