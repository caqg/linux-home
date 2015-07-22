var menuVisibility = true;
var loginStatus = false;
var PADDING_FULLSCREEN = 10;
var isChromeApp = function() {
  if (chrome && chrome.storage) {
    return true;
  } else {
    return false;
  }
};

var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-27635130-2']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = 'https://ssl.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();

if (navigator.userAgent.indexOf('Chrome') < 0) {
  chrome = null;
} 

var layout = function() {
  //console.log('window:' + $(window).width() + ' ' +  $(window).height());

  // Editor
  var width = 0, padding = 0, bar = 0;
  $g('width', function(settingWidth) {
    settingWidth = parseInt(settingWidth) || 800;      
    if ($(window).width() < 800) {
      if (settingWidth < $(window).width()) {
        width = settingWidth;
        padding = ($(window).width() / 2) - (width / 2) + PADDING_FULLSCREEN;
      } else {
        width = $(window).width() - PADDING_FULLSCREEN*2;
        padding = PADDING_FULLSCREEN;
      }
    } else {
      width = settingWidth;
      padding = ($(window).width() / 2) - (width / 2);
    }

    $('#editor')
      .css("margin-left", padding)
      .css("padding-right", padding)
      .width(width + padding);

    //if (isChromeApp() === false) {
      if ($(window).width() < 800) {
        $('#editor-footer, #header > #menu, .slidedown-bar > .container')
          .css("margin-left", 0)
          .css("padding-right", 0)
          .width(width + padding*2);
      } else {
        $('#editor-footer, #header > #menu, .slidedown-bar > .container')
          .css("margin-left", padding)
          .css("padding-right", padding)
          .width(width + padding);        
      }
    //}

    // Preview window
    var previewTop = $('#editor').position().top;
    $("#markdown-preview-window")
      .css('position', 'absolute')
      .css('top', previewTop)
      .css('left', $('#editor').position().left + padding)
      .css('width', $('#editor').width() + padding)
      .css('height', $(window).height() - previewTop);
    $("#preview")
      .css('padding-right', padding)
      .css('overflow-x', 'hidden')
      .css('height', $(window).height() - previewTop);

  });
};

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

/*
var showDialog = function(id,callback) {
  // background event
  var bg = document.createElement("div");
  $(bg)
    .addClass("dialog-bg")
    .css("position","absolute")
    .css("top", 0)
    .css("left", 0)
    .css("width", $(window).width())
    .css("height", $(window).height())
    .css("background","black")
    .css("opacity", 0.3)
    .css("z-index",10);
  $(bg).click(function() {
    $(this).remove();
    $(id).hide();
    if (callback) callback();
  });
  $(id).before(bg)

  // dialog
  var dialog = document.createElement("div");

  $(id)
    .addClass("dialog")
  $(id)
    .show();
    
  $(id).children(".dialog-bar").children(".dialog-window-close").click(function() {
    $(bg).remove();
    $(id).hide();
    if (callback) callback();
  });
};
*/

var createEmptyText = function() {
  var newFile = WriteboxFileInfo.createLocalFile();
  updateFileStatus(newFile);
  $("textarea#editor").val("");
  $s('contents','');

  updateStatisticsInfo();
  //textStorage.setEditingStatus('no-editing');
  $("#discard-button").addClass('disable');
};

var saveCurrentFileOnLocal = function() {
  var wbFileInfo = WriteboxFileStatus.get(),
      contents = textStorage.getContents();

  var result = WriteboxLocalFileManagement.saveFile(wbFileInfo, contents);
  return result;
};

var newText = function() {
  if (isCurrentFileEditing()) {
    // 邱ｨ髮�ｸｭ縺ｮ繝�く繧ｹ繝医ｒLocal縺ｫ菫晏ｭ倥＠縺ｦ縺九ｉ譁ｰ縺励＞繝�く繧ｹ繝医ｒ菴懊ｋ
    if (saveCurrentFileOnLocal()) {
      createEmptyText();
    }
  } else {
    // 邱ｨ髮�＠縺ｦ縺�↑縺��縺ｧ縲∫ｴ譽�＠縺ｦ譁ｰ縺励＞繝�く繧ｹ繝医ｒ菴懊ｋ
    createEmptyText();
  }
};

var isCurrentFileEditing = function() {
  var wbFileInfo = WriteboxFileStatus.get();
  return wbFileInfo.file.edit;
};

var updateFileStatus = function(wbFileInfo) {
  $("#filename")
    .attr("data-storage",wbFileInfo.storage.name)
    .attr("data-fileid",wbFileInfo.file.id)
    .attr("title",wbFileInfo.parent.path + '/' + wbFileInfo.file.name);

  $("#filename span").text(wbFileInfo.file.name);


  switch (wbFileInfo.storage.name) {
    case 'dropbox':
      $("#filename img").attr('src', '/image/storage/dropbox_icon.png');
      $("#filename img").addClass('show');
      break;
    case 'googledrive':
縲    $("#filename img").attr('src', '/image/storage/drive_icon.png');
      $("#filename img").addClass('show');
      break;
    case 'box':
縲    $("#filename img").attr('src', '/image/storage/box_icon.png');
      $("#filename img").addClass('show');
      break;
    case 'skydrive':
      $("#filename img").attr('src', '/image/storage/skydrive_icon.png');
      $("#filename img").addClass('show');
      break;
    default:
      $("#filename img").attr('src', '');
      $("#filename img").removeClass('show');
      break;
  }
  WriteboxFileStatus.save(wbFileInfo);
};


