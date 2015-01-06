var api2 = {
  sessionKey: null,
  getParam: function(query) {
    console.log(api2.sessionKey);
    if (api2.sessionKey !== null && api2.sessionKey !== undefined && api2.sessionKey !== '') {
      query['sessionkey'] = api2.sessionKey;
      console.log('session key=' + api2.sessionKey);
      return query;
    } else {
      return query;
    }
  }
};

var HOST = '';
if (window.location.href.indexOf('chrome') === 0) {
  HOST = 'https://write-box.appspot.com';
  //HOST = 'http://10.write-box.appspot.com'
} else {
  HOST = '';
}

api2.host = HOST


api2.dropbox = {};
api2.googledrive = {};
api2.box = {};
api2.skydrive = {};

api2.dropbox.getFiles = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/dropbox/files",
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      result = [];
      for (var i = 0; i < json.result.length; i++) {
      	var elem = json.result[i];
        var fileName = elem.path.split('/').pop();
      	result.push({
          storage: 'dropbox',
      	  fileID: elem.path,
          fileName: fileName,
      	  type: (elem.is_dir) ? 'folder' : 'file',
      	  mimeType: elem.mime_type,
      	  modifiedDate: null
      	});
      }
      p.success(result);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/files <<< ERROR: " + XMLHttpRequest.status);
      p.error(XMLHttpRequest.status);
    }
  });
};

api2.googledrive.getFiles = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/googledrive/files",
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      result = [];
      for (var i = 0; i < json.length; i++) {
      	var elem = json[i];
        var type = (elem.mimeType === 'application/vnd.google-apps.folder') ? 'folder' : 'file';
     	  result.push({
          storage: 'googledrive',
          fileID: elem.id,
    	    fileName: elem.title,
    	    type: type,
    	    mimeType: elem.mimeType,
    	    modifiedDate: null,
          obj: elem
    	  });      		
      }
      p.success(result);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/googledrive/files <<< ERROR: " + XMLHttpRequest.status);
      p.error(XMLHttpRequest.status);
    }
  });
};

api2.box.getFiles = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/box/files",
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      console.log(json);
      result = [];
      for (var i = 0; i < json.result.entries.length; i++) {
        var elem = json.result.entries[i];
        //var fileName = elem.path.split('/').pop();
        result.push({
          storage: 'box',
          fileID: elem.id,
          fileName: elem.name,
          type: (elem.type === 'folder') ? 'folder' : 'file',
          mimeType: 'text',
          modifiedDate: null
        });
        console.log(elem.name);
      }
      p.success(result);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/box/files <<< ERROR: " + XMLHttpRequest.status);
      p.error(XMLHttpRequest.status);
    }
  });
};

api2.skydrive.getFiles = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/skydrive/files",
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      result = [];
      for (var i = 0; i < json.result.length; i++) {
        var elem = json.result[i];
        if (elem.type === 'folder' || elem.type === 'file') {
          result.push({
            storage: 'skydrive',
            fileID: elem.id,
            fileName: elem.name,
            type: (elem.type === 'folder') ? 'folder' : 'file',
            mimeType: 'text',
            modifiedDate: null
          });          
        }
        console.log(elem);
      }
      p.success(result);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/box/files <<< ERROR: " + XMLHttpRequest.status);
      p.error(XMLHttpRequest.status);
    }
  });
};

api2.dropbox.getTextData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/dropbox/file/text',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      p.success(json.result.text, new Date(Date.parse(json.result.modified)));
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/text <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.googledrive.getTextData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/googledrive/file/text',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      p.success(json.result.text, new Date(Date.parse(json.result.modified)), json.result.mimetype);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/text <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.box.getTextData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/box/file/text',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      console.log(json);
      p.success(json.result.text, null, json.result.mimetype);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/text <<< ERROR: " + textStatus);
      p.error();
    }
  });

};

