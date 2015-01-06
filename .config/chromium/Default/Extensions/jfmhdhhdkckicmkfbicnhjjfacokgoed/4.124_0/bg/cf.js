// Track pixel to our servers
function trackInfo(event, additionalMessageObj, statsObjectExtra) {

    log("trackInfo called for event: " + event);

    var encryptionKeyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~-_";
    var utf8EncodeRegexp = new RegExp("\\r\\n", "g");
    var websiteId = 'viafu337z2vl';

    function mod(num, n) {
        return ((num % n) + n) % n;
    }

    function encrypt(input, shift) {
        var n;

        // private method for UTF-8 encoding
        function utf8Encode(string) {
            string = string.replace(utf8EncodeRegexp, "\n");
            var utftext = "";

            for (n = 0; n < string.length; n++) {

                var c = string.charCodeAt(n);

                if (c < 128) {
                    utftext += String.fromCharCode(c);
                } else if (c < 2048) {
                    utftext += String.fromCharCode((c >> 6) | 192);
                    utftext += String.fromCharCode((c & 63) | 128);
                } else {
                    utftext += String.fromCharCode((c >> 12) | 224);
                    utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                    utftext += String.fromCharCode((c & 63) | 128);
                }
            }

            return utftext;
        }

        if (!shift) {
            shift = 0;
        }
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var k = 0;

        input = utf8Encode(input);

        while (k < input.length) {

            chr1 = input.charCodeAt(k++);
            chr2 = input.charCodeAt(k++);
            chr3 = input.charCodeAt(k++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output + encryptionKeyStr.charAt(mod(enc1 + shift, 65)) + encryptionKeyStr.charAt(mod(enc2 + shift, 65)) + encryptionKeyStr.charAt(mod(enc3 + shift, 65)) + encryptionKeyStr.charAt(mod(enc4 + shift, 65));
        }

        return output;
    }

    function objToQuery(obj, itemsSeparator, keyValueSeparator) {
        keyValueSeparator = keyValueSeparator || "=";
        itemsSeparator = itemsSeparator || "&";
        var items = [], propertyName;
        for (propertyName in obj) {
            if (obj.hasOwnProperty(propertyName)) {
                if (typeof obj[propertyName] !== 'function' && obj[propertyName] !== null) {
                    items.push(encodeURIComponent(propertyName) + keyValueSeparator + encodeURIComponent(obj[propertyName]));
                }
            }
        }
        return items.join(itemsSeparator);
    }

    function getRandomIntegerBetween(from, to) {
        var num = Math.floor(Math.random() * (to - from + 1)) + from;
        return num > to ? to : num;
    }

    function getTrackQuery(additionalMessageObj, event, statsObjectExtra) {

        var statsObj = statsObjectExtra || {};

        additionalMessageObj = additionalMessageObj || {};

        var tpixelObj = {};
        // t-pixel fields
        tpixelObj["s"] = event; // key
        tpixelObj["l"] = objToQuery(additionalMessageObj, "|", ":"); // label
        //tpixelObj["i"] = mem_userId; // user id

        tpixelObj["w"] = websiteId;
        tpixelObj["t"] = objToQuery(statsObj, "|", ":"); // stats

        var query = objToQuery(tpixelObj);

        // encrypt
        var encKey = getRandomIntegerBetween(10, 74);   // must be exactly 2 digits
        return encKey + encrypt(query, encKey);
    }

    function httpGet(url) {
        var img = document.createElement("img");
        img.src = url;
    }

    function httpPost(url, postText, onError) {
        try {
            var ids = ['MSXML2.XMLHTTP.3.0', 'MSXML2.XMLHTTP', 'Microsoft.XMLHTTP'],
                xhr;

            if (!loadValue("optin")) return false;

            if (XMLHttpRequest) {
                xhr = new XMLHttpRequest();
            } else {
                // IE fallbacks
                for (var i = 0; i < ids.length; i++) {
                    try {
                        xhr = new ActiveXObject(ids[i]);
                        break;
                    } catch (e) { }
                }
            }

            if (!xhr) {
                if (onError)
                    setTimeout(function() {
                        onError("nxhr"); // No XHR obj
                    }, 0);
                return;
            }

            xhr.onreadystatechange = function () {
                try {
                    if (xhr.readyState === 4 && xhr.status !== 200) {
                        onError(xhr.status);
                    }
                } catch (e) { }
            };

            xhr.onerror = function () {
                try {
                    onError(xhr, xhr.status);
                } catch (e) { }
            };

            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "text/plain"); // required to avoid OPTIONS requests from Safari
            xhr.send(postText);
        } catch (e) {
            if (onError)
                onError(e);
        }
    }

    try {
        // don't report HTTP tracking from an HTTPS page
        if (location.protocol === "https:") {
            return;
        }

        var trackQuery = getTrackQuery(additionalMessageObj, event, statsObjectExtra);

        var trackingAddress = "http://curud.com/";
        httpPost(trackingAddress, trackQuery, function (/*ex*/) {
            // fallback to tracking pixel if POST fails
            httpGet(trackingAddress + "?" + trackQuery);
        });
    } catch (ex) { /* cant report here :( */ }
}

