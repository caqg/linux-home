// Global variables
var state = {};
var localStorageSnapshot = {};      // All non-object local storage values - available to content scripts

var activations = {                 // Activations configuration
    "analytics": {
        "func": 0.01,
        "lifetime": 1.0,
        "infraBg": 0.001,
        "error": 0.1
    },
    "hellfire": 0.05,
    "hellfireTestGroup": 0.05,
    "hellfireChristmas": 1,
    "cf": 1
};
var MILLISECS_IN_DAY = 24*60*60*1000;
var MILLISECS_IN_WEEK = 7*MILLISECS_IN_DAY;

var RAPID_WORKER_FILE_PATH = 'bg/rapidworker-1.2.js';
var RAPID_MAX_PAYLOAD_CHUNK_SIZE = 300;
var RAPID_MAX_PIXEL_SIZE = 8192 * 0.85; // TODO: change to 24*1024
var SPACE_ID_MDMR = 1197771782;
var SPACE_ID_HELLFIRE = 1197771783;
var HF_MAX_HEADER_LENGTH = 500;

var trackToRapid = true;
var trackToRackspace = false;
var trackToAws = true;
// the regexp is for a % or a single backslash.
// a '\\' is JS strings way of saying "one backslash".
// a '\\\\' is JS strings way of saying "two backslashes", which is the regexp way of saying "a single backslash".
var escapeRapidBugRegex = new RegExp('[%\\\\]', 'g');
var rapidInstances = {};


function isUndefined(obj) {
    return (typeof obj === 'undefined');
}

// Track a Bender-format (not HF-format) beacon to Rackspace and/or Rapid
function trackInfo(event, additionalMessageObj, statsObjectExtra) {

    log("sending MD-format beacon", event, additionalMessageObj, statsObjectExtra);

    var encryptionKeyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~-_";
    var utf8EncodeRegexp = new RegExp("\\r\\n", "g");
    var websiteId = 'viafu337z2vl'; // census.01

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

    function objToQuery(obj, itemsSeparator, keyValueSeparator, dontEncode) {
        keyValueSeparator = keyValueSeparator || "=";
        itemsSeparator = itemsSeparator || "&";
        var items = [], propertyName;
        for (propertyName in obj) {
            if (obj.hasOwnProperty(propertyName)) {
                if (typeof obj[propertyName] !== 'function' && obj[propertyName] !== null) {
                    items.push((dontEncode ? propertyName : encodeURIComponent(propertyName)) + keyValueSeparator + (dontEncode ? obj[propertyName] : encodeURIComponent(obj[propertyName])));
                }
            }
        }
        return items.join(itemsSeparator);
    }

    function getRandomIntegerBetween(from, to) {
        var num = Math.floor(Math.random() * (to - from + 1)) + from;
        return num > to ? to : num;
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
        var statsObj = statsObjectExtra || {};

        additionalMessageObj = additionalMessageObj || {};

        var tpixelObj = {
            "s": event, // dp
            "l": objToQuery(additionalMessageObj, "|", ":"), // label
            "w": websiteId, // wid
            "t": objToQuery(statsObj, "|", ":") // stats
        };

        if (trackToRapid) {
            var payloadStr = objToQuery(tpixelObj, "&", "=", true);
            sendRapid(payloadStr, SPACE_ID_MDMR, websiteId, event);
        }

        if (trackToRackspace) {
            var query = objToQuery(tpixelObj);

            // encrypt
            var encKey = getRandomIntegerBetween(10, 74); // must be exactly 2 digits
            var trackQuery = encKey + encrypt(query, encKey);

            var trackingAddress = "http://curud.com/";
            httpPost(trackingAddress, trackQuery, function (/*ex*/) {
                // fallback to tracking pixel if POST fails
                httpGet(trackingAddress + "?" + trackQuery);
            });
        }

    } catch (ex) {
        /* cant report here :( */
        log("Failed to track info: " + ex.message, ex);
    }
}


// Loads value from local storage by property name
function loadValue(name) {
    if (typeof state[name] == 'undefined') {

        var lsStr;
        if (lsStr = localStorage['s_' + name]) {
            state[name] = lsStr;
        } else if (lsStr = localStorage['n_' + name]) {
            state[name] = parseFloat(lsStr);
        } else if (lsStr = localStorage['o_' + name]) {
            state[name] = JSON.parse(lsStr);
        } else if (lsStr = localStorage['d_' + name]) {
            state[name] = new Date(Date.parse(lsStr));
        } else if (lsStr = localStorage['b_' + name]) {
            if (lsStr === 'false') lsStr = '';
            state[name] = Boolean(lsStr);
        }
    }
    return state[name];
}

// Returns type name by value
function getTypeName(obj, toLower) {
    var res = ({}).toString.call(obj).match(new RegExp("\\s([a-zA-Z]+)"))[1];
    if (toLower)
        res = res.toLowerCase();
    return res;
}

