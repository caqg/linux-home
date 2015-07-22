var isChromeApp = false;
if (chrome && chrome.storage) {
	isChromeApp = true;
}

var util = {
	session: {
		write: function(key, value) {
	    try {
	      sessionStorage.setItem(key, value);
	    } catch(e) {
	    	if (this.writeErrorEventListener) {
	    		this.writeErrorEventListener(key);
	    	}
	    }    
		},

		read: function(key, callback) {
	    callback(sessionStorage[key]);
		},

		writeJSON: function(key, value) {
			this.write(key, JSON.stringify(value));
		},

		readJSON: function(key, callback) {
			this.read(key, function(value) {
				if (value) {
					callback(JSON.parse(value));					
				} else {
					callback(null);
				}
			});
		}
	},

	local: {
		writeErrorEventListener: null,
		listenWriteErrorEvent: function(callback) {
      this.writeErrorEventListener = callback;
		},

		write: function(key, value) {
			if (isChromeApp) {
		    var obj = { key : value };
		    chrome.storage.local.set(obj);
		  } else {
		    try {
		      localStorage.setItem(key, value);
		    } catch(e) {
		    	if (this.writeErrorEventListener) {
		    		this.writeErrorEventListener(key);
		    	}
		    }    
		  }
		},

		read: function(key, callback) {
		  if (!callback) {
		    return 
		  }

			if (isChromeApp) {
		    chrome.storage.local.get(key, function(items) {
		      callback(items[key]);
		    });
		  } else {
		    callback(localStorage[key]);
		  }
		},

		writeJSON: function(key, value) {
			this.write(key, JSON.stringify(value));
		},

		readJSON: function(key, callback) {
			this.read(key, function(value) {
				if (value) {
					callback(JSON.parse(value));
				} else {
					callback(null);
				}
			});
		},

		clearAll: function() {
			if (isChromeApp) {
		    chrome.storage.local.clear();
		  } else {
		    localStorage.clear();
		  }

		}
	},

  toThreeDigit: function(num) {
	  var r=[], nums=num.toString().split("").reverse(), l=nums.length;
	  nums.forEach(function(c,i) {
	    r.push(c);
	    if ((i+1)%3 === 0 && i !== l-1 && c !== '-') r.push(',');
	  });

	  return r.reverse().join("");
  }
};
