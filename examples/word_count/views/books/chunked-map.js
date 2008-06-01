function(doc) {
  doc.title && doc.chunk && emit([doc.title, doc.chunk],null);
}