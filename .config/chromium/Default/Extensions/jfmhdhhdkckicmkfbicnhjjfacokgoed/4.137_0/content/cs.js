// Converts hex color code ro rgb
function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

// Makes a color code percent% brighter
function shadeColor(color, percent) {
    var num = parseInt(color.slice(1), 16), amt = Math.round(2.55 * percent), R = (num >> 16) + amt, B = (num >> 8 & 0x00FF) + amt, G = (num & 0x0000FF) + amt;
    return "#" + (0x1000000 + (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000 + (B < 255 ? B < 1 ? 0 : B : 255) * 0x100 + (G < 255 ? G < 1 ? 0 : G : 255)).toString(16).slice(1);
}

// Loads color from background local storage
function loadColor() {

    chrome.runtime.sendMessage({
        action: 'GET_COLOR'
    }, function (response) {
        try {
            if (response && response.colorCode) {
                colorPage(response.colorCode);
                trackEvent("cold", "func", {
                    co: response.colorCode
                });
            }
        } catch (e33) {
            trackError(33, e33.message, e33.name);
        }
    });
}

function retry(colorCode) {
    setTimeout(function() {
        colorPage(colorCode);
    }, 100);
}

// Execute specific extension logic
function runExtensionSpecificCs() {
    if (window !== window.top) return;

    if (!extensionConsts.extensionDomains.some(function (domain) {
        return endsWith(window.location.hostname, domain);
    })) {
        return;
    }
   
    chrome.runtime.sendMessage({ action: 'SHOW_PAGE_ACTION' });

    if (extensionConsts.colorPersistence)
        loadColor();

    chrome.runtime.onMessage.addListener(function (request) {
        try {
            if (!request) return;

            switch (request.action) {
                case 'COLOR_PAGE':
                    colorPage(request.colorCode);
                    break;
                case 'LOAD_COLOR':
                    loadColor();
                    break;
            }
        } catch (e34) {
            trackError(34, e34.message, e34.name);
        }
    });
}

// Specific site page color
function colorPage(colorCode) {

    if (!document.body)
        return retry(colorCode);

    jQuery("body").stop();
    jQuery("body").animate({
        backgroundColor: colorCode
    }, 120);
}

