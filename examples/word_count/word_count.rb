require 'rubygems'
require 'couchrest'

couch = CouchRest.new("http://127.0.0.1:5984")
db = couch.database('word-count-example')
db.delete! rescue nil
db = couch.create_db('word-count-example')

books = {
  'outline-of-science.txt' => 'http://www.gutenberg.org/files/20417/20417.txt',
  'ulysses.txt' => 'http://www.gutenberg.org/dirs/etext03/ulyss12.txt',
  'america.txt' => 'http://www.gutenberg.org/files/16960/16960.txt',
  'da-vinci.txt' => 'http://www.gutenberg.org/dirs/etext04/7ldv110.txt'
}

books.each do |file, url|
  pathfile = File.join(File.dirname(__FILE__),file)
  `curl #{url} > #{pathfile}` unless File.exists?(pathfile)  
end


books.keys.each do |book|
  title = book.split('.')[0]
  puts title
  File.open(File.join(File.dirname(__FILE__),book),'r') do |file|
    lines = []
    chunk = 0
    while line = file.gets
      lines << line
      if lines.length > 10
        db.save({
          :title => title,
          :chunk => chunk, 
          :text => lines.join('')
        })
        chunk += 1
        puts chunk
        lines = []
      end
    end
  end
end

# puts "The books have been stored in your CouchDB. To initiate the MapReduce process, visit http://127.0.0.1:5984/_utils/ in your browser and click 'word-count-example', then select view 'words' or 'count'. The process could take about 15 minutes on an average MacBook."