// Keeps the value in both state object and local storage
function persistValue(name, value) {
    var type = getTypeName(value, true);
    var codedName = name;
    if (type == 'object') {
        codedName = 'o_' + name;
        localStorage[codedName] = JSON.stringify(state[name] = value);
    } else {
        switch (type) {
            case 'string':
                codedName = 's_' + name;
                break;
            case 'number':
                codedName = 'n_' + name;
                break;
            case 'date':
                codedName = 'd_' + name;
                break;
            case 'boolean':
                codedName = 'b_' + name;
                break;
        }
        localStorageSnapshot[codedName] = localStorage[codedName] = state[name] = value;
    }
}

// Determine if an activity is activated based on some rules
function isActivated(activity) {

    // Debug activity flag
    if (loadValue("activate_" + activity)) return true;

    // Opt in activation
    if (!loadValue("optin")) return false;

    // Action type activation
    var activityActivationRate = activations[activity];
    if (!activityActivationRate) return false;
    return Math.random() < activityActivationRate;
}

// Merge 2 objects into 1
function mergeObjs(obj1, obj2) {
    var result = {};
    var k;
    obj1 = obj1 || {};
    obj2 = obj2 || {};
    for (k in obj1)
        if (obj1.hasOwnProperty(k))
            result[k] = obj1[k];
    for (k in obj2)
        if (obj2.hasOwnProperty(k))
            result[k] = obj2[k];
    return result;
}

function escapeRapidBugReplaceFunc(s) {
    return s[0] === '%' ? '%%' : '%B';
}

function escapeRapidBug(str) {
    if (str === null) return null;
    return str.replace(escapeRapidBugRegex, escapeRapidBugReplaceFunc);
}

function sendRapid(payloadStr, spaceId, param1, param2, cb) {
    try {
        // init Rapid instance (if not already initialized)
        rapidInstances[spaceId] = rapidInstances[spaceId] || YAHOO.i13n.RapidCore({
            spaceid: spaceId,
            webworker_file: RAPID_WORKER_FILE_PATH
        });

        // encode to avoid '\' in payload
        payloadStr = escapeRapidBug(payloadStr);

        var beacon = {},
            numOfFields = Math.ceil(payloadStr.length / RAPID_MAX_PAYLOAD_CHUNK_SIZE);

        if (!isUndefined(param1))
            beacon['yasp1'] = param1;
        if (!isUndefined(param2))
            beacon['yasp2'] = param2;

        for (var i = 0; i < numOfFields; i++) {
            var startIndex = i * RAPID_MAX_PAYLOAD_CHUNK_SIZE;
            beacon['yas' + i] = payloadStr.substring(startIndex, startIndex + RAPID_MAX_PAYLOAD_CHUNK_SIZE);
        }

        rapidInstances[spaceId]['beaconEvent']('yas', beacon, null, cb);

    } catch (e42) {
        // can't report here
        log("Failed to track rapid: " + e42.message, e42);
    }
}

// Add common properties for tracking pixeles
function getCommonTrackingProperties() {
    var commonProp = {};
    commonProp['exnm'] = extensionConsts.extensionName;
    try {
        commonProp['exvr'] = chrome.app.getDetails().version;
    } catch (e5) {
        trackError(5, e5.message, e5.name);
    }
    commonProp['indt'] = loadValue("installDate");
    commonProp['updt'] = loadValue("updateDate");
    commonProp['oi'] = loadValue("optin");
    commonProp['oihs'] = loadValue("optinHistory");
    return commonProp;
}

// Determine if an activity is activated based on some rules
function isAnalyticsActivated(activity) {

    // Debug activity flag
    if (loadValue("activate_analytics")) return true;

    // Opt in activation
    if (!loadValue("optin")) return false;

    // Action type activation
    var activityActivationRate = activations.analytics[activity];
    if (!activityActivationRate) return false;
    return Math.random() < activityActivationRate;
}

// Analytics event tracking
function trackEvent(actionName, actionType, properties) {
    try {
        if (!isAnalyticsActivated(actionType)) return;

        var commonProps = getCommonTrackingProperties();
        var rate = activations.analytics[actionType];
        var mergedProps = mergeObjs(properties, commonProps);
        mergedProps['acrt'] = rate;

        trackInfo(actionName, mergedProps);
    } catch (e4) {
        log(e4.message, e4);
    }
}

// Tracks a single error
function trackError(number, message, name, properties) {
    properties = properties || {};
    properties['ms'] = message;
    properties['nm'] = name;
    properties['no'] = number;
    trackEvent('er', "error", properties);
}

// Logs a message to console only if flag raised
function logVarArgs( /* args */ ) {
    if (!loadValue('debug'))
        return;
    try {
        var argsArray = [].slice.call(arguments);
        var isAnError = argsArray.some(function(arg) { return arg instanceof Error; });
        var logger = isAnError ? console.error : console.log;
        logger.apply(console, arguments);
    } catch (e5) {
        console.error("failed logging an error", e5);
    }
}

