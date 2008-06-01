function(doc){
  var words = doc.text.split(/\W/).filter(function(w) {return w.length > 0}).map(function(w){return w.toLowerCase()});
  for (var i = 0, l = words.length; i < l; i++) {
    emit(words.slice(i,4),doc.title);
  }
}