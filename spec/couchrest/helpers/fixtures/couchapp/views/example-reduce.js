// example reduce function to count the
// number of rows in a given key range.

function(keys, values, rereduce) {
  if (rereduce) {
    return sum(values);
  } else {
    return values.length;
  }
};