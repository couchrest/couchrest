// an example map function, emits the doc id 
// and the list of keys it contains

function(doc) {
  var k, keys = []
  for (k in doc) keys.push(k);
  emit(doc._id, keys);
};
