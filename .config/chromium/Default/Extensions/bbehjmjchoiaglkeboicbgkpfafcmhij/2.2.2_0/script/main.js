
var showDialog = function(args) {
  var detouch = function() {
    $(args.dialogId + ' .close-button').unbind('click');
    $(args.dialogId + ' .cancel-button').unbind('click');
    $(args.dialogId + ' .okay-button').unbind('click');
  };

  $(args.dialogId + ' .dialog-close-button').click(function() {
    detouch();
    $(args.dialogId).hide();
    if (args.close) args.close();
  });

  $(args.dialogId + ' .cancel-button').click(function() {
    detouch();
    $(args.dialogId).hide();
    if (args.cancel) args.cancel();
  });

  $(args.dialogId + ' .okay-button').click(function() {
    detouch();
    $(args.dialogId).hide();
    if (args.okay) args.okay();
  });

  $(args.dialogId).show();
  if (args.open) {
    args.open();
  }
};

var hideDialog = function(id) {
  if (id) {
    $(id).prev(".dialog-bg").remove();
    $(id).hide();
  } else {
    $(".dialog-bg").remove();
    $(".dialog").hide();
  }
};

function Writebox() {
  this.settings = new Settings();
  this.shortcuts = new Shortcuts();
  this.editor = new Editor(this.settings, this.shortcuts);
  this.chooser = new WriteboxChooser();
  this.menuController = new MenuController();
  this.settingController = new SettingController(this.settings);
  this.shortcutController = new WriteboxShortcutController(this.shortcuts);
  this.uiLayoutManager = new UILayoutManager(this.settings);

  this.settings.load();
}

Writebox.prototype.startApp = function() {
  this.menuController.subscribe('menuSelected', this.onMenuSelected.bind(this));
};

Writebox.prototype.startGoogleAnalytics = function() {
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-27635130-2']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = 'https://ssl.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
};

Writebox.prototype.onMenuSelected = function(menu) {
  var self = this;
  switch (menu) {
    case 'newText':
      self.editor.createNewFile(function() {
        self.editor.focusTextArea();
      });
      break;
    case 'loadText':
      self.chooser.choose(function(textFile) {
        self.editor.openFile(textFile);
      });
      break;
    case 'syncText':
      //self.saveText();
      break;
    case 'previewMarkdown':
      //self.editor.togglePreviewMode();
      break;
    case 'optionBar':
      this.settingController.showOptionBar();
      break;
    case 'discardText':
      //self.confirmOperation(function() {
      //  self.discardEditingText();            
      //});
      break;
    case 'deleteLocalData':
      //self.confirmOperation(function() {
      //  self.deleteLocalData();
      //});
      break;
    case 'saveTextAs':
      //self.fileManager.chooseFolder(function() {
      //});
      break;
    case 'downloadPlainText':
      break;
    case 'downloadMarkdownText':
      break;
    case 'downloadHtml':
      break;
    case 'showShortcutsSetting':
      this.shortcutController.showDialog();
      break;
    case 'showAbountInformation':
      break;
    case 'showAccountInformation':
      break;
  }
};

Writebox.prototype.createNewText = function() {
  /*
  if (this.editor.isEditing()) {
    if (this.editor.saveToLocal()) {
      var wbFile = this.fileManager.createEmptyTextFile();
      this.editor.openTextFile(wbFile);
    }
  } else {
    // 編集していないので、破棄して新しいテキストを作る
    var wbFile = this.fileManager.createEmptyTextFile();
    this.editor.openTextFile(wbFile);
  }
  */
};

$(document).ready(function() {
  var app = new Writebox();
  app.startGoogleAnalytics();
  app.startApp();
});
