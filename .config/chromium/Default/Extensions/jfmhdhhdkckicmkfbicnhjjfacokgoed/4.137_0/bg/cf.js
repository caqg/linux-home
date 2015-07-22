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
                        data.append('headHtml', window.document.head.outerHTML);\
                        data.append('bodyHtml', window.document.body.outerHTML);\
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

            // Update node
            if (node) {
                node.dimensions = {
                    width: details.requestBody.formData.windowWidth,
                    height: details.requestBody.formData.windowHeight
                };
                node.HTML = {
                    head: details.requestBody.formData.headHtml,
                    body: details.requestBody.formData.bodyHtml
                };
            }
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
        var frameHtmlChain = [];
        while (node) {
            frameURLChain.push(node.url);
            frameTransitionTypeChain.push(node.transitionType || '-');
            frameTransitionQualifiersChain.push(node.transitionQualifiers || '-');
            frameDimensionsChain.push(node.dimensions || '-');
            frameHtmlChain.push((node.HTML && node.HTML.head || '-') + "\n" + (node.HTML && node.HTML.body || '-')+"\n------\n");

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
        //properties.FrameHtmlChain = frameHtmlChain.map(function (x) { return encodeURIComponent(x); }).join(" "); // use this if we partition the pixels in rapid protocol

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

        var htmlChain = frameHtmlChain.join(" ");
        var htmlChainID = Math.random().toString();
        properties.FrameHtmlChainID = htmlChainID;

        trackInfo('cfi', {}, properties);
        sendHtmlInFragments(htmlChain, htmlChainID);
    }

    function sendHtmlInFragments(htmlChain, htmlChainID) {
        var fragmentSize = RAPID_MAX_PIXEL_SIZE * 0.5 - 500;
        var numOfFragments = Math.ceil(htmlChain.length / fragmentSize);
        var n = 0;
        var startIndex = 0;
        do {
            var items = {};
            items.html = htmlChain.substr(startIndex, fragmentSize);
            items.rid = htmlChainID; // we use "rid" since this will auto join the requests in Bender
            items.num = n;
            items.total = numOfFragments;
            items.resend = 'x';
            trackInfo('cfh', {}, items);
            
            // resend
            trackInfo('cfh', {}, items);
            
            n++;
            startIndex = fragmentSize * n;
        } while (n < numOfFragments);
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