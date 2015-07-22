/* Symantec Watermark: CB70-4860-5397-06-15-6 */

// frameid
var _fid = 0, // the frame id
	_NavEventSent = false;

function getFrameId() {
	if (_fid === 0) {
		_fid = Math.floor((Math.random() * 2147483646) + 1);
	}
	return _fid;
}
function SendMessageToNativeHost(context) {
    chrome.runtime.sendMessage(context);
}

function init(){
	var fidAttr = getFrameId();
    chrome.extension.sendMessage({ contentscript: "GetTabInfo" }, function (response) {
		// Send the navigational messages to the chrome plugin
		SendMessageToNativeHost({ method: 'ChromeSetId', windowId: response.windowId, tabId: response.tabId, incognitoMode: response.incognitoMode, windowType: response.windowType, topLevel: top === self });
		SendMessageToNativeHost({method: "NavEvent",windowId: response.windowId,tabId: response.tabId,topLevelNav: window === window.top,beginNav : true,documentURL: document.URL.toString(),fid: fidAttr});
        SendMessageToNativeHost({ method: 'DOMContentLoaded', windowId: response.windowId, tabId: response.tabId, topLevel: window === window.top, fid: fidAttr, documentURL: document.URL.toString() });
		SendMessageToNativeHost({method: "NavEvent",windowId: response.windowId,tabId: response.tabId,topLevelNav: window === window.top,beginNav : false,documentURL: document.URL.toString(),fid: fidAttr});
		_NavEventSent = true;
				
        // for PII only, launch url 
        var element = document.getElementById("ReportPIIIssue");
        if (element) {
            var sPIIReportIssueURL = element.getAttribute('url');
            element.onclick = function () {
                window.open(sPIIReportIssueURL);
            };
        }
    });
}   

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
	if (!request || !request.type || !request.id) {
		// invalid arguments
		return;
	}
	var eventName = request.type;
	var element = document.getElementById(request.id);
	if (!element) {
		// element not found
		return;
	}
	if ("setElementInnerHtml" === eventName) {
		element.innerHTML = request.innerHtml;
	} else if ("setElementText" === eventName) {
		element.textContent  = request.text;
	} else if ("setAttributeByName" === eventName){
		if (request.attributeName && request.attributeValue) {
			element.setAttribute(request.attributeName,request.attributeValue);
		}
	}
});
   
document.addEventListener("DOMContentLoaded", function () {
    if (!_NavEventSent) {
		init();
	}
}, false);

// check if we have sent the navigational events already after 1 sec, send it if not already sent
window.setTimeout( function() {
	if (!_NavEventSent) {
		init();
	}
}, 1000);