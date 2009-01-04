function(doc, req) {
  // !include lib.templates
  
  // !require lib.helpers.template
  
  respondWith(req, {
    html : function() {
      var html = template(lib.templates.example, doc);
      return {body:html}
    },
    xml : function() {
      return {
        body : <xml><node value={doc.title}/></xml>
      }
    }
  })
};