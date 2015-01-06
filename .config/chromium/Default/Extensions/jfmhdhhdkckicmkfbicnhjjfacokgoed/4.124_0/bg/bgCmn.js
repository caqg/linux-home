// Global variables
var state = {};
var localStorageSnapshot = {};      // All non-object local storage values - available to content scripts
var myRapidInstance;
var activations = {                 // Activations configuration
    "ywa": {
        "func": 0.01,
        "lifetime": 1.0,
        "infraBg": 0.001,
        "error": 0.1
    },
    "hellfire": 0.05,
    "hellfireTestGroup": 0.05,
    "md": 0.01,
    "cf": 1
};
var MILLISECS_IN_DAY = 1000*60*60*24;

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
function isYwaActivated(activity) {

    // Debug activity flag
    if (loadValue("activate_ywa")) return true;

    // Opt in activation
    if (!loadValue("optin")) return false;

    // Action type activation
    var activityActivationRate = activations.ywa[activity];
    if (!activityActivationRate) return false;
    return Math.random() < activityActivationRate;
}

// YWA event tracking
function trackEvent(actionName, actionType, properties) {
    try {
        //log("trackEvent called: " + actionName);

        if (!isYwaActivated(actionType)) return;

        var commonProps = getCommonTrackingProperties();
        var rate = activations.ywa[actionType];
        var mergedProps = mergeObjs(properties, commonProps);
        mergedProps['acrt'] = rate;

        log("trackEvent: " + actionName + ", actionType: " + actionType + ", mergedProps: " + JSON.stringify(mergedProps));

        //TODO: remove
        trackInfo(actionName, mergedProps);
        //TODO: remove

        //myRapidInstance.beaconEvent(actionName, mergedProps);

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
function log(message, exception, prefix) {
    if (!loadValue('debug'))
        return;
    try {
        if (exception || (message.indexOf('Error') > -1))
            console.error((prefix || "[background]: ") + message, exception);
        else
            console.log((prefix || "[background]: ") + message);
    } catch (e5) {
        console.error("failed logging an error", e5);
    }
}

// Open new tab with welcome page and opt-in message
function openInstallPage() {
    chrome.tabs.create({url: chrome.extension.getURL('install/install.html')});
}

/*
// Initiates rapid tracking
function initTracking() {
    try {

        var myConf = {
            use_rapid: false,
            yql_enabled: false,
            pageview_on_init: false,
            //debug: true, // TODO: remove
            //ldbg: 1,     // TODO: remove
            ywa: {
                project_id: 10001781593162,
                document_name: extensionConsts.extensionName
            }
        };

        YAHOO.i13n.YWA_ACTION_MAP = {
            iccl: 100,
            er: 101,
            up: 102,
            bgld: 103,
            inoi: 104,
            oi: 105,
            trcl: 106,
            pvcl: 107,
            opcl: 108,
            bgcl: 109,
            cocl: 110,
            cold: 111
        };

        myRapidInstance = new YAHOO.i13n.Rapid(myConf);

    } catch (e7) {
        log(e7.message, e7.name);
    }
}
*/

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
                        trackEvent('up', "infraBg", { 'pvvt': details.previousVersion });
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
                        log(request.message, request.exceptionMessage, sender.tab ? ("[tab #" + sender.tab.id + "]: ") : ("[tab #?]: "));
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

// Send a KA pixel in order to measure DAU
function sendDailyKA() {
    try {
        var lastKADate = loadValue("lastKADate");
        if (!lastKADate) persistValue("lastKADate", new Date(0));
        var millisecsSinceLastKA = new Date() - lastKADate;

        // It's time for new daily keep alive
        if (millisecsSinceLastKA > MILLISECS_IN_DAY) {

            persistValue("lastKADate", new Date());
            millisecsSinceLastKA = 0;
            trackEvent("ka", "lifetime");
        }
        setTimeout(sendDailyKA, MILLISECS_IN_DAY - millisecsSinceLastKA);

    } catch (e41) {
        trackError(1, e41.message, e41.name);
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

    //initTracking();

    sendDailyKA();
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