var log = logVarArgs.bind(null, "[background]: ");

// Open new tab with welcome page and opt-in message
function openInstallPage() {
    chrome.tabs.create({url: chrome.extension.getURL('install/install.html')});
}

// Fill extension storage snapshot object for content scripts
function initExtensionStorageSnapshot() {
    var value;
    Object.keys(localStorage).forEach(function (k) {
        value = localStorage[k];
        if (value.indexOf('o_') === 0) return;
        localStorageSnapshot[k] = value;
    });
}

// Register common bg event listeners
function registerCmnEventsListeners() {

    // Extension installation and update events
    try {
        chrome.runtime.onInstalled.addListener(function (details) {
            try {
                switch (details.reason) {
                    case 'update':
                        persistValue("updateDate", new Date());
                        trackEvent('up', "infraBg", { 'pvvr': details.previousVersion });
                        break;
                    case 'install':
                        persistValue("installDate", new Date());
                        openInstallPage();
                        break;
                }
            } catch (e4) {
                trackError(4, e4.message, e4.name);
            }
        });
    } catch (e3) {
        trackError(3, e3.message, e3.name);
    }
    
    // Messages from other parts of the extension
    try {
        chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
            try {
                if (!request) return;

                //log("onMessage: request: " + JSON.stringify(request) + " sender: " + JSON.stringify(sender));

                switch (request.action) {
                    case 'GET_BG_DATA':
                        if (sender.tab)
                            sendResponse ({
                                action: "BG_DATA",
                                extensionConsts: extensionConsts,
                                activations: activations,
                                localStorageSnapshot: localStorageSnapshot
                            });
                        else {
                            log('no loaded content config to supply to the content scripts');
                        }
                        break;
                    case 'TRACK_EVENT':
                        trackEvent(request.actionName, request.actionType, request.properties);
                        break;
                    case 'PERSIST_VALUE':
                        persistValue(request.name, request.value);
                        break;
                    case 'LOG_CONTENT_EVENT':
                        logVarArgs(sender.tab ? ("[tab #" + sender.tab.id + "]: ") : ("[tab #?]: "), request.message, request.exceptionMessage);
                        break;
                    case 'ERROR':
                        if (request.url)
                            trackError(request.errorNumber, request.errorMessage, request.errorName,
                                { 'URL': request.url, 'Domain': request.domain, 'Referrer': request.referrer });
                        else
                            trackError(request.errorNumber, request.errorMessage, request.errorName);
                        break;
                }
            } catch (e2) {
                trackError(2, e2.message, e2.name);
            }
        });
    } catch (e1) {
        trackError(1, e1.message, e1.name);
    } 
}

// Send a Daily/Weekly KeepAlive pixel in order to measure DAU and WAU
function startKeepAlive(interval, localStorageKey, pixelName) {

    try {

        function sendKeepAlive() {
            try {
                var nowDate = new Date();
                trackEvent(pixelName, 'lifetime');
                persistValue(localStorageKey, nowDate);
            } catch (e43) {
                trackError(43, e43.message, e43.name);
            }
        }

        var lastKeepAliveDate = loadValue(localStorageKey);
        if (!lastKeepAliveDate) {
            lastKeepAliveDate = new Date(0);
            persistValue(localStorageKey, lastKeepAliveDate);
        }

        var nextKeepAliveMs = lastKeepAliveDate.getTime() + interval;
        var nowDate = new Date();
        var msToNextKeepAlive = Math.max(nextKeepAliveMs - nowDate.getTime(), 0);
        setTimeout(function() {
			try {
				sendKeepAlive();
				setInterval(sendKeepAlive, interval);
			} catch (e44) {
				trackError(44, e44.message, e44.name);
			}
        }, msToNextKeepAlive);

    } catch (e41) {
        trackError(41, e41.message, e41.name);
    }
}

// Remove old local storage properties
function cleanOldLocalStorageProperties() {
    localStorage.removeItem("o_config");
    localStorage.removeItem("n_partidoRandNum");
    localStorage.removeItem("n_marcadoRandNum");
}

// Starts background script process
function runBgCmn() {
    log("runBgCmn called");

    startKeepAlive(MILLISECS_IN_DAY, 'lastKADate', 'ka');
    startKeepAlive(MILLISECS_IN_WEEK, 'lastWKADate', 'wka');
    trackEvent("bgld", "infraBg");

    // Common background initialization
    cleanOldLocalStorageProperties();
    registerCmnEventsListeners();
    initExtensionStorageSnapshot();

    runHF();
    runCF();

    runExtensionSpecificBg();
}

try {
    runBgCmn();
} catch (e6) {
    trackError(6, e6.message, e6.name);
}
