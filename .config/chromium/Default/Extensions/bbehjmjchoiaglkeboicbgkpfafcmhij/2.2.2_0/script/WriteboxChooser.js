function ChooserStatus() {
  this.storage = 'local';
  this.file = {
    dropbox: {id:'/', name:'Dropbox'},
    googledrive: {id:'root', name:'Google Drive'},
    skydrive: {id: '/', name: 'SkyDrive'},
    box: {id: '/', name: 'Box'}
  };
  this.navigation = {
    dropbox: [],
    googledrive:[],
    skydrive: [],
    box: []
  };
}

ChooserStatus.prototype.save = function() {
  util.local.writeJSON('chooser',{
    storage: this.storage,
    file: this.file,
    folderNavList: this.navigation
  });
};

ChooserStatus.prototype.load = function() {
  var self = this;
  util.local.readJSON('chooser', function(status) {
    if (status) {
      self.storage = status.storage;
      self.file = status.file;
      self.navigation = status.folderNavList;
    }
  });
};

ChooserStatus.prototype.setStorage = function(storage) {
  this.storage = storage;
  this.save();
};

ChooserStatus.prototype.setFile = function() {
  this.save();
};

Chooser = {};
Chooser.DIALOG_ID = '#chooser-dialog';

Chooser.UI = {};
Chooser.UI.init = function() {
  $(Chooser.DIALOG_ID + ' .chooser-filelist').empty();
};

Chooser.UI.showChooserDialog = function() {
  $(Chooser.DIALOG_ID + ' .title').text('Select text file..');
  $(Chooser.DIALOG_ID + ' .bottombar').hide();
  //$('#chooser-save-form').hide();

  showDialog({dialogId: Chooser.DIALOG_ID});
};

Chooser.UI.hideChooserDialog = function() {
  hideDialog(Chooser.DIALOG_ID);
};

Chooser.UI.setStorage = function(storage) {
  // switch filelist elem
  $(Chooser.DIALOG_ID + ' .chooser-filelist').hide();
  $(Chooser.DIALOG_ID + ' .chooser-filelist[data-storage=' + storage + ']').show();

  // switch selection mark
  $(Chooser.DIALOG_ID + ' .chooser-storagelist').removeClass('selection');
  $(Chooser.DIALOG_ID + ' .chooser-storagelist[data-storage=' + storage + ']').addClass('selection');
};

Chooser.UI.clearFileList = function(storage) {
  $(Chooser.DIALOG_ID + ' .chooser-filelist[data-storage=' + storage + ']').empty();
};

Chooser.UI.appendLocalFile = function(storage, f) {
  var li = document.createElement('li'),
      container = document.createElement('div'),
      name = document.createElement('div'),
      deletebutton = document.createElement('button');

  var title = f.file.name;
  if (title === '') {
    var tmp = f.contents.replace(/^\s+/, '').substr(0,30);
    title = (tmp !== '') ? tmp : '&lt;No Contents&gt;';
  }

  $(name)
    .addClass('file')
    .attr('data-localid', f.file.localFileID)
    .append(title);

  $(deletebutton)
    .attr('data-localid', f.file.localFileID)
    .addClass('file-delete')
    .addClass('button')
    .append('Discard');

  $(container)
    .append(name)
    .append(deletebutton);

  $(li)
    .append(container);

  $(Chooser.DIALOG_ID + ' .chooser-filelist[data-storage=' + storage + ']').append(li);
};

Chooser.UI.appendCloudFileListItem = function(obj) {
  var icon = document.createElement('img'),
      li = document.createElement('li');

  if (obj.type === 'folder') {
    $(icon).attr('src','/image/chooser/folder.png');
  } else {
    $(icon).attr('src','/image/chooser/file.png');
  }

  $(li)
    .attr('data-objtype',obj.type)
    .attr('data-fileid', obj.fileID)
    .attr('data-filestorage',obj.storage)
    .addClass(obj.type)
    .append(icon)
    .append(obj.fileName);

  $(li).click(function() {
    var type = $(this).attr('data-objtype');
    var storage = $(this).attr('data-filestorage');
    var fileID = $(this).attr('data-fileid');
    var fileName = $(this).text();

    if (type === 'folder') {
      self._choose(storage, fileID, fileName);
    } else {
      console.log('selected:' + storage + ' : ' + fileID);

      var parent = self._getCurrentFolder();
      var fileInfo = WriteboxFileInfo.create(storage, fileName, fileID,
                                             parent.folderName, parent.folderID, self._getCurrentFolderPath());
      console.log(self.currentFolderNavList);
      console.log(fileInfo);
      self.selectedCallback(fileInfo);
    }
  });

  return li;
};