var loadCloudFile = function(wbFileInfo) {
  hideDialog();
  $("textarea#editor").val("Loading..");

  var accessAPI = api2[wbFileInfo.storage.name];
  var query;
  if (wbFileInfo.storage.name === 'dropbox') {
    query = wbFileInfo.parent.path + '/' + wbFileInfo.file.name;
  } else {
    query = wbFileInfo.file.id;
  }
  
  accessAPI.getTextData({
    query: query,
    success: function(text, modifiedDate, mimeType) {

      if (isCurrentFileEditing()) {
        var result = saveCurrentFileOnLocal();
        if (result === false) {
          $("textarea#editor").val(prev_contents);
          return;
        }
      }

      wbFileInfo.file.mimeType = mimeType;
      wbFileInfo.file.modified = modifiedDate;
      updateFileStatus(wbFileInfo);

      $("textarea#editor").val(text);
      textStorage.setContents(text);
      WriteboxRecentFileList.push(wbFileInfo);
      buildRecentListMenu();

      updateStatisticsInfo(text);
    },
    error: function() {
      $("textarea#editor").val("");
      showDialog({dialogId: "#error-load-dialog"});      
    }
  });

};

var selectCloudFile = function(callback) {
  chooser.build('#chooser-dialog', 'save', callback, confirmMoveToAuthProcess);
  showDialog({dialogId: '#chooser-dialog'});
  $('#file-name-input').focus();
};

var sync = function() {
  var wbFileInfo = WriteboxFileStatus.get();
  var fileName = wbFileInfo.file.name;
  if (fileName !== "") {
    var contents = $("textarea#editor").val();
    saveFileContents(WriteboxFileStatus.get(), contents);

  } else {
    selectCloudFile(function(wbFileInfo) {
      if (wbFileInfo.file.name !== '') {
        hideDialog();

        var contents = $("textarea#editor").val();
        saveFileContents(wbFileInfo, contents);

        updateFileStatus(wbFileInfo);
      } else {
        hideDialog();
      }
    });
  }
};


var isPreviewMode = function() {
  if ($('#markdown-preview-window').css('display') === 'none') {
    return false;
  } else {
    return true;
  }
};

var hidePreview = function() {
  $("#markdown-preview-window").fadeOut(300, function() {
    $('#markdown-preview-window').removeClass('preview-status-on');        
  });

  $("#preview-markdown-esc-message").fadeOut(300, function() {
    $("#header > div#menu").fadeIn(200);
  });

  $("#editor").animate({opacity: 1.0, duration: 300});
};

var previewMarkdown = function() {
  console.log('previewMarkdown');
  //var markdown = window.markdown.toHTML($('#editor').val());
  //marked.setOptions({tables: true});
  var markdown = marked($('#editor').val());

  $("#preview > div").html(markdown)

  $("#markdown-preview-window, #preview")
    .css("background",settingsModel.backgroundColor);

  $("#preview *")
    //.css('font-size', localStorage.fontSize)
    .css('font-family', settingsModel.fontFamily)
    .css('color', settingsModel.textColor);

/*
  $("#preview-markdown-esc-message")
    .css('position', 'absolute')
    .css('top', 0)
    .css('left', $('div.left').position().left)
    .css('height', $('#header').outerHeight());
*/

  $('#markdown-preview-window').addClass('preview-status-on');
  //$('#preview-markdown-button > img').attr('src', '/image/preview-on-status.png');


  $("#editor").animate({opacity: 0.0, duration: 300}, function() {
    $("#markdown-preview-window").fadeIn(200);
    $("#preview-markdown-esc-message").fadeIn(200);
  });

  $("#header > div#menu").fadeOut(300);

  $("#editor").blur();
};

var insertString = function() {

};


var wrap = function(token) {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd,
      len = end - at;

  if (at !== end) {
    t.value = tdata.substring(0, at) + token + tdata.substring(at, end) + token + tdata.substring(end, t.value.length);
    t.selectionStart = at + token.length;
    t.selectionEnd = t.selectionStart + len;
  } else {
    t.value = tdata.substring(0, at) + token + token + tdata.substring(end, t.value.length);
    t.selectionStart = at + token.length;
    t.selectionEnd = t.selectionStart;
  }
};


var insertTopOfLine = function(str) {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd,
      len = end-at-1;

  var t1, t2, t3;
  t1 = tdata.substr(0, at);
  if (end - at > 0) {
    // selected
    t2 = str + tdata.substr(at, len).split("\n").join("\n"+str) + tdata.substr(end-1,1);
  } else {
    t2 = str;
  }
  t3 = tdata.substr(end, tdata.length);
  t.value = t1 + t2 + t3;

  var cursorStart, cursorEnd;
  if (end - at > 0) {
    // selected
    cursorStart = at;
    cursorEnd = cursorStart + t2.length;
  } else {
    cursorStart = str.length + at;
    cursorEnd = cursorStart;
  }

  t.setSelectionRange(cursorStart, cursorEnd);
};


var deleteTopOfLine = function(str) {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd,
      len = end-at-1;

  if (end - at > 0) {
    // selected
    var t1, t2, t3;
    t1 = tdata.substr(0, at);
    t2 = tdata.substr(at, end - at).split("\n"+str).join("\n");
    if (t2.substr(0, str.length) === str) {
      t2 = t2.replace(str,"");
    }
    t3 = tdata.substr(end, tdata.length);
    t.value = t1 + t2 + t3;

    var cursorStart, cursorEnd;
    cursorStart = at;
    cursorEnd = cursorStart + t2.length;
    t.setSelectionRange(cursorStart, cursorEnd);

  } else {
    // not selected
    // do nothing..
  }

};

