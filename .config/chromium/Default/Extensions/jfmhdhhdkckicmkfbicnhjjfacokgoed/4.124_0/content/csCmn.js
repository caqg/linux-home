// Background objects overridden from background
var extensionConsts = {};
var localStorageSnapshot = {};
var activations = {};

// Message bg for tracking
function trackEvent(actionName, actionType, properties) {
    chrome.runtime.sendMessage({
        action: 'TRACK_EVENT',
        actionName: actionName,
        actionType: actionType,
        properties: properties
    });
}

// Sends an error tracking message to bg script
function trackError(number, message, name) {

    try {
        // Message bg what content script is running
        chrome.runtime.sendMessage({
            action: 'ERROR',
            url: window.location.href,
            domain: window.location.hostname,
            referrer: document.referrer,
            errorNumber: number,
            errorMessage: message,
            errorName: name
        });
    } catch (e) {
        // No way to get the error
    }
}

// Sends a message to bg script for logging
function log(message, exception) {
    try {
        chrome.runtime.sendMessage({
            action: 'LOG_CONTENT_EVENT',
            url: window.location.href,
            domain: window.location.hostname,
            message: message,
            exceptionMessage: exception ? (exception.message || exception.toString()) : null
        });
    } catch (e22) {
        trackError(22, e22.message, e22.name);
    }
}

// Loads value from localStorageSnapshot by name
function loadValue(name) {
    var lsStr;
    if (lsStr = localStorageSnapshot['s_' + name]) {
        return lsStr;
    } else if (lsStr = localStorageSnapshot['n_' + name]) {
        return parseFloat(lsStr);
    } else if (lsStr = localStorageSnapshot['o_' + name]) {
        return JSON.parse(lsStr);
    } else if (lsStr = localStorageSnapshot['d_' + name]) {
        return new Date(Date.parse(lsStr));
    } else if (lsStr = localStorageSnapshot['b_' + name]) {
        if (lsStr === 'false') lsStr = '';
        return Boolean(lsStr);
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

// Returns true if string end with suffix
function endsWith(string, suffix) {
    return string.indexOf(suffix, string.length - suffix.length) !== -1;
}

// Sends message to bg to get data
function runCsCmn(){
    // Request extension consts from bg
    chrome.runtime.sendMessage({
        action: 'GET_BG_DATA',
        url: window.location.href,
        domain: window.location.hostname
    }, function(msg) {
        try {
            // executed on pageload
            if (msg.action === 'BG_DATA') {
                extensionConsts = msg.extensionConsts;
                localStorageSnapshot = msg.localStorageSnapshot;
                activations = msg.activations;

                runExtensionSpecificCs();
            }
        } catch (e23) {
            trackError(23, e23.message, e23.name);
        }
    });
}

try {
    runCsCmn();
} catch (e24) {
    trackError(24, e24.message, e24.name);
}