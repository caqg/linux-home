function EditStatus() {
}

EditStatus.prototype.save = function(wbTextFile) {
  this.saveMetaData(wbTextFile.getMetaData());
  this.saveContents(wbTextFile.file.localFileID, wbTextFile.contents);
};

EditStatus.prototype.load = function(callback) {
  var self = this;

  self.loadMetaData(function(metaData) {
    var textFile = new WriteboxTextFile();
    textFile.setMetaData(metaData);

    self.loadContents(textFile.file.localFileID, function(contents) {
      textFile.setContents(contents);
      callback(textFile);
    });
  });
};

EditStatus.prototype.saveMetaData = function(metaData) {
  util.session.writeJSON('textFile', metaData);
  util.local.writeJSON('textFile', metaData);
};

EditStatus.prototype.saveContents = function(localFileID, contents) {
  util.local.write(localFileID, contents);
};

EditStatus.prototype.loadMetaData = function(callback) {
  util.session.readJSON('textFile', function(metaData) {
    if (metaData) {
      callback(metaData);
    } else {
      util.local.readJSON('textFile', function(metaData) {
        if (metaData) {
          callback(metaData);
        }
      });
    }
  });
};

EditStatus.prototype.loadContents = function(localFileID, callback) {
  util.local.read(localFileID, function(contents) {
    callback(contents);
  });
};