var saveFileContents = function(wbFileInfo, contents) {

  //showDialog("#sync-processing-dialog");
  $('#sync-button > span').text('Syncing..');
  //$('#sync-button').addClass('syncing');
  $('#processing-message').text('Syncing...');
  $('#processing-message').addClass('processing');

  var accessAPI = api2[wbFileInfo.storage.name]
  var fileID = '';
  if (wbFileInfo.storage.name === 'dropbox') {
    fileID = wbFileInfo.parent.path + '/' + wbFileInfo.file.name;
  } else {
    fileID = wbFileInfo.file.id;
  }
  var mimeType = wbFileInfo.file.mimeType;
  if (mimeType === undefined) {
    mimeType = 'text/plain';
  }
  accessAPI.saveTextData({
    fileID: fileID,
    fileName: wbFileInfo.file.name,
    mimeType: mimeType,
    parentFolderID: wbFileInfo.parent.id,
    contents: contents,
    success: function(fileID, modified) {
      $('#sync-button > span').text('Sync');
      //$('#sync-button').removeClass('syncing');
      $('#processing-message').text('');
      $('#processing-message').removeClass('processing');
      $("#discard-button").addClass('disable');

      wbFileInfo.file.id = fileID;
      wbFileInfo.file.modified = modified;
      wbFileInfo.file.edit = false;
      updateFileStatus(wbFileInfo);
      //WriteboxFileStatus.save(wbFileInfo);
      textStorage.setContents(contents);

      //textStorage.setEditingStatus('no-editing');
    },
    error: function() {
      $('#sync-button > span').text('Sync');
      $('#processing-message').text('');
      showDialog({dialogId: "#error-save-dialog"});
    }
  });
};

var account = function(callback) {
  api2.getAccount({
    success: function(account) {
      if (account.linked_count === 0) {
        $("#dropbox-account").text('');
        $("#link-dropbox-button").show();
        $("#unlink-dropbox-button").hide();

        $("#googledrive-account").text('');
        $("#link-googledrive-button").show();
        $("#unlink-googledrive-button").hide();

        $("#box-account").text('');
        $("#link-box-button").show();
        $("#unlink-box-button").hide();

        $("#skydrive-account").text('');
        $("#link-skydrive-button").show();
        $("#unlink-skydrive-button").hide();

        loginStatus = false;
      } else {
        if (account.dropbox) {
          $("#dropbox-account").text(account.dropbox.mail_address);
          $("#link-dropbox-button").hide();
          $("#unlink-dropbox-button").show();
        } else {
          $("#dropbox-account").text('');
          $("#link-dropbox-button").show();
          $("#unlink-dropbox-button").hide();
        }

        if (account.googledrive) {
          $("#googledrive-account").text(account.googledrive.mail_address);
          $("#link-googledrive-button").hide();
          $("#unlink-googledrive-button").show();
        } else {
          $("#googledrive-account").text('');
          $("#link-googledrive-button").show();
          $("#unlink-googledrive-button").hide();
        }

        if (account.box) {
          $("#box-account").text(account.box.mail_address);
          $("#link-box-button").hide();
          $("#unlink-box-button").show();
        } else {
          $("#box-account").text('');
          $("#link-box-button").show();
          $("#unlink-box-button").hide();
        }

        if (account.skydrive) {
          $("#skydrive-account").text(account.googledrive.mail_address);
          $("#link-skydrive-button").hide();
          $("#unlink-skydrive-button").show();
        } else {
          $("#skydrive-account").text('');
          $("#link-skydrive-button").show();
          $("#unlink-skydrive-button").hide();
        }

        loginStatus = true;
      }
      if (callback) callback();
    },
    error: function() {
      $("#dropbox-account").text('');
      $("#link-dropbox-button").show();
      $("#unlink-dropbox-button").hide();

      $("#googledrive-account").text('');
      $("#link-googledrive-button").show();
      $("#unlink-googledrive-button").hide();

      loginStatus = false;
      if (callback) callback();      
    }
  });
};

var getModifiedDate = function(wbFileInfo, callback) {
  var query;
  if (wbFileInfo.storage.name === 'dropbox') {
    query = wbFileInfo.parent.path + '/' + wbFileInfo.file.name;
  } else {
    query = wbFileInfo.file.id;
  }

  var accessAPI = api2[wbFileInfo.storage.name];
  accessAPI.getMetaData({
    query: query,
    success: function(metadata) {
      var modifiedDate = new Date(Date.parse(metadata.modified));
      callback(modifiedDate);
    },
    error: function() {
      callback(null);
    }
  });    
};