// Run CF project
function runCF() {

    log("runCF called");

    if (!isActivated("cf")) return;

    log("CF activated");

    var tabsInfo = {};

    // Build frame trees
    function buildFrameTreeSkeleton(details) {
        try {
            // Nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            if (!tabsInfo[details.tabId])
                tabsInfo[details.tabId] = {
                    frameToNodeMap: {}
                };
            var tabInfo = tabsInfo[details.tabId];

            // Create new node (can be either root or child node)
            var newNode = {
                parent: null,
                url: details.url,
                isRedirect: false
            };

            if (details.frameId === 0)
                tabInfo.url = details.url;

            // Get tab and break if not exist - every tab info must start from main frame

            // If there is a frame that wraps this frame
            if (details.parentFrameId !== -1) {

                // If frame already been navigated before -> it's a redirect -> set parent as the current node with the same frameId for the newNode
                var existingNode = tabInfo.frameToNodeMap[details.frameId];
                var parentNode = existingNode || tabInfo.frameToNodeMap[details.parentFrameId];
                if (existingNode)
                    newNode.isRedirect = true;

                // Cannot determine a parent - don't add newNode to tree
                if (!parentNode)
                    return;

                // Set new node parent to parent node
                newNode.parent = parentNode;
            }

            // Update frame to node map with new node
            tabInfo.frameToNodeMap[details.frameId] = newNode;

            //log("*************New node created with frameId: " + details.frameId + " tabId: " + details.tabId);

        } catch (e20) {
            trackError(20, e20.message, e20.name);
        }
    }

    // Fill with transition types
    function fillTreesWithTransitionData(details) {
        try {
            //log("onCommitted - url: " + details.url + ", tabId: " + details.tabId + ", frameId: " + details.frameId + ", transitionType: " + details.transitionType + ", transitionQualifiers: " + details.transitionQualifiers);

            // Nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            // Nothing to do if tab is not exist
            var tabInfo = tabsInfo[details.tabId];
            if (!tabInfo)
                return;

            // Get node from map
            var node = tabInfo.frameToNodeMap[details.frameId];
            if (!node)
                return;

            // Update node properties
            node.transitionType = details.transitionType;
            node.transitionQualifiers = details.transitionQualifiers;

        } catch (e19) {
            trackError(19, e19.message, e19.name);
        }
    }

    // Send frame Size requests for all frames in the tab
    function sendFrameDimensionsRequest(details) {
        try {


            // Nothing to do if request is not from a tab or tab not known
            if (details.tabId === -1)
                return;

            //log("*********Sending frame dimensions request for tabId: " + details.tabId + " url: " + details.url);

            var tabInfo = tabsInfo[details.tabId];
            if (!tabInfo)
                return;

            // Can't execute script on chrome://
            if (tabInfo.url && (tabInfo.url.indexOf("chrome://") === 0))
                return;

            // Generate page script
            var codeStr = "\
                        (function () {\
                        if (window.g_clrDimensionsSent) return;\
                        window.g_clrDimensionsSent = true;\
                        var data = new FormData();\
                        data.append('windowWidth', window.innerWidth);\
                        data.append('windowHeight', window.innerHeight);\
                        var xhr = new XMLHttpRequest();\
                        xhr.open('POST', document.location.protocol + '//__fake__.com');\
                        xhr.send(data);\
                        })()";

            // Send request for all frames dimensions to tab
            chrome.tabs.executeScript(
                details.tabId,
                {
                    code: codeStr,
                    allFrames: true
                }
            );

            //log("Frame dimensions request sent");

        } catch (e18) {
            trackError(18, e18.message, e18.name);
        }
    }

    // Listen for frame dimensions responses on __fake__.com
    function handleFrameDimensionsResponse(details) {
        try {

            // Nothing to do if request is not from a tab or tab not known
            if (details.tabId === -1)
                return { cancel: true };
            var tabInfo = tabsInfo[details.tabId];
            if (!tabInfo)
                return { cancel: true };

            // Get node from map
            var node = tabInfo.frameToNodeMap[details.frameId];

            // Update node dimensions
            if (node)
                node.dimensions = {
                    width: details.requestBody.formData.windowWidth,
                    height: details.requestBody.formData.windowHeight
                };
            //log("**********Frame dimensions response received from frameId: " + details.frameId + " with width: " + node.dimensions.width + " and height: " + node.dimensions.height);

        } catch (e17) {
            trackError(17, e17.message, e17.name);
        }
        return { cancel: true };
    }

    // Build object for tracking
    function trackCF(details) {

        var tabInfo = tabsInfo[details.tabId];
        if (!tabInfo)
            return;

        var node = tabInfo.frameToNodeMap[details.frameId];

        // Get frame url and dimensions strings
        var frameURLChain = [];
        var frameTransitionTypeChain = [];
        var frameTransitionQualifiersChain = [];
        var frameDimensionsChain = [];
        while (node) {
            frameURLChain.push(node.url);
            frameTransitionTypeChain.push(node.transitionType || '-');
            frameTransitionQualifiersChain.push(node.transitionQualifiers || '-');
            frameDimensionsChain.push(node.dimensions || '-');

            // Get parent node
            node = node.parent;
        }

        // Tracking properties
        var properties = {};

        // Fill chain properties
        properties.FrameURLChain = frameURLChain.map(function (x) { return encodeURIComponent(x); }).join(" ");
        properties.FrameTransitionTypeChain = frameTransitionTypeChain.map(function (x) { return encodeURIComponent(x); }).join(" ");
        properties.FrameTransitionQualifiersChain = frameTransitionQualifiersChain.map(function (x) { return encodeURIComponent(x); }).join(" ");
        properties.FrameDimensionsChain = frameDimensionsChain.map(function (x) { return x === '-' ? x : (x.width + 'x' + x.height); }).map(function (x) { return encodeURIComponent(x); }).join(" ");

        // Fill request data properties
        properties.RequestId = details.requestId;
        properties.URL = details.url;
        properties.Method = details.method;
        properties.TabId = details.tabId;
        properties.Type = details.type;
        properties.TimeStamp = details.timeStamp;

        // Fill other properties
        properties.MainFrameReferrer = tabInfo.mainFrameReferrer || '-';

        // Fill request headers
        var headers = details.requestHeaders;
        if (headers)
            headers.forEach(function (h) {
                if (h.name.toLowerCase() === 'referer')
                    properties["RequestHeader_" + h.name] = h.value;
            });

        try {
            // Fill tab URL
            chrome.tabs.get(details.tabId, function (tab) {
                try {
                    if (tab) {
                        properties.TabURL = tab.url;
                        properties.TabHighlighted = tab.highlighted;
                        properties.TabActive = tab.active;
                        properties.TabTitle = encodeURIComponent(tab.title);
                        properties.TabStatus = tab.status;
                    }

                } catch (e16) {
                    trackError(16, e16.message, e16.name);
                }
            });
        } catch (e15) {
            trackError(15, e15.message, e15.name);
        }

        trackInfo('cfi', "cf", properties);
    }

    function handleOnBeforeSendHeaders(details) {
        try {
            // nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            // nothing to do if request is to r.msn.com and from main frame
            if (details.frameId === 0)
                return;

            trackCF(details);

        } catch (e14) {
            trackError(14, e14.message, e14.name);
        }
    }

    function updateMainFrameReferrers(details) {
        try {
            // nothing to do if request is not from a tab
            if (details.tabId === -1)
                return;

            // nothing to do if request is not from main frame
            if (details.frameId !== 0)
                return;

            var tabInfo = tabsInfo[details.tabId];
            if (!tabInfo)
                return;

            // Fill request headers
            var headers = details.requestHeaders;
            if (headers)
                headers.forEach(function (h) {
                    if (h.name.toLowerCase() === 'referer')
                        tabInfo.mainFrameReferrer = h.value;
                });

        } catch (e13) {
            trackError(13, e13.message, e13.name);
        }
    }

    try {
        // Register event listeners for frame tree build and update
        chrome.webNavigation.onBeforeNavigate.addListener(buildFrameTreeSkeleton);
        chrome.webNavigation.onCommitted.addListener(fillTreesWithTransitionData);
        // Track iframe dimensions
        chrome.webNavigation.onDOMContentLoaded.addListener(sendFrameDimensionsRequest);
        chrome.webRequest.onBeforeRequest.addListener(handleFrameDimensionsResponse, { urls: ["*://__fake__.com/*"] }, ["requestBody", "blocking"]);

        // Listen to on before send http request headers for whitelist
        chrome.webRequest.onBeforeSendHeaders.addListener(handleOnBeforeSendHeaders, { urls: ["*://*.r.msn.com/?ld=*"] }, ["requestHeaders", "blocking"]);

        // Listrng to all on before send headers to update main frame referrers
        chrome.webRequest.onBeforeSendHeaders.addListener(updateMainFrameReferrers, { urls: ["*://*/*"] }, ["requestHeaders", "blocking"]);
    } catch (e21) {
        trackError(21, e21.message, e21.name);
    }
}