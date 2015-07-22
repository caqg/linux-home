var isChromeApp = function() {
  var browserName = getBrowser();
  if (browserName === 'chrome' && chrome && chrome.storage) {
    return true;
  } else {
    return false;
  }
};

// http://qiita.com/Evolutor_web/items/162bfcf83695c83f1077
var getBrowser = function(){
    var ua = window.navigator.userAgent.toLowerCase();
    var ver = window.navigator.appVersion.toLowerCase();
    var name = 'unknown';

    if (ua.indexOf("msie") != -1){
        if (ver.indexOf("msie 6.") != -1){
            name = 'ie6';
        }else if (ver.indexOf("msie 7.") != -1){
            name = 'ie7';
        }else if (ver.indexOf("msie 8.") != -1){
            name = 'ie8';
        }else if (ver.indexOf("msie 9.") != -1){
            name = 'ie9';
        }else if (ver.indexOf("msie 10.") != -1){
            name = 'ie10';
        }else{
            name = 'ie';
        }
    }else if(ua.indexOf('trident/7') != -1){
        name = 'ie11';
    }else if (ua.indexOf('chrome') != -1){
        name = 'chrome';
    }else if (ua.indexOf('safari') != -1){
        name = 'safari';
    }else if (ua.indexOf('opera') != -1){
        name = 'opera';
    }else if (ua.indexOf('firefox') != -1){
        name = 'firefox';
    }
    return name;
};
var menuVisibility = true;
var loginStatus = false;
var editorFocused = true;
var findController = new FindControl();
var PADDING_FULLSCREEN = isChromeApp() ? 30 : 10;


var pushGAQ = function(data) {
  if (isChromeApp() === false) {
    _gaq.push(data);
  }

};