var startApp = function() {
  // enable setting of scrollbar show/hide
  if (navigator.userAgent.indexOf('Chrome') > 0 ||
      navigator.userAgent.indexOf('Safari') > 0) {
    $('#current-show-scrollbar').parent().show();
  } else {
    $('#current-show-scrollbar').parent().hide();      
  }

  if (isChromeApp()) {
    $('body').addClass('chrome-app');
    $('#download-text-menu').hide();
    $('#download-html-menu').hide();
    //$('#window-close-button').show();
    $('#window-close-button').click(function() {
      chrome.app.window.current().close();
    });
    $g('sessionKey', function(key) {
      api2.setSessionKey(key);      
    });
  }

  $('#header').css('visibility', 'visible');


  WriteboxFileStatus.load(function(wbFileInfo) {
    updateFileStatus(wbFileInfo);

    if (isCurrentFileEditing() === false) {
      $("#discard-button").addClass('disable');
    }

    if (wbFileInfo.storage.name !== '' && wbFileInfo.storage.name !== 'local') {
      getModifiedDate(wbFileInfo, function(latestModifiedDate) {
        if (latestModifiedDate) {
          var currentModifiedDate = new Date(Date.parse(wbFileInfo.file.modified));
          console.log(latestModifiedDate + ' ' + currentModifiedDate);
          if (latestModifiedDate > currentModifiedDate) {
            showSlidedownBar("#message-bar");
          }
        }
      });    
    }
  });

  layout();

  textStorage.resume(function() {
    var contents = textStorage.getContents();
    if (contents !== "") {
      $("textarea#editor").val(contents);
      updateStatisticsInfo(contents);
    }
  });

  $("textarea#editor").focus();
  buildRecentListMenu();

  var infoid = $("#writebox-info-dialog").attr('attr-infoid');
  if (infoid !== '') {
    $g('infoid', function(value) {
      if (infoid !== value) {
        showDialog({
          dialogId: "#writebox-info-dialog",
          okay: function() {
            $s('infoid', infoid);
          }
        });        
      }
    });
  }
};

var login = function() {
  api.login();

  /* for Chrome App
  api.loginWithNewTab(function() {
    account(function() {
      startApp();
      layout();
    });
  });
  */
};

var linkCloudService = function(service) {
  if (isChromeApp() === true) {
    var url = api2[service].getLinkUrl();

    var wv = document.querySelector('#link-window > webview');
    wv.addEventListener('loadstart', function(e) {
      //console.log(e);
    });
    wv.addEventListener('loadredirect', function(e) {
      console.log(e);
      if (e.newUrl.indexOf('http://10.write-box.appspot.com/key') === 0) {
        var returnKey = e.newUrl.replace('http://10.write-box.appspot.com/key?returnkey=','');
        if (returnKey) {
          $s('sessionKey', returnKey);
          api2.setSessionKey(returnKey);
        }
        $('#link-window').hide();
      }
    });

    $('#link-window > webview').attr('src', url)
    $('#link-window .cancel-button').click(function() {
      $('#link-window').hide();
    });

    $('#link-window').show();

  } else if (window.location.href.indexOf('chrome') === 0) {
    var api = api2[service];
    api.linkWithNewTab(function() {
      account();
    });
  } else {
    var api = api2[service];
    api.link();
  }
};

var unlinkCloudService = function(service, callback) {
  var api = api2[service];
  api.unlink({
    success: function() {
      callback()
    },
    error: function() {
    }
  });
};

var logout = function() {
  api.logout({
    success: function() {
      $("#account-menu").hide();
      $("#login-button").show();
      $("#sync-button").addClass("disable");
      layout();

      loginStatus = false;
    },
    error: function() {
    }
  });
};

var toggleSlidedownBar = function(id) {
  /*
  $(id)
    .css("left", 0)
    .css("top", $("#header").position().top + $("#header").height());
  */
  $(id).slideToggle(150, function() {
    $(id).css({'overflow':'visible'});
  });
};

var showSlidedownBar = function(selector) {
  $(selector).slideDown(150);
};

var hideSlidedownBar = function(selector) {
  $(selector).slideUp(150);
};

