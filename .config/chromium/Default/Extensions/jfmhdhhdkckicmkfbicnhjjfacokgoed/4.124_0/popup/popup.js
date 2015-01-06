// Message bg for tracking
function trackEvent(actionName, actionType, properties) {
    chrome.runtime.sendMessage({ action: 'TRACK_EVENT', actionName: actionName, actionType: actionType, properties: properties });
}

// Message bg for error tracking
function trackError(e, number) {
    chrome.runtime.sendMessage({ action: 'ERROR', errorNumber: number, errorMessage: e.message, errorName: e.name });
}

// Sends message to current tab content script
function sendMsgToCS(message) {
    chrome.tabs.getSelected(null, function (tab) {
        try {
            chrome.tabs.sendMessage(tab.id, message);
        } catch (e39) {
            trackError(e39, 39);
        }
    });
}

// Handles color click event
function click(e) {
    try {
        var colorCode = e.target.id;

        // Message bg for tracking and persistence
        chrome.runtime.sendMessage({ action: 'COLOR_SELECTED_FROM_POPUP', color: colorCode });

        sendMsgToCS({ action: 'COLOR_PAGE', colorCode: colorCode });
        window.close();
    } catch (e38) {
        trackError(e38, 38);
    }
}

// Handles color mouse hover event - colors page
function mouseover(e) {
    try {
        var colorCode = e.target.id;
        sendMsgToCS({ action: 'COLOR_PAGE', colorCode: colorCode });
    } catch (e37) {
        trackError(e37, 37);
    }
}

// Handles popup window mouse out event - loads stored color
function mouseout(e) {
    try {
        e = e || window.event;
        var from = e.relatedTarget || e.toElement;
        if (!from || from.nodeName === "HTML") {
            sendMsgToCS({ action: 'LOAD_COLOR' });
        }
    } catch (e36) {
        trackError(e36, 36);
    }
}

// Tracks user icon click and registers popup window event listeners
function run() {
    trackEvent("iccl", "func");

    document.addEventListener('DOMContentLoaded', function () {
        try {
            var divs = document.querySelectorAll('div');
            for (var i = 0; i < divs.length; i++) {
                divs[i].style.backgroundColor = divs[i].id;
                divs[i].addEventListener('click', click);
                divs[i].addEventListener("mouseover", mouseover);
            }
            document.addEventListener("mouseout", mouseout);
        } catch (e35) {
            trackError(e35, 35);
        }
    });
}

try {
    run();
} catch (e40) {
    trackError(e40, 40);
}