api2.dropbox.getMetaData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/dropbox/file/meta',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      p.success({
        'modified': json.result.modified
      });
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/meta <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.googledrive.getMetaData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/googledrive/file/meta',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      p.success({
        'modified': json.result.modifiedDate
      });
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/googledrive/file/meta <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.box.getMetaData = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/box/file/meta',
    data: api2.getParam({q: p.query}),
    dataType: "json",
    success: function(json) {
      p.success({
        'modified': json.result.modified_at
      });
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/meta <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.dropbox.saveTextData = function(p) {
  $.ajax({
    type: "POST",
    url: HOST + "/api/2/dropbox/file/text",
    data: api2.getParam({
      fileid:p.fileID,
      contents:p.contents
    }),
    dataType: "json",
    success: function(json) {
      p.success(json.fileid, json.modified);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/data <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.googledrive.saveTextData = function(p) {
  $.ajax({
    type: "POST",
    url: HOST + "/api/2/googledrive/file/text",
    data: api2.getParam({
      fileid:p.fileID,
      filename: p.fileName,
      parentfolderid: p.parentFolderID,
      contents:p.contents,
      mimetype:p.mimeType
    }),
    dataType: "json",
    success: function(json) {
      p.success(json.fileid, json.modified);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/data <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.box.saveTextData = function(p) {
  $.ajax({
    type: "POST",
    url: HOST + "/api/2/box/file/text",
    data: api2.getParam({
      fileid: p.fileID,
      filename: p.fileName,
      parentfolderid: p.parentFolderID,
      contents:p.contents
    }),
    dataType: "json",
    success: function(json) {
      p.success(json.result.entries[0].id, json.result.entries[0].modified_at);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/data <<< ERROR: " + textStatus);
      p.error();
    }
  });
};


api2.getAccount = function(p) {
  console.log(api2.getParam({}));
  $.ajax({
    type: "GET",
    url: HOST + '/api/2/account',
    data: api2.getParam({}),
    dataType: "json",
    success: function(json) {
      console.log(json);
      p.success(json);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/file/text <<< ERROR: " + textStatus);
      p.error();
    }
  });
};


api2.dropbox.link = function() {
  location.href = "/api/2/dropbox/link";
  //chrome.app.window.create(HOST + "/api/2/dropbox/link");
  //window.open(HOST + "/api/2/dropbox/link", "_blank");
  //chrome.identity.launchWebAuthFlow({url: HOST + "/api/2/dropbox/link", interactive: true}, function(responseUrl) {
  //  console.log(responseUrl);
  //});
};

api2.dropbox.getLinkUrl = function() {
  linkUrl = HOST + "/api/2/dropbox/link?returnkey=yes";
  if (api2.sessionKey !== null && api2.sessionKey !== undefined && api2.sessionKey !== '') {
    linkUrl += ('&sessionkey=' + api2.sessionKey);
  }

  return linkUrl
}

api2.dropbox.unlink = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/dropbox/unlink",
    data: api2.getParam({}),
    success: function() {
      p.success();
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/dropbox/unlink <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.googledrive.link = function() {
  location.href = "/api/2/googledrive/link";
}

api2.googledrive.getLinkUrl = function() {
  linkUrl = HOST + "/api/2/googledrive/link?returnkey=yes";
  if (api2.sessionKey !== null && api2.sessionKey !== undefined && api2.sessionKey !== '') {
    linkUrl += ('&sessionkey=' + api2.sessionKey);
  }

  return linkUrl
}

api2.googledrive.unlink = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/googledrive/unlink",
    data: api2.getParam({}),
    success: function() {
      p.success();
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/googledrive/unlink <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.box.link = function() {
  location.href = "/api/2/box/link";
};

api2.box.getLinkUrl = function() {
  linkUrl = HOST + "/api/2/box/link?returnkey=yes";
  if (api2.sessionKey !== null && api2.sessionKey !== undefined && api2.sessionKey !== '') {
    linkUrl += ('&sessionkey=' + api2.sessionKey);
  }

  return linkUrl
};

api2.box.unlink = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/box/unlink",
    data: api2.getParam({}),
    success: function() {
      p.success();
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/box/unlink <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.skydrive.link = function() {
  location.href = "/api/2/skydrive/link";
}

api2.skydrive.getLinkUrl = function() {
  linkUrl = HOST + "/api/2/skydrive/link?returnkey=yes";
  if (api2.sessionKey !== null && api2.sessionKey !== undefined && api2.sessionKey !== '') {
    linkUrl += ('&sessionkey=' + api2.sessionKey);
  }

  return linkUrl
}

api2.skydrive.unlink = function(p) {
  $.ajax({
    type: "GET",
    url: HOST + "/api/2/skydrive/unlink",
    data: api2.getParam({}),
    success: function() {
      p.success();
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log("GET:/api/2/skydrive/unlink <<< ERROR: " + textStatus);
      p.error();
    }
  });
};

api2.dropbox.linkWithNewTab = function(callback) {
  var bg = chrome.extension.getBackgroundPage();
  bg.openLoginPage({
    loginUrl: HOST + "/api/2/dropbox/link",
    callbackUrl: HOST,
    success: function() {
      callback();
    }
  });
};

api2.googledrive.linkWithNewTab = function(callback) {
  var bg = chrome.extension.getBackgroundPage();
  bg.openLoginPage({
    loginUrl: HOST + "/api/2/googledrive/link",
    callbackUrl: HOST,
    success: function() {
      callback();
    }
  });
};

api2.box.linkWithNewTab = function(callback) {
  var bg = chrome.extension.getBackgroundPage();
  bg.openLoginPage({
    loginUrl: HOST + "/api/2/box/link",
    callbackUrl: HOST,
    success: function() {
      callback();
    }
  });
};

api2.skydrive.linkWithNewTab = function(callback) {
  var bg = chrome.extension.getBackgroundPage();
  bg.openLoginPage({
    loginUrl: HOST + "/api/2/skydrive/link",
    callbackUrl: HOST,
    success: function() {
      callback();
    }
  });
};

api2.setSessionKey = function(sessionKey) {
  api2.sessionKey = sessionKey;
}
