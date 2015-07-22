function LocalFileManager() {
}

LocalFileManager.prototype.new = function(callback) {
  var self = this;

  var f = new WriteboxTextFile();
  self.list(function(l) {
    l.push(f);
    self.writeToStorage(l);

    callback(f);
  });
};

LocalFileManager.prototype.del = function(localFileID, callback) {
  var self = this;

  self.list(function(l) {
    for (var i = 0;i < l.length; i++) {
      if (l[i].file.localFileID = localFileID) {
        l.splice(i, 1);
        break;
      }
    }

    self.writeToStorage(l);

    if (callback) {
      callback();
    }
  });
};

LocalFileManager.prototype.get = function(localFileID, callback) {
  var self = this;

  self.list(function(l) {
    for (var i = 0;i < l.length; i++) {
      if (l[i].file.localFileID === localFileID) {
        callback(l[i]);
        return;
      }
    }
    callback(null);
  });
};

LocalFileManager.prototype.save = function(f) {
  var self = this;

  self.list(function(l) {
    for (var i = 0;i < l.length; i++) {
      if (l[i].file.localFileID === f.file.localFileID) {
        l[i] = f; // update
      }
    }
    self.writeToStorage(l);
  });  
};

LocalFileManager.prototype.list = function(callback) {
  this.readFromStorage(function(l) {
    callback(l);
  })
};


LocalFileManager.prototype.readFromStorage = function(callback) {
  var l = [];

  util.local.readJSON('pool', function(storageList) {
    storageList = storageList || [];
    for (var i = 0; i < storageList.length; i++) {
      if ('localFileID' in storageList[i].wbFileInfo) {
        // for old version(for Multi tab)
        storageList[i].wbFileInfo.file.localFileID = WriteboxTextFile.createLocalFileID();
      }

      // Convert to WriteboxTextFile
      var f = new WriteboxTextFile();
      f.setMetaData(storageList[i].wbFileInfo);
      f.setContents(storageList[i].contents);

      l.push(f);
    }

    callback(l);
  });
};

LocalFileManager.prototype.writeToStorage = function(l) {
  var storageList = [];
  for (var i = 0; i < l.length; i++) {
    storageList.push({
      wbFileInfo: l[i].getMetaData(),
      contents: l[i].contents
    });
  }
  util.local.writeJSON('pool', storageList);
};


function CloudFileManager() {

}

CloudFileManager.prototype.get = function() {

};


CloudFileManager.prototype.save = function() {

};

CloudFileManager.prototype.list = function(storage, fileID, callback) {
  api2[storage].getFiles({
    query: fileID,
    success: function(files) {
      callback(files);
    },
    error: function(errorStatus) {
    }
  });
};

function WriteboxTextFile(param) {
  var localFileID = WriteboxTextFile.createLocalFileID();

	this.storage = {
		name: 'local'
	};

	this.file = {
    name: '',
    id: localFileID,
    localFileID: localFileID,
    modified: '',
    edit: false
	};

	this.parent = {
		name: '',
		id: '',
		path: ''
	};

	this.contents = '';
}

WriteboxTextFile.createLocalFileID = function() {
  return 'localid-' + (new Date()).getTime() + '' + Math.floor(Math.random()*255+1);
};

WriteboxTextFile.prototype.getMetaData = function() {
	return {
		storage: this.storage,
		file: this.file,
		parent: this.parent
	};
};

WriteboxTextFile.prototype.setMetaData = function(wbTextFile) {
	this.storage = wbTextFile.storage;
	this.file = wbTextFile.file;
	this.parent = wbTextFile.parent;
}

WriteboxTextFile.prototype.setContents = function(contents) {
	this.contents = contents;
}
