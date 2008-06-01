
function(doc){doc.playlist&&doc.playlist.track&&doc.playlist.track.forEach(function(t){emit([t.creator||null,t.title||null],t.album||null);});};