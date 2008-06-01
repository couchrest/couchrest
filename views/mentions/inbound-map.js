
function(doc){if(doc.mp3s){for(var i=0,m;m=doc.mp3s[i];i++){emit(m.href,doc.fetch.url);}}}