$(document).ready(function() {
  // layout
  layout();
  $(window).resize(function() {
    layout();
  });
  
  $(".pulldown").pulldown();
  $("[data-tooltip]").tooltip();
  $(".font-family-menu").each(function(i, item) {
    $(this).css("font-family", $(this).text());
  });
  $(".font-size-menu").each(function(i, item) {
    $(this).css("font-size", $(this).text());
  });

  // load preference data
  settingsModel.load();
  shortcuts.resume();

  // get account info
  account(function() {
    startApp();
    layout();
  });

  var handleShortcut = function() {

  };

  // event handler
  $(window).keydown(function(e) {
    if (e.ctrlKey || (e.metaKey && !e.ctrlKey)) { // ctrl or cmd
      if (!e.altKey) {
        if (e.shiftKey) { // Shift
          var c = String.fromCharCode(e.keyCode).toUpperCase();
          if (c ===  shortcuts.keys.preview) { //縲Ctrl(Cmd) + P
            if (isPreviewMode() === false) {
              previewMarkdown();
            }
            e.preventDefault();              
          } else if (c === shortcuts.keys.format_list) { // Ctrl(Cmd) + L
            insertTopOfLine('* ');
            e.preventDefault();
          }
        } else {
          var c = String.fromCharCode(e.keyCode).toUpperCase();
          if (c ===  shortcuts.keys.sync) { // Ctrl(Cmd) + S
            sync();
            e.preventDefault();
          } else if (c ===  shortcuts.keys.format_bold) { // Ctrl(Cmd) + B
            wrap('**');
            e.preventDefault();
          } else if (c ===  shortcuts.keys.format_italic) { // Ctrl(Cmd) + I
            wrap('*');
            e.preventDefault();
          }
        }
      }
    } else if (e.keyCode === 27) {  // esc
      if (isPreviewMode()) {
        hidePreview();
        e.preventDefault();
      }
    } else if (e.keyCode === 9) { // tab
      if (!e.altKey && !e.ctrlKey && !e.metaKey) {
        var tab = "    ";
        if (e.shiftKey) {
          deleteTopOfLine(tab);
        } else {
          insertTopOfLine(tab);
        }
        e.preventDefault();
      }
    }

  });


  $("textarea#editor").keyup(function(e) {
    //console.log(String.fromCharCode(e.keyCode));

    var prevcontents = textStorage.getContents();
    var contents = $("textarea#editor").val();
    textStorage.setContents(contents);

    if (prevcontents !== contents) {
      var wbFileInfo = WriteboxFileStatus.get();
      wbFileInfo.file.edit = true;
      updateFileStatus(wbFileInfo);
      $("#discard-button").removeClass('disable');

      if (menuVisibility === true) {
        $("#menu, #header, .slidedown-bar").animate({opacity:0.0},2000);
        menuVisibility = false;        
      }
    }
    updateStatisticsInfo(contents);

    /*
    if (menuVisibility) {
      console.log(e.ctrlKey);
      if (e.ctrlKey || (e.metaKey && !e.ctrlKey)) { // ctrl or cmd
        //if (!e.altKey && e.shiftKey) {
          return;
        //}
      }

      $("#menu, #header, .slidedown-bar").animate({opacity:0.0},2000);
      menuVisibility = false;
    }
    */
  });
  
  $("#menu, #header").hover(function() {
    $("#menu, #header, .slidedown-bar").animate({opacity:1.0},100);
    menuVisibility = true;
  });


  $("#new-button").click(function() {
    newText();
    $("textarea#editor").focus();
  });

  $("#load-button").click(function() {
    chooser.build('#chooser-dialog', 'open', loadCloudFile, confirmMoveToAuthProcess);
    showDialog({dialogId: '#chooser-dialog'});
    $('#file-name-input').focus();
  });

  $("#sync-button").click(function() {
    sync();
    _gaq.push(['_trackEvent', 'sync-button', 'clicked']);
  });

  $("#copy-html-menu").click(function() {
    /*
    var contents = $("textarea#editor").val();
    var wbFileInfo = WriteboxFileStatus.get();
    var html = templateHTML
      .replace('{{title}}', wbFileInfo.file.name)
      .replace('{{contents}}', marked(contents));
    */
  });

  $("#preview-markdown-button, #preview-markdown-menu").click(function() {
    if (isPreviewMode()) {
      hidePreview();
    } else {
      previewMarkdown();
    }
  });
     
  $("#preview-markdown-esc-message").click(function() {
    hidePreview();
  });

  $("#discard-button").click(function() {
    showDialog({
      dialogId: "#confirm-discard-text-dialog",
      okay: function() {
        createEmptyText();
      },
      cancel: function() {
        // do nothing...
      }
    });
  });

  $("#delete-local-data-button").click(function() {
    showDialog({
      dialogId: "#confirm-clear-local-data-dialog",
      okay: function() {
        $clear();

        $('#editor').val('');
        var wbLocalFileInfo = WriteboxFileInfo.createLocalFile();
        updateFileStatus(wbLocalFileInfo);
        updateStatisticsInfo();
        buildRecentListMenu();
      },
      cancel: function() {
        // do nothing...
      }
    });

  });

  $("#saveas-button").click(function() {
    var currentMimeType = WriteboxFileStatus.get().file.mimeType;
    selectCloudFile(function(wbFileInfo) {
      if (wbFileInfo.file.name !== '') {
        wbFileInfo.file.mimeType = currentMimeType;
        hideDialog();

        var contents = $("textarea#editor").val();
        saveFileContents(wbFileInfo, contents);

        updateFileStatus(wbFileInfo);
      } else {
        hideDialog();
      }
    });
  });

  $("#download-text-menu").click(function() {
    var contents = $("textarea#editor").val();
    var wbFileInfo = WriteboxFileStatus.get();

    downloadFile(wbFileInfo.file.name, contents, 'text/plain');
  });
  
  $("#download-markdown-menu").click(function() {
    var contents = $("textarea#editor").val();
    var wbFileInfo = WriteboxFileStatus.get();

    downloadFile(wbFileInfo.file.name, contents, 'text/markdown');
  });

  $("#download-html-menu").click(function() {
    var contents = $("textarea#editor").val();
    var wbFileInfo = WriteboxFileStatus.get();

    var tree = wbFileInfo.file.name.split('.');
    console.log(wbFileInfo.file.name + ' ' + tree.length);
    var fileName = '';
    if (tree.length > 0) {
      fileName = wbFileInfo.file.name.replace('.' + tree[tree.length-1], '.html');
      title = wbFileInfo.file.name.replace('.' + tree[tree.length-1], '');
    } else {
      fileName = wbFileInfo.file.name;
      title = fileName;
    }

    // Render HTML
    var templateHTML = $.ajax({
      url: '/template/template.html',
      async: false
    }).responseText;
    var html = templateHTML
      .replace('{{title}}', title)
      .replace('{{contents}}', marked(contents))
      .replace('{{color}}', settingsModel.textColor)
      .replace('{{backgroundColor}}', settingsModel.backgroundColor)
      .replace('{{fontFamily}}', settingsModel.fontFamily);

    downloadFile(fileName, html, 'text/html');
  });

  $("#about-button").click(function() {
    showDialog({dialogId: "#about-dialog"});
  });

  $("#option-button").click(function() {
    toggleSlidedownBar("#option-bar");
  });

  $("#shortcuts-setting-button").click(function() {
    for (k in shortcuts.keys) {
      $('.shortcuts[data-action=' + k + ']').val(shortcuts.keys[k]);
    }

    showDialog({
      dialogId: '#shortcuts-dialog',
      okay: function() {
        $('.shortcuts').each(function(i, item) {
          shortcuts.set($(item).attr('data-action'), $(item).val().toUpperCase());
        });
      }
    });
  });

  $(".shortcuts").keyup(function(e) {
    /*
    var c = $(this).val().charAt($(this).val().length-1);
    $(this).val(c);
    */
  });

  $('#restore-default-shortcuts').click(function() {
    shortcuts.restoreDefault();
  });

  $(".slidedown-bar .close-button").click(function() {
    hideSlidedownBar(".slidedown-bar");
  });
  
  $(".font-size-menu").click(function() {
    var fontSize = $(this).text();
    settingsModel.setFontSize(fontSize);
    layout();
  });

  $(".font-family-menu").click(function() {
    var fontFamily = $(this).text();
    if (fontFamily !== "") {
      settingsModel.setFontFamily(fontFamily);
      layout();
    }
  });

  $("#custom-font-family").keypress(function (e) {
    if (e.keyCode === 13) {
      var fontFamily = $(this).val();
      if (fontFamily !== "") {
        settingsModel.setFontFamily(fontFamily);
        layout();
        $(this).parent().parent().hide();
        $(this).val("");
      }
    }
  });

  $("#current-width").keypress(function(e) {
    if (e.keyCode === 13) {
      var width = $(this).val();
      settingsModel.setWidth(width);
    }
  });

  $("#current-line-height").keypress(function(e) {
    if (e.keyCode === 13) {
      var lineHeight = $(this).val();
      settingsModel.setLineHeight(lineHeight);
    }
  });

  $("#current-show-statics").change(function() {
    var status = $(this).attr("checked");
    settingsModel.setShowStatistics(status);
  });

  $("#current-show-scrollbar").change(function() {
    var status = $(this).attr("checked");
    settingsModel.setShowScrollbar(status);
  });

  $("#okcancel-dialog-disable").change(function() {
    var status = $(this).attr("checked");
    settingsModel.setPromptBeforeDiscarding(status);
  });

  $("#link-dropbox-button").click(function() {
    linkCloudService('dropbox');
  });

  $("#link-googledrive-button").click(function() {
    linkCloudService('googledrive');
  });

  $("#unlink-dropbox-button").click(function() {
    unlinkCloudService('dropbox', function() {
      account();
    });
  });

  $("#unlink-googledrive-button").click(function() {
    unlinkCloudService('googledrive', function() {
      account();
    });
  });

  $("#link-box-button").click(function() {
    linkCloudService('box');
  });

  $("#link-skydrive-button").click(function() {
    linkCloudService('skydrive');
  });

  $("#unlink-box-button").click(function() {
    unlinkCloudService('box', function() {
      account();
    });
  });

  $("#unlink-skydrive-button").click(function() {
    unlinkCloudService('skydrive', function() {
      account();
    });
  });


/*
  $("#logout-button").click(function() {
    logout();
    showOkCancelDialog({
      dialogid: "#confirm-clear-local-data-dialog",
      okay: function() {
        textStorage.init();
        recentList.clear();
        $("#filename")
          .attr('data-path','')
          .attr('data-tooltip','')
          .text('');
        $("textarea#editor").val('');
        //buildLocalMenu();
      },
      cancel: function() {
        // do nothing...
      }
    });
  });
*/

  $("#download-latest-button").click(function() {
    hideSlidedownBar("#message-bar");
    var wbFileInfo = WriteboxFileStatus.get();
    loadCloudFile(wbFileInfo);
  });
  
  $("#bg-color-picker").simpleColorPicker({
    onChangeColor: function(color) {
      settingsModel.setBackgroundColor(color);
    }
  });
  $("#front-color-picker").simpleColorPicker({
    onChangeColor: function(color) {
      settingsModel.setTextColor(color);
    }
  });

  $("#account-menu").click(function() {
    showDialog({dialogId: '#account-dialog'});
  });

  var savedWinBounds = null;
  $("#toggle-maximize-button").click(function() {
    if (chrome.app) {
      if (chrome.app.window.current().isMaximized() && savedWinBounds !== null) {
        chrome.app.window.current().setBounds(savedWinBounds);
      } else {
        savedWinBounds = chrome.app.window.current().getBounds();
        chrome.app.window.current().maximize();
      }
    }
  });

  var mediaQueryList = window.matchMedia('print');
  mediaQueryList.addListener(function(mql) {
    if (mql.matches) {
      //before print
      $('#print-window').show();
      $("#preview *")
        //.css('font-size', localStorage.fontSize)
        .css('font-family', settingsModel.fontFamily)
        .css('color', settingsModel.textColor);
      if (isPreviewMode() === true) {
        var previewHtml = $("#preview > div").html();
        $('#print-window > .contents').html(previewHtml);        
      } else {
        var html = "";
        var lines = $('#editor').val().split('\n');
        for (var i = 0; i < lines.length; i++) {
          html += (lines[i] + '<br/>');
        }        
        $('#print-window > .contents').html(html);
      }
    } else {
      //after print
      $('#print-window').hide();
    }
  });
});

