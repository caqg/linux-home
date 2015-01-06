// Message bg for event tracking
function trackEvent(actionName, actionType, properties) {
    try {
        chrome.runtime.sendMessage({
            action: 'TRACK_EVENT',
            actionName: actionName,
            actionType: actionType,
            properties: properties
        });
    } catch (e30) {
        trackError(30, e30.message, e30.name);
    }
}

// Sends an error tracking message to bg script
function trackError(number, message, name) {

    try {
        // Message bg what content script is running
        chrome.runtime.sendMessage({
            action: 'ERROR',
            errorNumber: number,
            errorMessage: message,
            errorName: name
        });
    } catch (e) {
        // No way to get the error
    }
}

// Message bg for value persistence
function persistValue(name, value) {
    chrome.runtime.sendMessage({
        action: 'PERSIST_VALUE',
        name: name,
        value: value
    });
}

// Handles finish btn click
function finish() {
    try {
        var enableCS = document.getElementById('opt_clkstrm0').checked;
        var isFirstLoad = !localStorage.b_optin;
        persistValue("optin", enableCS);
        var optInHistoryKey = "s_optinHistory";
        persistValue("optinHistory", (localStorage[optInHistoryKey] ? localStorage[optInHistoryKey] : "") + "(" + enableCS + "," + new Date() + "),");
        closeDialog();

        if (enableCS) {
            if (isFirstLoad)
                trackEvent('inoi', "lifetime");
            else
                trackEvent('oi', "lifetime");
        }
    } catch (e29) {
        trackError(29, e29.message, e29.name);
    }
}

// Handles dialog closing
function closeDialog() {
    try {
        document.getElementById('yui_3_12_0_1_1410346560334_37').style.display = 'none';
        document.getElementById('dimmer').style.display = 'none';
    } catch (e28) {
        trackError(28, e28.message, e28.name);
    }
}

// Registers dom content loaded event
function registerEventListeners() {
    document.addEventListener("DOMContentLoaded", function() {
        try {
            document.getElementById("termsLink").addEventListener("click", function() {
                trackEvent('trcl', "lifetime");
            });

            document.getElementById("privacyLink").addEventListener("click", function() {
                trackEvent('pvcl', "lifetime");
            });

            if (localStorage["b_optin"] && localStorage["b_optin"] === "false")
                document.getElementById('opt_clkstrm0').checked = false;

            var element = document.getElementById('btn_finish');
            element.focus();
            element.addEventListener('click', finish, false);

            var closeBtn = document.getElementById('yui_3_12_0_1_1410346560334_53');
            closeBtn.addEventListener('click', closeDialog, false);

            document.title = "Thank you for installing " + chrome.app.getDetails().name;

            var extensionNameSpans = document.getElementsByClassName("extensionName");
            for (var extensionNameSpanIndex in extensionNameSpans) {
                extensionNameSpans[extensionNameSpanIndex].innerText = chrome.app.getDetails().name;
            }

            document.getElementById("howItWorksSpan").innerHTML = howItWorksText;
            document.getElementById("whyShouldISpan").innerHTML = whyShouldIUseText;

            document.getElementById("chromeStoreURL").href = "https://chrome.google.com/webstore/detail/" + chrome.app.getDetails().id;
        } catch (e27) {
            trackError(27, e27.message, e27.name);
        }
    });
}

// Starts install page proccess
function runInstall() {
    trackEvent('opcl', "lifetime");
    registerEventListeners();
}

try {
    runInstall();
} catch (e26) {
    trackError(26, e26.message, e26.name);
}