if (isChromeApp() === false) {
  var _gaq = _gaq || [];
  pushGAQ(['_setAccount', 'UA-27635130-2']);
  pushGAQ(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = 'https://ssl.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();  
}

if (navigator.userAgent.indexOf('Chrome') < 0) {
  chrome = null;
} 

var layout = function() {
  //console.log('window:' + $(window).width() + ' ' +  $(window).height());

  // Editor
  var width = 0, padding = 0, bar = 0;
  $g('width', function(settingWidth) {
    settingWidth = parseInt(settingWidth) || 800;
    if ($(window).width() < 800 + PADDING_FULLSCREEN) {
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
    $('#editor > div.contents').height($('#eidtor').height()-10);

    //if (isChromeApp() === false) {
    //  if ($(window).width() < 800) {
    //    $('#editor-footer, #header > #menu, .slidedown-bar > .container')
    //      .css("margin-left", 0)
    //      .css("padding-right", 0)
    //      .width(width + padding*2);
    //  } else {
    //    $('#editor-footer, #header > #menu, .slidedown-bar > .container')
    //      .css("margin-left", padding)
    //      .css("padding-right", padding)
    //      .width(width + padding);        
    //  }
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


    // hidden textarea for FIND
    findController.layoutEditorHighlightArea();

    layoutLinkWindow();
  });
};

var layoutLinkWindow = function() {
  var t = 20, l = 50;
  var w = $(window).width() - l * 2, h = $(window).height() - t * 2;

  $('#link-window')
    .css('width', w)
    .css('height', h)
    .css('top', t)
    .css('left', l);

  $('#link-window > webview').css('height', h - $('#link-window > webview').position().top);

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
  setEditorValue('');
  $s('contents','');

  updateStatisticsInfo();
  //textStorage.setEditingStatus('no-editing');
  $("#discard-button").addClass('disable');
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

var saveCurrentFileOnLocal = function(callback) {
  var wbFileInfo = WriteboxFileStatus.get(),
      contents = textStorage.getContents();

  WriteboxLocalFileManagement.saveFile(wbFileInfo, contents, function(result) {
    showProcessingMessage('File saved locally.','processing');
    hideProcessingMessage('processing');

    callback(result);

  });
};

var newText = function() {
  if (isCurrentFileEditing()) {
    saveCurrentFileOnLocal(function(result) {
      if (result) {
        createEmptyText();
      } else {
        // Do Nothing..
      }
    });
  } else {
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
      $("#filename img").attr('src', '/image/storage/drive_icon.png');
      $("#filename img").addClass('show');
      break;
    case 'box':
      $("#filename img").attr('src', '/image/storage/box_icon.png');
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
  var prevContents = getEditorValue();

  hideDialog();
  setEditorValue('Loading...');

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

      var reflectFile = function(wbFileInfo, text) {
        wbFileInfo.file.mimeType = mimeType;
        wbFileInfo.file.modified = modifiedDate;
        updateFileStatus(wbFileInfo);

        setEditorValue(text);
        textStorage.setContents(text);
        WriteboxRecentFileList.push(wbFileInfo, function() {
          buildRecentListMenu();        
        });

        updateStatisticsInfo();
      };

      if (isCurrentFileEditing()) {
        saveCurrentFileOnLocal(function(result) {
          if (result) {
            reflectFile(wbFileInfo, text);
          } else {
            // Role Back
            setEditorValue(prevContents);
          }
        });
      } else {
        reflectFile(wbFileInfo, text);
      }

    },
    error: function() {
      setEditorValue(prevContents);
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
    var contents = getEditorValue();
    saveFileContents(WriteboxFileStatus.get(), contents);

  } else {
    selectCloudFile(function(wbFileInfo) {
      if (wbFileInfo.file.name !== '') {
        hideDialog();

        var contents = getEditorValue();
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
  var markdown = marked(getEditorValue());

  $("#preview > div").html(markdown)

  $("#markdown-preview-window, #preview")
    .css("background",settingsModel.backgroundColor);

  $("#preview *")
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

var getSelectionStringLen = function() {
  var t = document.getElementById("editor");
  var at = t.selectionStart,
      end = t.selectionEnd,
      len = end - at;

  return len;
};

var wrap = function(token1, token2) {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd,
      len = end - at;
  token2 = token2 || token1;

  if (at !== end) {
    t.value = tdata.substring(0, at) + token1 + tdata.substring(at, end) + token2 + tdata.substring(end, t.value.length);
    t.selectionStart = at + token.length;
    t.selectionEnd = t.selectionStart + len;
  } else {
    t.value = tdata.substring(0, at) + token1 + token2 + tdata.substring(end, t.value.length);
    t.selectionStart = at + token1.length;
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
  // t1
  t1 = tdata.substr(0, at);
  // search previous \n
  var returnPos = t1.lastIndexOf('\n');
  if (returnPos > 0) {
    at = returnPos + 1;
    len = end-at-1;
    t1 = tdata.substr(0, at);
  }

  // t2
  if (len > 0) {
    // selected
    t2 = str + tdata.substr(at, len).split("\n").join("\n"+str) + tdata.substr(end-1,1);
  } else {
    t2 = str;
  }

  // t3
  t3 = tdata.substr(end, tdata.length);

  // t1 + t2 + t3
  t.value = t1 + t2 + t3;

  var cursorStart, cursorEnd;
  if (len > 0) {
    // selected
    cursorStart = at;
    cursorEnd = cursorStart + t2.length;
  } else {
    cursorStart = str.length + at;
    cursorEnd = cursorStart;
  }

  t.setSelectionRange(cursorStart, cursorEnd);
};

var insertLinkFormat = function() {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd,
      len = end-at;

　var t1, t2, t3;
  t1 = tdata.substr(0, at);
  t2 = tdata.substr(at, len);
  t3 = tdata.substr(end, tdata.length-end);

  t.value = t1 + '[' + t2 + ']()' + t3;

  var cursorPos;
  if (len > 0) {
    cursorPos = end + 3;
  } else {
    cursorPos = end + 1;
  }
  t.setSelectionRange(cursorPos, cursorPos);
};

var getSelectedEditorValue = function() {
  var t = document.getElementById("editor");
  var tdata = t.value,
      at = t.selectionStart,
      end = t.selectionEnd;

  return tdata.substr(at, end-at);
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

var showProcessingMessage = function(message, cssClassName) {
  $('#processing-message')
    .css('position', 'absolute')
    .css('bottom', -30)
    .show();
  $('#processing-message').animate({bottom: 0}, 500);

  $('#processing-message').text(message);
  $('#processing-message').addClass(cssClassName);
};

var hideProcessingMessage = function(cssClassName) {
  setTimeout(function() {
    $('#processing-message').animate({bottom: -30}, 500, function() {
      $('#processing-message').text('');
      $('#processing-message').removeClass(cssClassName);
      $('#processing-message').hide();
    });
  }, 2000);
};

var saveFileContents = function(wbFileInfo, contents) {
  showProcessingMessage('Syncing...', 'processing');

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
      hideProcessingMessage('processing');
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
      hideProcessingMessage('processing');
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

  $('body').addClass('chrome-app');
  if (isChromeApp()) {
    $('#download-text-menu').hide();
    $('#download-html-menu').hide();
    $('#window-close-button').click(function() {
      chrome.app.window.current().close();
    });
  } else {
    $('#print-button').hide();
    $('#fullscreen-button').hide();
    $('#find-button').hide(); 
    $('#find-button').next().hide(); 
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
      setEditorValue(contents);
      updateStatisticsInfo();
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
          close: function() {
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
    editorFocused = false;

    var url = api2[service].getLinkUrl();

    var wv = document.querySelector('#link-window > webview');
    wv.addEventListener('loadstart', function(e) {
      $('#link-window-header > .message').text('Loading...');
    });
    wv.addEventListener('loadstop', function(e) {
      $('#link-window-header .message').text('');
    });
    wv.addEventListener('loadredirect', function(e) {
      $('#link-window-header .message').text('Loading...');
      if (e.newUrl.indexOf(api2.host + '/key') === 0) {
        var returnKey = e.newUrl.replace(api2.host + '/key?returnkey=','');
        if (returnKey) {
          $s('sessionKey', returnKey);
          api2.setSessionKey(returnKey);
        }
        $('#link-window').hide();
        account();
        editorFocused = true;
      }
    });

    $('#link-window > webview').attr('src', url)
    $('#link-window .cancel-button').click(function() {
      $('#link-window').hide();
      editorFocused = true;
    });


    $('#link-window').show();
    layoutLinkWindow();
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
  showProcessingMessage('Unlinking...', 'processing');
  api.unlink({
    success: function() {
      callback();
      hideProcessingMessage();
    },
    error: function() {
      hideProcessingMessage();
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

var toggleFullscreenMode = function() {
  if (chrome.app.window.current().isFullscreen()) {
    chrome.app.window.current().restore();
  } else {
    chrome.app.window.current().fullscreen();      
  }
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
  findController.init();


  if (isChromeApp()) {
    $g('sessionKey', function(key) {
      api2.setSessionKey(key);      
      account(function() {
        startApp();
        layout();
      });    
    });
  } else {
    // get account info
    account(function() {
      startApp();
      layout();
    });    
  }

  $(window).keyup(function(e) {
    if (e.keyCode === 27) { // esc
      if (isPreviewMode()) {
        console.log(e.keyCode);
        hidePreview();
        e.preventDefault();
      }
    }
  });

  // event handler
  $(window).keydown(function(e) {
    if (editorFocused) {
      if (e.ctrlKey || (e.metaKey && !e.ctrlKey)) { // ctrl or cmd
        if (!e.altKey) {
          if (e.shiftKey) { // Shift
            var c = String.fromCharCode(e.keyCode).toUpperCase();
            if (c ===  shortcuts.keys.preview) { //Ctrl(Cmd) + P
              if (isPreviewMode() === false) {
                previewMarkdown();
              } else {
                hidePreview();
              }
              e.preventDefault();
            } else if (c === shortcuts.keys.statistics) { // Ctrl(Cmd) + K
              var status = (settingsModel.showStatistics === 'show') ? true : false;
              settingsModel.setShowStatistics(!status);
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
            } else if (c === shortcuts.keys.format_list) { // Ctrl(Cmd) + L
              insertTopOfLine('* ');
              e.preventDefault();
            } else if (c === shortcuts.keys.format_link) { // Ctrl(Cmd) + K
              insertLinkFormat();
              e.preventDefault();
            } else if (c === shortcuts.keys.find && isChromeApp() === true) {  // Ctrl(Cmd) + F
              findController.toggleFindMode();
              e.preventDefault();
            } else if (c === 'P' && isChromeApp() === true) {
              window.print();
              e.preventDefault();
            } else if (e.keyCode === 13) {
              toggleFullscreenMode();
              e.preventDefault();
            }
          }
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
    }

    if (e.keyCode === 27) { // esc
      e.preventDefault();
    }

  });


  $("textarea#editor").keyup(function(e) {
    //console.log(String.fromCharCode(e.keyCode));

    var prevcontents = textStorage.getContents();
    var contents = getEditorValue();
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
    //updateStatisticsInfo(contents);

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

  document.onselectionchange = function() {
    console.log("Selection changed");
    updateStatisticsInfo();
  };
  
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
    pushGAQ(['_trackEvent', 'sync-button', 'clicked']);
  });

  $("#print-button").click(function() {
    window.print();
  });

  $("#fullscreen-button").click(function() {
    toggleFullscreenMode();
  });

  $("#find-button").click(function() {
    findController.toggleFindMode();
  });

  $("#find-next-button").click(function() {
    findController.findNext();
  });

  $("#find-prev-button").click(function() {
    findController.findPrevious();
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

        setEditorValue('');
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

        var contents = getEditorValue();
        saveFileContents(wbFileInfo, contents);

        updateFileStatus(wbFileInfo);
      } else {
        hideDialog();
      }
    });
  });

  $("#download-text-menu").click(function() {
    var contents = getEditorValue();
    var wbFileInfo = WriteboxFileStatus.get();

    downloadFile(wbFileInfo.file.name, contents, 'text/plain');
  });
  
  $("#download-markdown-menu").click(function() {
    var contents = getEditorValue();
    var wbFileInfo = WriteboxFileStatus.get();

    downloadFile(wbFileInfo.file.name, contents, 'text/markdown');
  });

  $("#download-html-menu").click(function() {
    var contents = getEditorValue();
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

  $("#current-show-statistics").change(function() {
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
        //.css('font-size', settingsModel.fontSize)
        .css('font-family', settingsModel.fontFamily)
        .css('color', settingsModel.textColor);
      if (isPreviewMode() === true) {
        var previewHtml = $("#preview > div").html();
        $('#print-window > .contents').html(previewHtml);        
      } else {
        var html = "";
        var lines = getEditorValue().split('\n');
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
    format_list: 'L',
    format_link: 'K',
    find: 'F',
    statistics: 'K'
  },
  keys: {
    sync: 'S',
    preview: 'P',
    format_bold: 'B',
    format_italic: 'I',
    format_list: 'L',
    format_link: 'K',
    find: 'F',
    statistics: 'K'
  }
};

shortcuts.resume = function() {
  $g('shortcuts', function(keys) {
    if (keys) {
      var savedKeys = JSON.parse(keys);
      for (k in savedKeys) {
        shortcuts.keys[k] = savedKeys[k];
      }

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
  WriteboxLocalFileManagement.getFile(fileIndex, function(localFile) {
    if (isCurrentFileEditing()) {
      saveCurrentFileOnLocal(function(result) {

      });
    }
    updateFileStatus(localFile.wbFileInfo);
    setEditorValue(localFile.contents)
    $("textarea#editor").focus();
      
    textStorage.setContents(localFile.contents);
    //textStorage.setEditingStatus('editing');
    $("#discard-button").removeClass('disable');

    updateStatisticsInfo();
  });
};


var buildRecentListMenu = function() {
  var ul = $("#recent-button").children("ul");
  $(ul).empty();

  WriteboxRecentFileList.getAll(function(list) {
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
  });
};

var toThreeDigit = function(num) {
  var r=[], nums=num.toString().split("").reverse(), l=nums.length;
  nums.forEach(function(c,i) {
    r.push(c);
    if ((i+1)%3 === 0 && i !== l-1 && c !== '-') r.push(',');
  });
  return r.reverse().join("");
};

var updateStatisticsInfo = function() {
  var contents = getEditorValue();

  if (getSelectionStringLen() > 0) {
    $('#document-statistics > .normal').hide();
    $('#document-statistics > .selected').show();
    var selectedValue = getSelectedEditorValue();
    console.log(selectedValue);
    var selected_word_count = selectedValue.split(/\S+/g).length-1;
    var selected_char_count = selectedValue.replace(/\n/g,"").length;
    $('#selected-word-count').text(toThreeDigit(selected_word_count));
    $('#selected-char-count').text(toThreeDigit(selected_char_count));
  } else {
    $('#document-statistics > .normal').show();
    $('#document-statistics > .selected').hide();
    if (contents !== '') {
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

/*
var showOkCancelDialog = function(p) {
  $(p.dialogid).find('.ok-button').click(function() {
    hideDialog(p.dialogid);
    $(p.dialogid).find('.ok-button').unbind('click');
    p.okay();
  });
  $(p.dialogid).find('.cancel-button').click(function() {
    hideDialog(p.dialogid);
    $(p.dialogid).find('.cancel-button').unbind('click');
    p.cancel();
  });

  showDialog(p.dialogid, function() {
    $(p.dialogid).find('.ok-button').unbind('click');
    $(p.dialogid).find('.cancel-button').unbind('click');    
  });
}
*/

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

var $s = function(key, data, callback) {
  if (chrome && chrome.storage) {
    var obj = {};
    obj[key] = data;
    chrome.storage.local.set(obj, function() {
      if (callback) {
        callback();
      }
    });
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

var WriteboxChooser = {};
var chooser = WriteboxChooser;

WriteboxChooser.build = function(dialogID, feature, selectedCallback, authorizeErrorCallback) {
  var self = this;

  self.dialogID = dialogID;
  self.feature = feature;
  self.selectedCallback = selectedCallback;
  self.authorizeErrorCallback = authorizeErrorCallback;

  // init variables
  self.currentStorage = 'local';
  self.currentFile = {
    dropbox: {id:'/', name:'Dropbox'},
    googledrive: {id:'root', name:'Google Drive'},
    skydrive: {id: '/', name: 'SkyDrive'},
    box: {id: '/', name: 'Box'}
  };
  self.currentFolderNavList = {
    dropbox: [],
    googledrive:[],
    skydrive: [],
    box: []
  };

  // init component
  self._emptyFileList('dropbox');
  self._emptyFileList('googledrive');
  self._emptyFileList('skydrive');
  self._emptyFileList('box');
  self._buildEventHandler();

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
};

WriteboxChooser._saveChooserStatus = function() {
  $s('chooser', JSON.stringify({
    storage: this.currentStorage,
    file: this.currentFile,
    folderNavList: this.currentFolderNavList
  }));
};

WriteboxChooser._loadChooserStatus = function(callback) {
  var self = this;
  $g('chooser', function(chooserStatus) {
    if (chooserStatus) {
      chooserStatus = JSON.parse(chooserStatus);
      self.currentStorage = chooserStatus.storage;
      self.currentFile = chooserStatus.file;
      self.currentFolderNavList = chooserStatus.folderNavList;
    }
    callback();
  });
};


WriteboxChooser.deleteChooserStatus = function() {
  $s('chooser', JSON.stringify({
    storage: 'local',
    file: {
      id: '',
      name: ''
    },
    folderNavList: []
  }));
};

WriteboxChooser._buildEventHandler = function() {
  var self = this;

  // side menu click event (switching storage)
  $(self.dialogID + ' .chooser-storagelist').unbind();
  $(self.dialogID + ' .chooser-storagelist').click(function() {
    var li = this;

    var storage = $(li).attr("data-storage");
    self._switchStorage(storage);
  });
};

WriteboxChooser._switchStorage = function(storage) {
  this.currentStorage = storage;

  // switch filelist elem
  $(this.dialogID + ' .chooser-filelist').hide();
  $(this.dialogID + ' .chooser-filelist[data-storage=' + this.currentStorage + ']').show();

  // switch selection mark
  $(this.dialogID + ' .chooser-storagelist').removeClass("selection");
  $(this.dialogID + ' .chooser-storagelist[data-storage=' + this.currentStorage + ']').addClass("selection");

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

WriteboxChooser.buildOpenUI = function() {
  $("#chooser-dialog .title").text("Select text file..");
  $("li[data-storage=local]").show();
  $("#chooser-save-form").hide();

  $("#chooser-dialog .bottombar").hide();
};

WriteboxChooser.buildSaveUI = function() {
  var self = this;

  $("#chooser-dialog .title").text("Save as..");
  $("li[data-storage=local]").hide();
  $("#chooser-save-form").show();
  $("#chooser-save-form input").focus();
  $("li[data-storage=" + this.currentStorage + "]").click();

  $("#chooser-save-button").unbind('click');
  $("#chooser-save-button").click(function() {
    var fileName = $('#chooser-save-form input').val()
    var parent = self._getCurrentFolder();
    var fileInfo = WriteboxFileInfo.create(self.currentStorage, fileName, '',
                                           parent.folderName, parent.folderID, self._getCurrentFolderPath());
    console.log(self.currentFolderNavList);
    console.log(fileInfo);
    self.selectedCallback(fileInfo);
  });

  $("#chooser-save-form input").unbind('keypress');
  $("#chooser-save-form input").keypress(function(e) {
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

  $("#chooser-dialog .bottombar").show();
};

WriteboxChooser._emptyFileList = function(storage) {
  $(this.dialogID + ' .chooser-filelist[data-storage=' + storage + ']').empty();
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

    var accessAPI = api2[storage];
    accessAPI.getFiles({
      query: fileID,
      success: function(files) {
        self._buildCloudFileListUI(storage, files);
        self.currentFile[storage] = {id: fileID, name: fileName};
        self._saveChooserStatus();

        if (files.length === 0) {
          self._addEmptyFolderMessage();
        }
      },
      error: function(errorStatus) {
        var fileList = $(self.dialogID + ' .chooser-filelist[data-storage=' + storage + ']');
        $(fileList).empty();

        var li = document.createElement('li');
        $(fileList).append(li);

        if (errorStatus === 401) {
          $(li).text('Authorization error');
          if (self.authorizeErrorCallback) self.authorizeErrorCallback(storage);
        } else if (errorStatus === 404) {
          $(li).text('File path not found');
        } else {
          $(li).text('Load error');          
        }
      }
    });
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
        if (f.mimeType.substring(0,4) === "text" || f.mimeType === "application/octet-stream") {
          var li = self._createCloudFileListItem(f);
          $(fileList).append(li);
        }
      }
    }    
  }
};

WriteboxChooser._createCloudFileListItem = function(obj) {
  var self = this;

  var icon = document.createElement("img");
  if (obj.type === 'folder') {
    $(icon).attr("src","/image/chooser/folder.png");
  } else {
    $(icon).attr("src","/image/chooser/file.png");
  }

  var li = document.createElement("li");
  $(li)
    .attr("data-objtype",obj.type)
    .attr("data-fileid", obj.fileID)
    .attr("data-filestorage",obj.storage)
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
    var span = document.createElement("span");
    $(span)
      .attr("data-folderid", navList[i].folderID)
      .append(navList[i].folderName);

    $(span).click(function() {
      self._choose(self.currentStorage, $(this).attr("data-folderid"), $(this).text());
    });

    if (i > 0) {
      $(self.dialogID + ' .chooser-navigator')
        .append(" > ")
        .append(span);
    } else {
      $(self.dialogID + ' .chooser-navigator')
        .append(" ")
        .append(span);
    }
  }
};

WriteboxChooser._updateLocalFileCount = function() {
  var self = this;

  WriteboxLocalFileManagement.getFiles(function(list) {
    $(self.dialogID + ' .chooser-storagelist[data-storage=local]').text('Drafts (' + list.length + ')');    
  });
};

WriteboxChooser._buildLocalFileListUI = function() {
  var self = this;

  var ul = $(this.dialogID + ' .chooser-filelist[data-storage=local]')
  $(ul).empty();
  
  WriteboxLocalFileManagement.getFiles(function(list) {
    for (var i = list.length - 1; i >= 0; i-=1) {
      //console.log(list[i]);
      var li = self._createLocalFileListItem(list[i].wbFileInfo, list[i].contents, i);
      $(ul).append(li);
    }    
  });
  
  this._updateLocalFileCount();
};

WriteboxChooser._createLocalFileListItem = function(wbFileInfo, contents, index) {
  var self = this;

  var li = document.createElement("li"),
      container = document.createElement("div"),
      name = document.createElement("div"),
      deletebutton = document.createElement("button");

  var icon = document.createElement("img");
  $(icon).attr("src","/image/chooser/file.png");

  var title = "";
  if (wbFileInfo.file.name !== "") {
    title = wbFileInfo.file.name;
  } else {
    var tmp = contents.replace(/^\s+/, "");
    title = tmp.substr(0,30);
    if (title === '') {
      title = '&lt;No Contents&gt;';
    }
  }

  $(name)
    .addClass("file")
    .attr("data-i",index)
    .append(title);

  $(deletebutton)
    .attr('data-fileid', wbFileInfo.file.id)
    .addClass('button')
    .append("Discard");

  $(container)
    .append(name)
    .append(deletebutton);

  $(name).click(function() {
    loadLocalFile(index);
    hideDialog();
  });

  $(deletebutton).click(function() {
    WriteboxLocalFileManagement.deleteFile(index);
    self._updateLocalFileCount();

    $(li).slideUp(200,function() {
      $(li).remove();
    });
  });

  $(li).append(container);

  return li;
};



var WriteboxFileInfo = {};
WriteboxFileInfo.create = function(storageName, fileName, fileID,
                                   parentFolderName, parentFolderID, parentFolderPath) {
  return {
    storage: {
      name: storageName
    },
    file: {
      name: fileName,
      id: fileID,
      modified: '',
      edit: false,
      mimeType: 'text/plain'
    },
    parent: {
      name: parentFolderName,
      id: parentFolderID,
      path: parentFolderPath
    }
  };
};

WriteboxFileInfo.createLocalFile = function() {
  return {
    storage: {
      name: 'local'
    },
    file: {
      name: '',
      id: 'localid-' + (new Date()).getTime() + ' ' + Math.floor(Math.random()*255+1),
      modified: '',
      edit: false
    },
    parent: {
      name: '',
      id: '',
      path: ''
    }
  };

};

var WriteboxFileStatus = {};
WriteboxFileStatus._currentFileInfo = null;

WriteboxFileStatus.save = function(wbFileInfo) {
  this._currentFileInfo = wbFileInfo;
  $s('wbFileInfo', JSON.stringify(wbFileInfo));
};

WriteboxFileStatus.load = function(callback) {
  var self = this;
  $g('wbFileInfo', function(wbFileInfo) {
    if (wbFileInfo) {
      self._currentFileInfo = JSON.parse(wbFileInfo);
    } else {
      self._currentFileInfo = WriteboxFileInfo.create('', '', '', '', '', '');
    }

    if (callback) {
      callback(self._currentFileInfo);
    }
  });

  /*
  if ($g('wbFileInfo')) {
    this._currentFileInfo = JSON.parse($g('wbFileInfo'));
  } else if ($g('dp_filename')) {
    var parentFolderPath = $g('textid').replace('/'+ $g('dp_filename'),'');
    this._currentFileInfo = WriteboxFileInfo.create($g('storage'),
                                                    $g('dp_filename'),
                                                    $g('textid'),
                                                    '',
                                                    '',
                                                    parentFolderPath);
    if ($g('editing_status') === 'editing') {
      this._currentFileInfo.file.edit = true;
    }
  } else {
    this._currentFileInfo = WriteboxFileInfo.create('', '', '', '', '', '');
  }

  return this._currentFileInfo;
  */
};

WriteboxFileStatus.get = function() {
  return this._currentFileInfo;
};


WriteboxRecentFileList = {};
WriteboxRecentFileList.push = function(wbFileInfo, callback) {
  this.getAll(function(wbFileList) {
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

    $s('recentList', JSON.stringify(wbFileList), callback);
  });
};

WriteboxRecentFileList.deleteAllHistory = function() {
  $s('recentList', JSON.stringify([]));
};

WriteboxRecentFileList.getAll = function(callback) {
  var allList = [];
  $g('recentList', function(list) {
    if (list) {
      var list = JSON.parse(list);
      for (var i = 0; i < list.length; i++) {
        console.log(list[i]);
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
    callback(allList);
  });
};

WriteboxLocalFileManagement = {};
WriteboxLocalFileManagement.saveFile = function(wbFileInfo, contents, callback) {
  var self = this;

  this.getFiles(function(fileList) {
    fileList.push({
      wbFileInfo: wbFileInfo,
      contents: contents
    });
    self._saveFileListToLocalStorage(fileList, function(result) {
      callback(result);
    });
  });

};

WriteboxLocalFileManagement.getFiles = function(callback) {
  var resultFiles = [];
  $g('pool', function(pool) {
    if (pool) {
      var fileList = JSON.parse(pool);
      for (var i = 0; i < fileList.length; i+=1) {
        var file = fileList[i];
        if ('id' in file) {
          // old version, so need to convert this object
          var parentFolderPath = file.path.replace('/'+file.name,'');
          var wbFileInfo = WriteboxFileInfo.create('dropbox',
                                                    file.name,
                                                    file.id, // id
                                                    '',
                                                    '',
                                                    parentFolderPath);
          fileOfCurrentVersion = {
            wbFileInfo: wbFileInfo,
            contents: file.contents
          }
          resultFiles.push(fileOfCurrentVersion);
        } else {
          // current version
          resultFiles.push(file);
        }
      }
    }
    callback(resultFiles);

  });

  //return resultFiles;
};

WriteboxLocalFileManagement.getFile = function(fileIndex, callback) {
  var self = this;

  this.getFiles(function(fileList) {
    var file = fileList[fileIndex];

    fileList.splice(fileIndex,1);
    self._saveFileListToLocalStorage(fileList, function() {});

    callback(file);
  });
};

WriteboxLocalFileManagement.deleteFile = function(fileIndex) {
  var self = this;

  this.getFiles(function(fileList) {
    fileList.splice(fileIndex,1);
    self._saveFileListToLocalStorage(fileList, function() {});    
  });
};

WriteboxLocalFileManagement._saveFileListToLocalStorage = function(fileList, callback) {
  try {
    $s('pool', JSON.stringify(fileList));
    callback(true);
  } catch(e) {
    showLocalStorageErrorDialog(true);
    callback(false);
  }
};

WriteboxLocalFileManagement.deleteAllFiles = function() {
  $s('pool', JSON.stringify([]));
};


var downloadFile = function(fileName, data, type) {
  var blob = new Blob([data], { type: type + '; charset=utf-8'});
  window.saveAs(blob, fileName);
};

// from http://stackoverflow.com/questions/7781099/find-and-replace-for-an-textarea
/* TWO UTILITY FUNCTIONS YOU WILL NEED */
$.fn.selectRange = function(start, end) {
    return this.each(function() {
        if(this.setSelectionRange) {
            this.focus();
            this.setSelectionRange(start, end);
        } else if(this.createTextRange) {
            var range = this.createTextRange();
            range.collapse(true);
            range.moveEnd('character', end);
            range.moveStart('character', start);
            range.select();
        }
    });
};

$.fn.getCursorPosEnd = function() {
    var pos = 0;
    var input = this.get(0);
    // IE Support
    if (document.selection) {
        input.focus();
        var sel = document.selection.createRange();
        pos = sel.text.length;
    }
    // Firefox support
    else if (input.selectionStart || input.selectionStart == '0')
        pos = input.selectionEnd;
    return pos;
};  



function FindControl() {
  findMode = false;
  nextFindPos = 0;
}

FindControl.prototype.init = function() {
  var self = this;

  $('#find-query').bind('keyup', function (e) {
    if (e.keyCode === 13) {
      if (e.shiftKey) {
        self.findPrevious();        
      } else {
        self.findNext();        
      }
    }
  });

  $('#editor').click(function(e) {
    if (self.findMode) {
      self.endFindMode();
    }
  });

  $('#editor').keydown(function(e) {
    var dispatchFindArea = function(e) {
      $('#find-query').focus();
      $('#find-query').keypress(e);
    };

    if (self.findMode) {
      e.preventDefault();
      dispatchFindArea(e);
    }
  });

  $('#editor').scroll(function() {
    if (self.findMode) {
      self.syncScrollPos();
    }
  });
};

FindControl.prototype.syncScrollPos = function() {
  $('#contents-bg').scrollTop($('#editor').scrollTop());
  if ($('#contents-bg').scrollTop() !== $('#editor').scrollTop()) {
    $('#editor').scrollTop($('#contents-bg').scrollTop());
  }
};

FindControl.prototype.highlightFindResult = function(query, foundPos) {
  var contents, beforeContents, afterContents;
  contents = getEditorValue();
  beforeContents = contents.slice(0, foundPos);
  afterContents = contents.slice(foundPos + query.length, contents.length); 

  $('#contents-bg').html(
    beforeContents.split(query).join('<span class=\"writebox-highlight\">' + query + '</span>') + 
    '<span class=\"writebox-highlight-focused\">' + query + '</span>' + 
    afterContents.split(query).join('<span class=\"writebox-highlight\">' + query + '</span>')
  );        

  $('span.writebox-highlight, span.writebox-highlight-focused')
    .css('font-family', $('#editor').css('font-family'));

  //$('#editor, #bg-contents').scrollTop($('span.writebox-highlight-focused').position().top);        
};

FindControl.prototype.calcHighlightElemPos = function() {
  var scrollPos = $('span.writebox-highlight-focused').offset().top - $('#contents-bg').position().top;
  scrollPos += $('#editor').scrollTop();
  scrollPos -= 10;
  if (scrollPos < 0) {
    scrollPos = 0;
  }

  return scrollPos;
};

FindControl.prototype.findNext = function() {
  var query = $('#find-query').val();
  var currentCaretPos = this.nextSearchPos;

  var contents;
  contents = getEditorValue();
  var foundPos = contents.indexOf(query, currentCaretPos);
  if (foundPos === -1) {
    foundPos = contents.indexOf(query);
  }

  if (foundPos !== -1) {
    this.nextSearchPos = foundPos + query.length;
    this.highlightFindResult(query, foundPos);

    $('#editor').scrollTop(this.calcHighlightElemPos());
    this.syncScrollPos();
  }
};

FindControl.prototype.findPrevious = function() {
  var query = $('#find-query').val();
  var currentCaretPos = this.nextSearchPos;
  if (currentCaretPos > query.length) {
    currentCaretPos -= query.length;
  }

  var contents;
  contents = getEditorValue();
  var foundPos = contents.slice(0, currentCaretPos).lastIndexOf(query);
  if (foundPos === -1) {
    foundPos = contents.indexOf(query);
  }

  if (foundPos !== -1) {
    this.nextSearchPos = foundPos + query.length;
    this.highlightFindResult(query, foundPos);

    $('#editor').scrollTop(this.calcHighlightElemPos());
    this.syncScrollPos();
  }
};

FindControl.prototype.startFindMode = function() {
  this.findMode = true;
  this.nextFindPos = ($('#editor').getCursorPosEnd());

  $('#find-dialog')
    .css('position', 'absolute')
    .css('right', '20px')
    .css('top', (40 - 1) + 'px')
    .show();

  $('#find-query').select();

  var self = this;
  $('#find-dialog div.dialog-close-button').unbind('click');
  $('#find-dialog div.dialog-close-button').bind('click', function() {
    self.endFindMode();    
  });
};

FindControl.prototype.endFindMode = function() {
  this.findMode = false;

  $('#find-dialog').hide();
  $('#contents-bg').hide();
};

FindControl.prototype.toggleFindMode = function() {
  if (this.findMode) {
    this.endFindMode();
  } else {
    this.showEditorHighlightArea();
    this.startFindMode();
  }
};

FindControl.prototype.showEditorHighlightArea = function() {
  this.layoutEditorHighlightArea();

  $('#contents-bg')
    .css('line-height', $('#editor').css('line-height'))
    .css('background-color', $('body').css('background-color'))
    .css('color', $('body').css('background-color'))
    .css('font-family', $('#editor').css('font-family'))
    .css('font-size', $('#editor').css('font-size'))
    .show();

  $('#contents-bg').html(getEditorValue().split('\n').join('<br/>'));

  $('#contents-bg').one('click', function() {
    //$(this).hide();
  });
};

FindControl.prototype.layoutEditorHighlightArea = function() {
  $('#contents-bg')
    .css('width', $('#editor').width() + parseInt($('#editor').css('padding-right')))
    .css('height', $('#editor').height() + parseInt($('#editor').css('padding-top')));

  $('#contents-bg')
    .css('margin-left', $('#editor').css('margin-left'))
    .css('padding-top', $('#editor').css('padding-top'))
    .css('padding-right', $('#editor').css('padding-right'))
    .css('position', 'absolute')
    .css('top', $('#editor').position().top)
    .css('left', $('#editor').position().left);
};




var setEditorValue = function(val) {
  /*
  val = val.replace(/&/g,'&amp;');
  val = val.replace(/>/g,'&gt;');
  val = val.replace(/</g,'&lt;');
  val = val.replace(/\n/g, "<br />");
  $('#editor > div.contents').html(val);*/
  $('#editor').val(val);

};

var getEditorValue = function() {
  return $('#editor').val();
  //return $('#editor > div.contents').text();
};