var getServiceName = function(storageID) {
  switch (storageID) {
    case 'dropbox':
      return 'Dropbox';
    case 'googledrive':
      return 'Google Drive';
    case 'box':
      return 'Box';
    case 'skydrive':
      return 'Sky Drive';

    return ''
  }

};

var confirmMoveToAuthProcess = function(service) {
  var serviceName = getServiceName(service);

  $('#confirm-move-to-authorize-process .title').text('Link ' + serviceName + ' Account')
  
  showDialog({
    dialogId: "#confirm-move-to-authorize-process",
    okay: function() {
      linkCloudService(service);
    },
    cancel: function() {
      // do nothing...
    }
  });
};


var settingsModel = {
  fontSize: '',
  fontFamily: '',
  backgroundColor: '',
  textColor: '',
  width: '',
  lineHeight: '',
  showStatistics: '',
  showScrollbar: ''
};

settingsModel.setFontSize = function(fontSize) {
  this.fontSize = fontSize;
  $s('fontSize', fontSize);

  $("#current-font-size").text(fontSize);
  $("#editor").css("font-size",fontSize);
};

settingsModel.setFontFamily = function(fontFamily) {
  this.fontFamily = fontFamily;
  $s('fontFamily', fontFamily);

  $("#current-font-family").text(fontFamily);
  $("#editor").css("font-family",fontFamily);
};