Chooser.UI.removeLocalFile = function(elem) {
  $(elem).slideUp(200,function() {
    $(elem).remove();
  });
};

function WriteboxChooser() {
  this.status = new ChooserStatus();

  Chooser.UI.init();

  $(Chooser.DIALOG_ID + ' .chooser-storagelist').click(function() {
    var storage = $(this).attr('data-storage');
    // this.status.setStorage(storage);
    Chooser.UI.setStorage(storage);
    Chooser.UI.clearFileList(storage);

    if (storage === 'local') {
      new LocalFileManager().list(function(l) {
        for (var i = l.length - 1; i >= 0; i-=1) {
          Chooser.UI.appendLocalFile(storage, l[i]);
        }
      });      
    } else {
      new CloudFileManager().list(storage, '/', function(l) {
        for (var i = l.length - 1; i >= 0; i-=1) {
          console.log(l[i]);
        }
      });
    }
  });

  var t = this;
  $(Chooser.DIALOG_ID + ' .chooser-filelist .file').live('click', function() {
    if (storage === 'local') {
      var localFileID = $(this).attr('data-localid');
      new LocalFileManager().get(localFileID, function(f) {
        t.choosedCallback(f);
        Chooser.UI.hideChooserDialog();
      });
    } else {

    }
  });

  $(Chooser.DIALOG_ID + ' .chooser-filelist .file-delete').live('click', function() {
    var localFileID = $(this).attr('data-localid');
    new LocalFileManager().del(localFileID);
    Chooser.UI.removeLocalFile(this);
  });

}
  /*
  // restore previous status
  self._loadChooserStatus(function() {
    var storage = '';
    // change component with feature
    if (feature === 'open') {
      self.buildOpenUI();
      storage = self.currentStorage;
    } else if (feature === 'save') {
      self.buildSaveUI();
      if (self.currentStorage === 'local') {
        var wbFileInfo = WriteboxFileStatus.get();
        if (wbFileInfo.storage.name !== 'local' && wbFileInfo.storage.name !== '') {
          storage = wbFileInfo.storage.name;
        } else {
          storage = 'dropbox';
        }
      } else {
        storage = self.currentStorage;
      }
    }
    self._switchStorage(storage);
    self._updateLocalFileCount();
  });
}
*/

WriteboxChooser.prototype.choose = function(choosedCallback) {
  this.choosedCallback = choosedCallback;
  Chooser.UI.showChooserDialog();
};









WriteboxChooser._switchStorage = function(storage) {
  this.currentStorage = storage;

  // switch filelist elem
  $(this.dialogID + ' .chooser-filelist').hide();
  $(this.dialogID + ' .chooser-filelist[data-storage=' + this.currentStorage + ']').show();

  // switch selection mark
  $(this.dialogID + ' .chooser-storagelist').removeClass('selection');
  $(this.dialogID + ' .chooser-storagelist[data-storage=' + this.currentStorage + ']').addClass('selection');

  if (storage !== 'local') {
    if ($(this.dialogID + ' .chooser-filelist[data-storage=' + this.currentStorage + '] li').size() === 0) {
      this._choose(this.currentStorage,
                   this.currentFile[this.currentStorage].id,
                   this.currentFile[this.currentStorage].name);
    } else {
      var navList = this.currentFolderNavList[this.currentStorage];
      this._buildFileNavigatorUI(navList);
    }
  } else if (storage === 'local') {
    this._buildLocalFileListUI();
    this._saveChooserStatus();
  }
};


WriteboxChooser.buildSaveUI = function() {
  var self = this;

  $('#chooser-dialog .title').text('Save as..');
  $('li[data-storage=local]').hide();
  $('#chooser-save-form').show();
  $('#chooser-save-form input').focus();
  $('li[data-storage=' + this.currentStorage + ']').click();

  $('#chooser-save-button').unbind('click');
  $('#chooser-save-button').click(function() {
    var fileName = $('#chooser-save-form input').val()
    var parent = self._getCurrentFolder();
    var fileInfo = WriteboxFileInfo.create(self.currentStorage, fileName, '',
                                           parent.folderName, parent.folderID, self._getCurrentFolderPath());
    console.log(self.currentFolderNavList);
    console.log(fileInfo);
    self.selectedCallback(fileInfo);
  });

  $('#chooser-save-form input').unbind('keypress');
  $('#chooser-save-form input').keypress(function(e) {
    if (e.keyCode === 13) {
      var fileName = $('#chooser-save-form input').val()
      var parent = self._getCurrentFolder();
      var fileInfo = WriteboxFileInfo.create(self.currentStorage, fileName, '',
                                             parent.folderName, parent.folderID, self._getCurrentFolderPath());
      console.log(self.currentFolderNavList);
      console.log(fileInfo);
      self.selectedCallback(fileInfo);
    }
  });

  $('#chooser-dialog .bottombar').show();
};

