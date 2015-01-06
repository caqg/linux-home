
function Editor(settings, shortcuts) {
  this.settings = settings;
  this.shortcuts = shortcuts;
  this.textFile = new WriteboxTextFile();
  this.textArea = $('#editor');
  this.status = new EditStatus();
  this.localFileManager = new LocalFileManager();

  this.textArea.bind('keyup', this.onContentsChanged.bind(this));
  this.settings.subscribe('settingChanged', this.onSettingChanged.bind(this));
  this.status.load(this.onStatusLoaded.bind(this));
}

Editor.prototype.onStatusLoaded = function(textFile) {
  this.textFile = textFile;
  this.textArea.val(this.textFile.contents);
  this.calcStatistics();
};

Editor.prototype.onContentsChanged = function() {
  this.textFile.setContents(this.textArea.val());
  this.status.save(this.textFile);
  this.calcStatistics();
};

Editor.prototype.onSettingChanged = function(settingName) {
  console.log(settingName);
  this.setPreference(this.settings);
};

Editor.prototype.focusTextArea = function() {
  this.textArea.focus();
};

Editor.prototype.setPreference = function(settings) {
  this.textArea
    .css('color', settings.textColor)
    .css('background-color', settings.backgroundColor)
    .css('font-family', settings.fontFamily)
    .css('font-size', settings.fontSize)
    .css("line-height", settings.lineHeight + "em");

  if (settings.showStatistics) {
    $("#document-statistics").show();
  } else {
    $("#document-statistics").hide();
  }

  if (settings.showScrollbar) {
    this.textArea.removeClass('off-scrollbar');
  } else {
    this.textArea.addClass('off-scrollbar');
  }
};

Editor.prototype.calcStatistics = function() {
  var contents = this.textArea.val();

  if (contents) {
    var l = contents.length,
        w = contents.split(/\S+/g).length-1,
        c = contents.replace(/\n/g,"").length,
        lf = l - c + 1;
    $("#line-count").text(util.toThreeDigit(lf));
    $("#word-count").text(util.toThreeDigit(w));
    $("#char-count").text(util.toThreeDigit(c));

  } else {
    $("#line-count").text('-');
    $("#word-count").text('-');
    $("#char-count").text('-');
  }

};

Editor.prototype.createNewFile = function() {
  var self = this;

  self.closeFile(function() {
    self.localFileManager.new(function(textFile) {
      self.openFile(textFile);          
      self.focusTextArea();
    })
  });
};

Editor.prototype.openFile = function(textFile) {
  this.textFile = textFile;

  if (this.textFile.storage.name === 'local') {
    // Load from local
    this.openLocalFile(this.textFile);
  } else {
    // Load from cloud
    this.openCloudFile(this.textFile);
  }
};

Editor.prototype.closeFile = function(callback) {
  if (this.textFile.storage.name === 'local') {
    this.textFile.contents = this.textArea.val();
    this.localFileManager.save(this.textFile);
    callback();
  } else {
    if (this.textFile.edit === true) {

    } else {
      this.localFileManager.delete(this.textFile, function() {
        callback();      
      });
    }
  }
};

Editor.prototype.openLocalFile = function(textFile) {
  this.textArea.val(textFile.contents);
  this.updateEditorUI(textFile);

};

Editor.prototype.openCloudFile = function(wbTextFile) {
  var self = this;

  self.showLoadingMessage();
  self.fileManager.openCloudFile(wbTextFile, function(wbTextFile) {
    self.hideLoadingMessage();
    self.textArea.val(wbTextFile.contents);
    self.updateEditorUI(wbTextFile);
  });
};

Editor.prototype.saveTextFile = function() {
};

Editor.prototype.isEditing = function() {
  return false;
};

Editor.prototype.updateEditorUI = function() {

};
