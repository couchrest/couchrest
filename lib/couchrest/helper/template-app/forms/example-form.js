function(doc, req) {
  // include-lib
  respondWith(req, {
    html : function() {
      var html = template(lib["example.html"], doc);
      return {body:html}
    },
    xml : function() {
      return {
        body : <xml><node value={doc.title}/></xml>
      }
    }
  })
};