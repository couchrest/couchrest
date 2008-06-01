function(doc){
  var words = doc.text.split(/\W/).map(function(w){return w.toLowerCase()});
  words.forEach(function(word){
    if (word.length > 0) emit([word,doc.title],1);
  });
}