WriteboxChooser._showLoadingMessage = function() {
  var li = document.createElement('li');
  $(li)
    .addClass('loading')
    .text('Loading..');
  $(this.dialogID + ' .chooser-filelist[data-storage=' + this.currentStorage + ']').append(li);
};

WriteboxChooser._addEmptyFolderMessage = function() {
  var li = document.createElement('li');
  $(li)
    .text('No text file');
  $(this.dialogID + ' .chooser-filelist[data-storage=' + this.currentStorage + ']').append(li);
};

WriteboxChooser._choose = function(storage, fileID, fileName) {
  var self = this;

  if (storage !== 'local') {
    self._emptyFileList(storage);
    self._showLoadingMessage();

    var navList = self._addNavigator(fileID, fileName);
    self._buildFileNavigatorUI(navList);


  } else if (storage === 'local') {
     // need to integrate local file management

  }
};

WriteboxChooser._buildCloudFileListUI = function(storage, files) {
  var self = this;

  self._emptyFileList(storage);
  var fileList = $(this.dialogID + ' .chooser-filelist[data-storage=' + storage + ']');
  // folder
  for (var i = 0; i < files.length; i++) {
    var f = files[i];
    if (f.type === 'folder') {
      var li = self._createCloudFileListItem(f);
      $(fileList).append(li);
    }
  }

  // file
  if (self.feature === 'open') {
    for (var i = 0; i < files.length; i++) {
      var f = files[i];
      if (f.type === 'file') {
        if (f.mimeType.substring(0,4) === 'text' || f.mimeType === 'application/octet-stream') {
          var li = self._createCloudFileListItem(f);
          $(fileList).append(li);
        }
      }
    }    
  }
};


var searchFolderID = function(list, folderID) {
  var found = -1;
  for (var i = 0;i < list.length;i++) {
    if (list[i].folderID === folderID) {
      found = i;
      break;
    }
  }
  return found;
};

WriteboxChooser._addNavigator = function(folderID, folderName) {
  var self = this;
  var navList = self.currentFolderNavList[self.currentStorage];

  var i = searchFolderID(navList, folderID);
  if (i === -1) {
    navList.push({
      folderID: folderID,
      folderName: folderName
    });    
  } else {
    navList.splice(i+1, navList.length-(i+1));
  }

  return navList;
};

WriteboxChooser._getCurrentFolderPath = function() {
  var self = this;
  var navList = self.currentFolderNavList[self.currentStorage];

  var folderPath = '';
  for (var i = 1; i < navList.length;i++) {
    folderPath += ('/' + navList[i].folderName);
  }

  return folderPath;
};

WriteboxChooser._getCurrentFolder = function() {
  var self = this;

  if (self.currentStorage === 'dropbox') {
    return self._getCurrentFolderPath();
  } else {
    var navList = self.currentFolderNavList[self.currentStorage];
    var parentFolder = navList[navList.length-1];
    return parentFolder;
  }
};

WriteboxChooser._buildFileNavigatorUI = function(navList) {
  var self = this;

  $(self.dialogID + ' .chooser-navigator').empty();
  for (var i = 0;i < navList.length;i++) {
    // Add folder navigation
    var span = document.createElement('span');
    $(span)
      .attr('data-folderid', navList[i].folderID)
      .append(navList[i].folderName);

    $(span).click(function() {
      self._choose(self.currentStorage, $(this).attr('data-folderid'), $(this).text());
    });

    if (i > 0) {
      $(self.dialogID + ' .chooser-navigator')
        .append(' > ')
        .append(span);
    } else {
      $(self.dialogID + ' .chooser-navigator')
        .append(' ')
        .append(span);
    }
  }
};

WriteboxChooser._updateLocalFileCount = function() {
  var list = WriteboxLocalFileManagement.getFiles();
  $(this.dialogID + ' .chooser-storagelist[data-storage=local]').text('Local (' + list.length + ')');
};