settingsModel.setWidth = function(width) {
  this.width = width;
  $s('width', width);

  $("#current-width").val(width);
  layout();
};

settingsModel.setLineHeight = function(lineHeight) {
  this.lineHeight = lineHeight;
  $s('lineHeight', lineHeight);

  $("#current-line-height").val(lineHeight);
  $("#editor").css("lineHeight",lineHeight + "em");
};

settingsModel.setShowStatistics = function(status) {
  if (status) {
    this.showStatistics = 'show';
    $s('showStatics', 'show');

    $("#current-show-statics").attr("checked", true)
    $("#document-statistics").show();
  } else {
    this.showStatistics = 'hide';
    $s('showStatics', 'hide');

    $("#current-show-statics").attr("checked", false)
    $("#document-statistics").hide();
  }
};

settingsModel.setShowScrollbar = function(status) {
  if (status) {
    this.showScrollbar = 'show';
    $s('showScrollbar', 'show');

    $("#current-show-scrollbar").attr("checked", true)
    $('#editor, #preview').removeClass('off-scrollbar');
  } else {
    this.showScrollbar = 'hide';
    $s('showScrollbar', 'hide');

    $("#current-show-scrollbar").attr("checked", false)
    $('#editor, #preview').addClass('off-scrollbar');
  }
  layout();
};

settingsModel.setBackgroundColor = function(color) {
  this.backgroundColor = color;
  $s('backgroundColor', color);

  $("#bg-color-picker").css("background-color", color);
  $("body").css("background-color",color);
};

settingsModel.setTextColor = function(color) {
  this.textColor = color;
  $s('textColor', color);

  $("#front-color-picker").css("background-color", color);
  $("#editor, #editor-footer").css("color",color);
};

settingsModel.load = function() {
  var self = this;

  $g('fontSize', function(value) {
    if (value !== undefined && value !== '') {
      self.setFontSize(value);      
    }
  });

  $g('fontFamily', function(value) {
    if (value !== undefined && value !== '') {
      self.setFontFamily(value);      
    }
  });


  $g('width', function(value) {
    if (value !== undefined && value !== '') {
      self.setWidth(value);      
    }
  });


  $g('lineHeight', function(value) {
    if (value !== undefined && value !== '') {
      self.setLineHeight(value);      
    }
  });

  $g('backgroundColor', function(value) {
    if (value !== undefined && value !== '') {
      self.setBackgroundColor(value);      
    }
  });

  $g('textColor', function(value) {
    if (value !== undefined && value !== '') {
      self.setTextColor(value);      
    }
  });

  $g('showStatics', function(value) {
    if (value !== undefined && value !== '') {
      var status = (value === 'show') ? true : false;
      self.setShowStatistics(status);
    }
  });

  $g('showScrollbar', function(value) {
    if (value !== undefined && value !== '') {
      var status = (value === 'show') ? true : false;
      self.setShowScrollbar(status);      
    }
  });
};

var textStorage = {
  contents: ''
};

textStorage.resume = function(callback) {
  var self = this;

  $g('contents', function(value) {
    self.contents = value;
    callback();
  });
};

textStorage.setContents = function(contents) {
  this.contents = contents;
  $s('contents', contents);
};

textStorage.getContents = function() {
  return this.contents;
};


var shortcuts = {
  defaultKeys: {
    sync: 'S',
    preview: 'P',
    format_bold: 'B',
    format_italic: 'I',
    format_list: 'L'
  },
  keys: {
    sync: 'S',
    preview: 'P',
    format_bold: 'B',
    format_italic: 'I',
    format_list: 'L'
  }
};

shortcuts.resume = function() {
  $g('shortcuts', function(keys) {
    if (keys) {
      shortcuts.keys = JSON.parse(keys);
      for (k in shortcuts.keys) {
        $('.shortcuts[data-action=' + k + ']').val(shortcuts.keys[k]);
      }
    }
  });
};

shortcuts.set = function(action, char) {
  shortcuts.keys[action] = char;
  $s('shortcuts', JSON.stringify(shortcuts.keys));
};

shortcuts.restoreDefault = function() {
  $s('shortcuts', JSON.stringify(shortcuts.defaultKeys));
  shortcuts.resume();
};

var loadLocalFile = function(fileIndex) {
  var localFile = WriteboxLocalFileManagement.getFile(fileIndex);
  if (isCurrentFileEditing()) {
    saveCurrentFileOnLocal();
  }
  updateFileStatus(localFile.wbFileInfo);
  $("textarea#editor").val(localFile.contents);
  $("textarea#editor").focus();
    
  textStorage.setContents(localFile.contents);
  //textStorage.setEditingStatus('editing');
  $("#discard-button").removeClass('disable');

  updateStatisticsInfo(localFile.contents);
};


