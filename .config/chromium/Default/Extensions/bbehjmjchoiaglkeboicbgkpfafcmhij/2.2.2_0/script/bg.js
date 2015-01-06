var gCallbackUrl = "";
var gCallback = null;
var gLoginPageTabID = "";

var openLoginPage = function(p) {
  gCallbackUrl = p.callbackUrl;
  gCallback = p.success;

  chrome.tabs.create({url:p.loginUrl,selected:true}, function(tab) {
    console.log("Tab created:" + tab.id);
    gLoginPageTabID = tab.id;
  });

  chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
    console.log("Updated: " + tabId + " " + changeInfo.url + " " + tab.url);
    console.log(gCallbackUrl);
    if (tabId === gLoginPageTabID && tab.url === gCallbackUrl + '/') {
      console.log('callback');
      if (gCallback) gCallback();
      chrome.tabs.remove(tabId);
      chrome.tabs.onUpdated.removeListener();
    }
  });
};

chrome.app.runtime.onLaunched.addListener(function() {
  var url = '/app.html';
      options = {
        bounds: {
          width: 640,
          height: 500
        },
        frame: 'chrome',
        id: 'writebox',
        singleton: true,
        /*state: 'fullscreen'*/ };

  chrome.app.window.create(url, options, function(win) {
    //win.fullscreen();
  });
});