var buildRecentListMenu = function() {
  var ul = $("#recent-button").children("ul");
  $(ul).empty();

  var list = WriteboxRecentFileList.getAll();
  for (var i = list.length - 1; i >= 0; i-=1) {
    var wbFileInfo = list[i];

    var li = document.createElement("li"),
        icon = document.createElement("img"),
        container = document.createElement("div"),
        name = document.createElement("div");

    if (wbFileInfo.storage.name === 'dropbox') {
      $(icon).attr('src', '/image/storage/dropbox_icon.png');
    } else if (wbFileInfo.storage.name === 'googledrive') {
      $(icon).attr('src', '/image/storage/drive_icon.png');
    } else if (wbFileInfo.storage.name === 'box') {
      $(icon).attr('src', '/image/storage/box_icon.png');
    } else if (wbFileInfo.storage.name === 'skydrive') {
      $(icon).attr('src', '/image/storage/skydrive_icon.png');
    }

    $(icon).addClass('storage-icon');

    $(name)
      .addClass("recent-title")
      .append(wbFileInfo.file.name);

    var fileID = '';
    if (wbFileInfo.storage.name === 'dropbox') {
      fileID = wbFileInfo.parent.path + '/' + wbFileInfo.file.name;
    } else if (wbFileInfo.storage.name === 'googledrive') {
      fileID = wbFileInfo.file.name;
    }
    
    $(container)
      .addClass("recent-item")
      .attr('data-index', i)
      .append(icon)
      .append(name);

    $(container).click(function() {
      $(".pulldown-bg-layer").remove();
      $(this).parent().parent().toggle();

      var fileInfoIndex = $(this).attr("data-index");
      var fileInfo = list[fileInfoIndex];
      loadCloudFile(fileInfo);
    });

    $(li).append(container);
    $(ul).append(li);
  }

  if (list.length > 0) {
    $("#recent-button").removeClass("disable");
  } else {
    $("#recent-button").addClass("disable");
  }
};

var toThreeDigit = function(num) {
  var r=[], nums=num.toString().split("").reverse(), l=nums.length;
  nums.forEach(function(c,i) {
    r.push(c);
    if ((i+1)%3 === 0 && i !== l-1 && c !== '-') r.push(',');
  });
  return r.reverse().join("");
};

var updateStatisticsInfo = function(contents) {
  if (contents) {
    var l = contents.length;
    var word_count = contents.split(/\S+/g).length-1;
    var char_count = contents.replace(/\n/g,"").length;
    var lf_count = l - char_count + 1;
    $("#line-count").text(toThreeDigit(lf_count));
    $("#word-count").text(toThreeDigit(word_count));
    $("#char-count").text(toThreeDigit(char_count));
  } else {
    $("#line-count").text('-');
    $("#word-count").text('-');
    $("#char-count").text('-');
  }
};

var showLocalStorageErrorDialog = function(discardAcceptable) {
  var dialogId = '#error-localstorage-dialog';

  if (discardAcceptable) {
    $(dialogId).find('.okay-button').show();    
  } else {
    $(dialogId).find('.okay-button').hide();
  }

  showDialog({
    dialogId: dialogId,
    okay: function() {
      createEmptyText();
    },
    cancel: function() {
      // do nothing..
    }
  });        
};


// for preferences
//var chrome = null;
var $g = function(key, callback) {
  if (!callback) {
    return 
  }

  if (chrome && chrome.storage) {
    chrome.storage.local.get(key, function(items) {
      callback(items[key]);
    });
  } else {
    callback(localStorage[key]);
  }

};

var $s = function(key, data) {
  if (chrome && chrome.storage) {
    var obj = {};
    obj[key] = data;
    chrome.storage.local.set(obj);
  } else {
    try {
      localStorage.setItem(key, data);
    } catch(e) {
      showLocalStorageErrorDialog(false);
    }    
  }
};

var $clear = function() {
  if (chrome && chrome.storage) {
    chrome.storage.local.clear();
  } else {
    localStorage.clear();
  }
};



WriteboxRecentFileList = {};
WriteboxRecentFileList.push = function(wbFileInfo) {
  var wbFileList = this.getAll();
  // delete same id
  for (var i = 0; i < wbFileList.length; i+=1) {
    var recent = wbFileList[i];
    if ((recent.storage.name === wbFileInfo.storage.name) &&
        (recent.file.id === wbFileInfo.file.id)) {
      wbFileList.splice(i,1);      
    }
  }

  // push last
  wbFileList.push(wbFileInfo);

  // only 10
  if (wbFileList.length > 10) {
    wbFileList.splice(0,1); // delete oldest item
  }

  $s('recentList', JSON.stringify(wbFileList));
};

WriteboxRecentFileList.deleteAllHistory = function() {
  $s('recentList', JSON.stringify([]));
};

WriteboxRecentFileList.getAll = function() {
  var allList = [];
  $g('recentList', function(list) {
    if (list) {
      var list = JSON.parse(list);
        for (var i = 0; i < list.length; i++) {
        if (list[i].path) {
          // old version data
          var parentFolderPath = list[i].path.replace('/'+list[i].name,'');
          var wbFileInfo = WriteboxFileInfo.create('dropbox',
                                                    list[i].name,
                                                    list[i].path, // id
                                                    '',
                                                    '',
                                                    parentFolderPath);
          allList.push(wbFileInfo);
        } else {
          allList.push(list[i]);
        }
      }
    }
  });

  return allList;
};


var downloadFile = function(fileName, data, type) {
  var blob = new Blob([data], { type: type + '; charset=utf-8'});
  window.saveAs(blob, fileName);
};

