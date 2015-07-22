//#region Rapid

/*jshint smarttabs:true, curly:true, forin:true, unused:true*/
if (typeof YAHOO === "undefined" || !YAHOO) {
    YAHOO = {};
}
YAHOO.i13n = YAHOO.i13n || {};

YAHOO.i13n.EventTypes = (function () {
    var RICHVIEW = 'richview';
    var CONTENTMODIFICATION = 'contentmodification';
    function EventType(yqlid, eventName, spaceidPrefix) {
        this.yqlid = yqlid;
        this.eventName = eventName;
        this.spaceidPrefix = spaceidPrefix;
    }
    EventType.prototype = {
        getYQLID: function () { return this.yqlid; },
        getEventName: function () { return this.eventName; }
    };
    var eventMapping = {
        'pageview': new EventType('pv', 'pageview', ''),
        'simple': new EventType('lv', 'event', 'P'),
        'linkview': new EventType('lv', 'linkview', 'P'),
        'richview': new EventType(RICHVIEW, RICHVIEW, 'R'),
        'contentmodification': new EventType(RICHVIEW, CONTENTMODIFICATION, 'R'),
        'dwell': new EventType('lv', 'dwell', 'D')
    };
    return {
        getEventByName: function (name) { return eventMapping[name]; }
    };
})();

YAHOO.i13n.RapidCore = function (old_conf) {
    function initConfig(conf) {
        var global = YAHOO.i13n,
            TEST_ID = YAHOO.i13n.TEST_ID || conf.test_id,
            loc = conf.location || document.location.href;

        if (TEST_ID) {
            TEST_ID = U.norm('' + TEST_ID);
        }

        var DEFAULT_COMPR_LOWER = 300,
            DEFAULT_COMPR_TIMEOUT = 700,
            DEFAULT_CLICK_TIMEOUT = 10000;

        var override = conf.override || {};

        var rv = {
            override: override,
            version: '3.23',
            spaceid: U.norm(override.spaceid || YAHOO.i13n.SPACEID || conf.spaceid),
            yrid: U.norm(conf.yrid || ''),
            // optout - use oo as the interface for devs since it's
            // visible in the pages.  'optout' is actually sent in
            // the YQL request, however.
            oo: (conf.oo ? '1' : '0'),
            // nologging - use nol to not log Y/T cookies
            nol: (conf.nol ? '1' : '0'),
            fing: conf.use_fing == 1,
            test_id: TEST_ID,
            yql_host: conf.yql_host || "geo.query.yahoo.com",
            yql_path: conf.yql_path || "/v1/public/yql",
            click_timeout: conf.click_timeout || DEFAULT_CLICK_TIMEOUT,
            compr_timeout: conf.compr_timeout || DEFAULT_COMPR_TIMEOUT,
            compr_on: (conf.compr_on !== false),
            compr_type: conf.compr_type || 'deflate',
            webworker_file: YAHOO.i13n.WEBWORKER_FILE || conf.webworker_file || 'rapidworker-1.2.js',
            deb: (conf.debug === true),
            ldbg: (conf.ldbg > 0 ? true : loc.indexOf('yhldebug=1') > 0),
            async_all_clicks: (conf.async_all_clicks === true),
            click_postmsg: (conf.click_postmsg || {}),
            ex: (conf.ex === true),
            persist_asid: (conf.persist_asid === true),
            loc: loc
        };

        var compr_timeout = rv.compr_timeout * 1;
        if (!U.isNum(compr_timeout)) {
            rv.compr_timeout = DEFAULT_COMPR_TIMEOUT;
        } else {
            rv.compr_timeout = getValueWithBounds(compr_timeout, DEFAULT_COMPR_LOWER, DEFAULT_COMPR_TIMEOUT);
        }

        if (rv.click_timeout != DEFAULT_CLICK_TIMEOUT) {
            logWarning('Click timeout set to ' + rv.click_timeout + 'ms (default 10000ms)');
        }

        return rv;
    }

    function absorb_hash(base, override) {
        var rv = {};
        if (base && U.isObj(base)) {
            for (var k in base) {
                if (!Object.prototype.hasOwnProperty || U.hasOwn(base, k)) {
                    rv[k] = base[k];
                }
            }
        }
        if (override && U.isObj(override)) {
            for (var k in override) {
                if (!Object.prototype.hasOwnProperty || U.hasOwn(override, k)) {
                    rv[k] = override[k];
                }
            }
        }
        return rv;
    }

    function CustomEvent(eventType, eventName, data, outcome) {
        data = data || {};
        var type = null;
        // if eventType is not null, then it's a YAHOO.i13n.EventType from which we can extract data
        // otherwise it was likely a simple event
        if (eventType) {
            type = YAHOO.i13n.EventTypes.getEventByName(eventType);
            data['_E'] = type.getEventName();
            eventName = data['_E'];
        }
        else {
            data['_E'] = eventName || '_';
        }
        if (outcome) {
            data.outcm = outcome;
        }
        return {
            type: type,
            name: eventName,
            data: data,
            outcome: outcome
        };
    }

    function KVMap() {
    }

    KVMap.prototype = {
        ser: function () {
            return U.ser(this.map);
        },
        set: function (k, v) {
            var val = (v ? U.norm(v) : v);
            if (val === undefined || val === null) {
                val = '';
            }
            if (val !== null && U.isStr(val)) {
                val = val.replace(/\\/g, '\\\\');
            }
            // ensure max ult key/value sizes respected
            if (val.length > U.MAX_VALUE_LENGTH) {
                val = val.substring(0, U.MAX_VALUE_LENGTH);
            }
            if (U.isValidPair(k, val)) {
                this.map[U.norm(k)] = val;
                this.count++;
            }
        },
        get: function (k) {
            return this.map[k];
        },
        getAll: function () {
            return this.map;
        },
        absorb: function (other) {
            if (!other || !U.isObj(other)) { return; }
            for (var k in other) {
                if (!Object.prototype.hasOwnProperty || U.hasOwn(other, k)) {
                    this.set(k, other[k]);
                }
            }
        },
        absorb_filter: function (other, f) {
            if (!other || !U.isObj(other)) { return; }
            for (var k in other) {
                if (f && !f.call(null, k)) {
                    continue;
                }
                if (!Object.prototype.hasOwnProperty || U.hasOwn(other, k)) {
                    this.set(k, other[k]);
                }
            }
        },
        getSize: function () { return this.count; }
    };

    function PageParams(initialVals) {
        this.map = {}; this.count = 0;
        if (initialVals) {
            this.absorb(initialVals);
        }
    }

    PageParams.prototype = new KVMap();
    PageParams.prototype.constructor = KVMap;
    /**
     * Small static method to help build PP from existing
     * page params, usually the conf.keys.
     **/
    PageParams.makeFromPP = function (existingPageParams) {
        var rv = new PageParams();
        if (existingPageParams) {
            rv.absorb(existingPageParams.getAll());
        }
        return rv;
    };

    var U = Utils(old_conf),
        comp_types = { // maps the strings passed into the conf to integers used when sent to YQL
            'none': 0,
            'gzip': 1,
            'lzw': 2,
            'deflate': 3
        };

    function logPre() {
        return 'Rapid-' + conf.version + '(' + (new Date().getTime()) + '):'
    }

    function logWarning(msg) {
        console.warn('RAPID WARNING: ' + msg);
    }

    function logError(msg) {
        console.error('RAPID ERROR: ' + msg);
    }

    function logDebug(msg) {
        if (conf.ldbg) {
            console.log(logPre() + msg);
        }
    }

    function initKeys() {
        // Place-holder for adding keys specific to rapid-core
        var rv = new PageParams();
        return rv;
    }

    function getValueWithBounds(value, lower, upper) {
        if (value < lower) {
            return lower;
        }
        if (value > upper) {
            return upper;
        }
        return value;
    }

    function Uploader() {
        // compressed: should we compress the data?
        // 0=no comp; 1=gzip; 2=lzw
        // only supporting lzw right now 
        function getYQLURI(compressed) {
            // try extremely hard to avoid POST caching.
            // it's happened in mobile safari in iOS6, so anything is possible.
            var debug = conf.deb,
                rnd = U.rand(),
                rv = [U.curProto(),
                    conf.yql_host,
                    conf.yql_path,
                    '?yhlVer=2&yhlClient=rapid&yhlS=', conf.spaceid,
                    ((debug === true) ? '&yhlEnv=staging' : ''),
                    ((debug === true || conf.ldbg) ? '&debug=true&diagnostics=true' : ''),
                    ((U.isIE && U.ieV) ? '&yhlUA=ie' + U.ieV : ''),
                    ((U.isIE && U.ieV == 8) ? '&format=json' : ''),
                    '&yhlCT=2',
                    '&yhlBTMS=', (new Date()).valueOf(),
                    '&yhlClientVer=', conf.version,
                    '&yhlRnd=', rnd,
                    '&yhlCompressed=', compressed || 0,
                    (conf.gen_bcookie) ? '&yhlBcookie=1' : ''
                ].join('');
            if (conf.ldbg) {
                logDebug(rv);
            }
            return rv;
        }

        function sendToYQL(pay, compressed, retryIfFails, cb) {
            var xhr = U.getXHR(),
                url = getYQLURI(compressed);
            xhr.open('POST', url, true); //async
            xhr.withCredentials = true;
            // added charset in 3.5
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

            var onError = function (msg, extra) {
                // prevent reporting from both error listeners
                onError = function() {};

                if (retryIfFails) {
                    if (typeof cb === 'function') {
                        // a retry failed - call cb with an error
                        cb(msg, extra);
                    }
                } else {
                    // send a retry POST
                    sendToYQL(pay, compressed, true, cb);
                }
            }

            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4) {
                    if (conf.ldbg) {
                        logDebug(xhr.status + ':xhr response: ' + xhr.responseText);
                    }

                    if (xhr.status !== 200) {
                        onError("xhr_error", xhr.status);
                    } else {
                        if (typeof cb === 'function') {
                            // success,c all cb without args
                            cb();
                        }
                    }
                }
            };
            xhr.onerror = function () {
                onError("xhr_error", xhr.status);
            };

            xhr.send(pay);
        }

        function yqlRecordTypeFor(isPageView, options) {
            if (isPageView) {
                return 'pv';
            }
            if (options && options.event) {
                return options.event.type.getYQLID();
            }
            return 'lv';
        }

        function makeInvisible(el) {
            var none = 'display:none;';
            if (U.isIE && (U.ieV === 6 || U.ieV === 7 || U.ieV === 8)) {
                el.style.setAttribute('cssText', none, 0);
            } else {
                U.sa(el, 'style', none);
            }
        }

        function makeIFrame(frameName) {
            var frame = null;
            if (U.isIE && U.ieV <= 8) {
                // IE6 needs a src on the iframe on https pages
                // See:http://social.msdn.microsoft.com/Forums/ie/en-US/4cddd959-15a1-46f9-83e0-f832d35f1253/ie6-sslhttps-nonsecure-items
                var src = '';
                if (U.isSecure() && U.ieV === 6) {
                    src = 'src="https://geo.yahoo.com/b.html"';
                }
                frame = document.createElement('<iframe ' + src + ' name="' + frameName + '"></iframe>');
            } else {
                frame = document.createElement('iframe');
            }
            frame.name = frameName;
            return frame;
        }

        function genRandIframeName() {
            return 'rapid_if_' + U.rand();
        }

        function hideLoadingBar() {
            setTimeout(function () {
                var frame = makeIFrame('');
                U.addEvent(frame, 'load', function () {
                    U.rmBodyEl(frame);
                });
                U.appBodyEl(frame);
            }, 1);
        }

        function sendViaIframe(pay, compression, cb) {
            var frame = null,
                form = U.make('form'),
                input = U.make('input'),
                curFrameName = genRandIframeName(),
                curFormId = genRandIframeName(),
                encType = 'application/x-www-form-urlencoded;charset=UTF-8';
            frame = makeIFrame(curFrameName);
            makeInvisible(frame);
            makeInvisible(form);
            form.id = curFormId;
            form.method = 'POST';
            form.action = getYQLURI(compression);
            form.target = curFrameName;
            // added in 3.5
            // changing the attribute directly causes errors in IE7, use setAttribute instead
            if (U.isIE && U.ieV <= 7) {
                form.setAttribute('enctype', encType);
            } else {
                form.setAttribute('enctype', encType);
                form.setAttribute('encoding', encType);
            }
            // end added in 3.5
            input.name = 'q';
            input.value = pay;
            if (U.isIE && U.ieV >= 10) { // IE 10 (perhaps more?) massively fails w/o this condition
                input.type = 'submit';
            }

            form.appendChild(input);
            var eventName = 'load',
                onloadHandler = function () {
                    var response = '';
                    // get the iframe content for debugging.  This only works
                    // when the YQL host we set in yql_conf is the same host
                    // as the test page rapid is running in.  That is,
                    // if yql_host is not set, this definitely will not work.
                    if (conf.ldbg && (!U.isIE || U.ieV >= 9)) {
                        var ifr = frame.contentDocument || frame.contentWindow.document;
                        response = ifr.body.innerHTML;
                    }
                    U.rmEvent(frame, eventName, onloadHandler);
                    // firefox 3.0.1 (perhaps others) continuously loads
                    // unless you delay the frame removal
                    // See: http://www.bennadel.com/blog/1336-FireFox-Never-Stops-Loading-With-iFrame-Submission.html
                    setTimeout(function () {
                        U.rmBodyEl(frame);
                        U.rmBodyEl(form);
                    }, 0);
                    if (conf.ldbg) {
                        logDebug('iframe resp: ' + response);
                    }
                    // hide the loading bar in IE7
                    if (U.isIE && U.ieV <= 7) {
                        hideLoadingBar();
                    }
                };
            U.addEvent(frame, eventName, onloadHandler);
            U.appBodyEl(frame); // append the frame to document body
            U.appBodyEl(form); // append the form to the document body
            form.submit();

            if (typeof cb === 'function') {
                setTimeout(cb, 0);
            }
        }
        /***
         * Builds up an array of pageview records.
         * @param mods Array of module objects
         * @param isPageView Boolean indicating whether we are going
         *    to log a pv or not.
         * @param sendPosition Boolean for sending a _p (position) key
         * @param pageParams Optional object of extra page params to send along
         */

        function buildPageRows(mods, isPageView, sendPosition, pageParams, options) {
            return [{
                't': yqlRecordTypeFor(isPageView, options),
                's': conf.spaceid,
                'pp': buildPageParams(isPageView, pageParams).getAll(),
                '_ts': U.ts(),
                'lv': buildModulesList(mods)
            }];
        }

        /**
         * Builds new representation of page params object based
         * on conf.keys.  Immutable.
         * @param isPageView Boolean - flag for a pageview record..
         * @param pageParams Object - optional object of page params to send along.
         */

        function buildPageParams(isPageView, pageParams) {
            var rv = initKeys();
            rv.absorb(pageParams);
            if (isPageView) {
                rv.set('A_', 1);
            }
            return rv;
        }

        function buildModulesList(modules) {
            // We dont have any linkviews now
            var rv = {};
            return rv;
        }

        /**
         * Builds a YQL statement with the given JSON payload.
         * @param json The JSON payload body to send
         * @param needKey: do we need the q= part of the POST body?
         *   If using iframe, then we don't need to add it here.
         *   If using CORS, then we need to manually add it.
         * @param doEncode: do we need to uri encode the data?
         *        In iframe case, we don't.
         **/

        function buildYQLPostBody(json, needKey, doEncode) {
            // Select stmt for flickr: http://bug.corp.yahoo.com/show_bug.cgi?id=6602886
            var s = 'select * from x where a = \'' + json + '\'';
            return (needKey ? 'q=' : '') + (doEncode ? U.enc(s) : s);
        }

        /**
         * Assembles a JSON payload for YQL.
         * @param rowBuilderFunc - function used to assemble the rows 'r' data.  Depending on the type of payload
         *         we're sending (refreshed content vs non-refreshed, r changes.)
         **/
        function buildJSON(rowBuilderFunc) {
            var data = {
                'bp': buildBP(),
                'r': rowBuilderFunc.call(0),
                'yrid': conf.yrid,
                'optout': conf.oo,
                'nol': conf.nol
            };
            return U.toJSON(data);
        }

        /**
         * For the _pl key:
         * 1= Clientside rapid js
         * 2= Rapid Pro
         * 3= Server side (rapid track) supercedes A_ss key
         * 4= iOS
         * 5= Android
         **/
        function buildBP() {
            var rv = {
                '_pl': 1,
                'A_v': conf.version
            };
            if (conf.ex) {
                rv['_ex'] = 1;
            }
            if (!rv['_bt']) {
                rv['_bt'] = 'rapid';
            }
            var protocol = window.location.protocol || '';
            protocol = protocol.replace(/:$/, "");
            rv['A_pr'] = protocol;
            return rv;
        }

        function _rapidConditionalSend(json, cb) {
            // useful function to send via to YQL via CORS or iframe
            var ldbg = conf.ldbg;

            function exec(jsonInsertData, compression) {
                // when we send over uncompressed and in clear json, we need to escape single quote
                // since YQL is expecting the json string to have surrounding single quotes.
                if (compression === 0) {
                    jsonInsertData = jsonInsertData.replace(/'/g, "\\\'");
                }
                if (ldbg) {
                    logDebug('body: ' + jsonInsertData);
                }

                // function buildYQLPostBody(json, needKey, doEncode);
                if (U.hasCORS()) { // we can do CORS
                    body = buildYQLPostBody(jsonInsertData, true, true);
                    sendToYQL(body, compression, false, cb);
                } else { //iframe
                    body = buildYQLPostBody(jsonInsertData, 0, 0);
                    sendViaIframe(body, compression, cb);
                }
            }

            var body = '',
                compressionInt = comp_types[conf.compr_type];
            // compressionInt > 1 since we dont have gzip in rapid so don't allow.
            if (conf.compr_on && U.hasWorkers() && compressionInt > 1 && json.length > (2 * 1024)) { //compress in another thread
                if (ldbg) {
                    logDebug('Looking for worker:' + conf.webworker_file + ', compr timeout:' + conf.compr_timeout);
                }
                try {
                    var w = new Worker(conf.webworker_file),
                        sent = false,
                        tid = null,
                        compressionStartTime = 0;
                    function failSend() {
                        if (!sent) {
                            sent = true;
                            exec(json, 0);
                            if (ldbg) { logDebug('sent in failSend'); }
                        }
                    }
                    w.onerror = function (error) {
                        clearTimeout(tid);
                        failSend();
                        logWarning(error.message);
                        w.terminate();
                    };
                    w.onmessage = function (event) {
                        clearTimeout(tid);
                        var compressionEndTime = U.tms();
                        if (event.data === 'Decompress fail' || event.data === 'Compress fail' || event.data.indexOf("error:") == 0) {
                            if (ldbg) { logDebug(event.data); }
                            failSend();
                        }
                        if (!sent) {
                            sent = true;
                            exec(event.data, compressionInt);
                        }
                        if (ldbg) {
                            logDebug('Ratio (' + event.data.length + '/' + json.length + '): ' + (event.data.length * 100.0 / json.length).toFixed(2) + '% -> C_T: ' + (compressionEndTime - compressionStartTime) + ' ms (' + compressionEndTime + '-' + compressionStartTime + ')');
                        }
                        w.terminate();
                    };
                    if (ldbg) {
                        logDebug('posting to worker: ' + json);
                    }
                    compressionStartTime = U.tms();
                    w.postMessage({
                        type: compressionInt,
                        json: json
                    });
                    // this timeout will happen if the worker took too long or if the worker js is missing
                    tid = setTimeout(function () {
                        failSend();
                        w.terminate();
                    }, conf.compr_timeout);
                } catch (e) {
                    if (ldbg) { logDebug('compression worker exception ' + e); }
                    exec(json, 0);
                }
            }
            else {
                // the 2nd arg of 0 is the uncompressed flag
                exec(json, 0);
            }
        }

        return {
            sendULTEvent: function (customEvent, cb) {
                var customPP = {};
                if (customEvent && customEvent.data) {
                    customPP = customEvent.data;
                }
                if (customEvent && customEvent.type) {
                    customPP['_E'] = customEvent.type.spaceidPrefix;
                }
                var json = buildJSON(function () {
                    return buildPageRows(null, false, false, customPP, customEvent.options);
                });
                _rapidConditionalSend(json, cb);
            },
            sendEvents: function (customEvent, cb) {
                this.sendULTEvent(customEvent, cb);
            }
        }

    }

    var conf = initConfig(old_conf);
    var uploader = Uploader();

    return {
        'beaconEvent': function (event, data, outcome, cb) {
            if (conf.ldbg) {
                logDebug('beaconEvent: event="' + event + '" data = ' + U.fData(data) + ' outcome = ' + outcome);
            }
            var ev = CustomEvent(0, event, data, outcome);
            uploader.sendEvents(ev, cb);
        }
    }
    function Utils(old_conf) {
        var ua = navigator.userAgent,
            OP = Object.prototype,
            isIE = (ua.match(/MSIE\s[^;]*/) || ua.match(/Trident\/[^;]*/) ? 1 : 0),
            isWebkit = ((/KHTML/).test(ua) ? 1 : 0),
            isIOS = (ua.match(/(iPhone|iPad|iPod)/ig) !== null),
            isAndroid = (ua.indexOf('android') > -1),
            isIOSSafari = (isIOS && (ua.match(/AppleWebKit/) !== null)),
            isSafari = (ua.match(/AppleWebKit/) !== null && ua.match(/Chrome/) === null),
        // considered garbage, thing we convert to empty string
            garbage_regex = new RegExp(/\ufeff|\uffef|[\u0000-\u001f]|[\ue000-\uf8ff]/g),
        // in particular, \u00a0 (non-breaking space) causes compression failures on windows
        // this is everything we want to convert to single spaces
            spaces_regex = new RegExp(/[\u007f-\u00a0]|\s{2,}/g),
            HTTP = 'http://',
            HTTPS = 'https://',
            KLASS = 'class',
            SPACE = ' ',
            sampling_hash_mod = -1,
            MAX_VALUE_LENGTH = 300,
            ieV = -1,
            isHTTPS = (window.location.protocol === 'https:');

        if (isIE) {
            if (navigator.appVersion.match(/MSIE/)) {
                ieV = parseFloat(navigator.appVersion.split("MSIE")[1]);
            } else {
                ieV = parseFloat(navigator.appVersion.split("; rv:")[1]);
            }
        }
        return {
            isIE: isIE,
            isIOSSafari: isIOSSafari,
            isSafari: isSafari,
            isWebkit: isWebkit,
            ieV: ieV,
            MAX_VALUE_LENGTH: old_conf.MAX_VALUE_LENGTH || MAX_VALUE_LENGTH,
            hasOwn: function (obj, key) {
                return OP.hasOwnProperty.call(obj, key);
            },
            enc: encodeURIComponent,
            dec: decodeURIComponent,
            curProto: function () {
                return (isHTTPS ? HTTPS : HTTP);
            },
            isSecure: function () {
                return isHTTPS;
            },
            appBodyEl: function (element) {
                document.body.appendChild(element);
            },
            rmBodyEl: function (element) {
                document.body.removeChild(element);
            },
            sa: function (node, attr, val) {
                node.setAttribute(attr, val);
            },
            make: function (name, attrs) {
                var el = document.createElement(name);
                if (attrs && this.isObj(attrs)) {
                    for (var k in attrs) {
                        if (!attrs.hasOwnProperty || attrs.hasOwnProperty(k)) {
                            this.sa(el, k, attrs[k]);
                        }
                    }
                }
                return el;
            },
            addEvent: function (obj, evt, fn) {
                if (obj.addEventListener) {
                    obj.addEventListener(evt, fn, false);
                } else if (obj.attachEvent) {
                    obj.attachEvent("on" + evt, fn);
                }
            },
            rmEvent: function (obj, evt, fn) {
                if (obj.removeEventListener) {
                    obj.removeEventListener(evt, fn, false);
                } else
                if (obj.detachEvent) {
                    obj.detachEvent('on' + evt, fn);
                }
            },
            getXHR: function () {
                var factories = [
                    function () {
                        return new XMLHttpRequest();
                    },
                    function () {
                        return new ActiveXObject("Msxml2.XMLHTTP");
                    },
                    function () {
                        return new ActiveXObject("Msxml3.XMLHTTP");
                    },
                    function () {
                        return new ActiveXObject("Microsoft.XMLHTTP");
                    }
                ];

                function createXMLHTTPObject() {
                    var xmlhttp = false,
                        len = factories.length;
                    for (var i = 0; i < len; i++) {
                        try {
                            xmlhttp = factories[i]();
                        } catch (e) {
                            continue;
                        }
                        break;
                    }
                    return xmlhttp;
                }
                return createXMLHTTPObject();
            },
            hasCORS: function () {
                // Credentialed CORS only works in IE10 and better
                // http://stackoverflow.com/questions/10941281/make-a-cors-request-in-ie9-with-cookies
                if (isIE && (ieV < 10)) {
                    return false;
                }
                // ff 3.5 & 3.6 a CORS POST gets sent without it's payload
                if (window.navigator && window.navigator.userAgent &&  window.navigator.userAgent.indexOf("Firefox/3.") !== -1) {
                    return false;
                }
                if ("withCredentials" in (new XMLHttpRequest)) { // for normal browsers
                    return true;
                } else if (typeof XDomainRequest !== "undefined") { // for IE10
                    return true;
                }
                return false;
            },
            hasWorkers: function () {
                return !!window['Worker'];
            },
            trim: function (s) {
                if (!s) {
                    return s;
                }
                return s.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
            },
            isDate: function (o) {
                return OP.toString.call(o) === '[object Date]';
            },
            isArr: function (o) {
                return OP.toString.apply(o) === '[object Array]';
            },
            isStr: function (o) {
                return typeof o === 'string';
            },
            isNum: function (o) {
                return typeof o === 'number' && isFinite(o);
            },
            isNumeric: function (input) {
                return (input - 0) == input && (input + '').replace(/^\s+|\s+$/g, "").length > 0;
            },
            isObj: function (o) {
                return (o && (typeof o === 'object'));
            },
            rTN: function (n) {
                try {
                    if (n && 3 === n.nodeType) {
                        return n.parentNode;
                    }
                } catch (e) {
                    logError(e);
                }
                return n;
            },
            /******
             * From: http://twiki.corp.yahoo.com/view/SDSMain/LinkTrackApi#Client_Parameters
             * No binary data. Control characters < 0x20 are not allowed, as they are used for log field delimters.
             * Multi-byte UTF-8 characters are fine because bytes 2-4 will not be < 0x20.
             * The one exception to the no-binary-data rule is the ^B list delimiter allowed in page params.
             * Key names must be 32 bytes or less. This limit was arbitrarily chosen to save space in the logs.
             * Keys may only contain alphanumeric, underscore '_', or non-ascii UTF-8 (0x80+) chars.
             * Value length is not restricted, subject to that field's log limit for parameter data. See link and page parameter log limits below.
             *****/
            norm: function (l) {
                if (l === null) {
                    return '';
                }
                l = '' + l;
                return this.trim(l.replace(spaces_regex, ' ').replace(garbage_regex, ''));
            },
            quote: function (s) {
                var escape = /["\\\x00-\x1f\x7f-\x9f]/g,
                    lookup = {
                        '\b': '\\b',
                        '\t': '\\t',
                        '\n': '\\n',
                        '\f': '\\f',
                        '\r': '\\r',
                        '"': '\\"',
                        '\\': '\\\\'
                    },
                    DQ = '"',
                    EDQ = "\"";
                if (s.match(escape)) {
                    var rv = s.replace(escape, function (c) {
                        var cur = lookup[c];
                        if (typeof cur === 'string') {
                            return cur;
                        }
                        cur = c.charCodeAt();
                        return '\\u00' + Math.floor(cur / 16).toString(16) + (c % 16).toString(16);
                    });
                    return DQ + rv + DQ;
                }
                return EDQ + s + EDQ;
            },


            /* @license
             Copyright 2013 jQuery Foundation and other contributors

             Permission is hereby granted, free of charge, to any person obtaining a copy
             of this software and associated documentation files (the "Software"), to deal
             in the Software without restriction, including without limitation the rights
             to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
             copies of the Software, and to permit persons to whom the Software is
             furnished to do so, subject to the following conditions:

             The above copyright notice and this permission notice shall be included in
             all copies or substantial portions of the Software.

             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
             IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
             FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
             AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
             LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
             OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
             THE SOFTWARE.
             */
            // IE8 JSON.stringify is hopeless when it comes to unicode.
            // Test if JSON global present && we're not ie8 and JSON.stringify.
            // Note that ie8 would otherwise satisfy those conditions but doesn't work.
            // IE 6,7,8 would all satisfy this if statement.
            // Although there is no native JSON object in IE 6 and 7, we guard against
            // incorrect versions being placed into the window object by third party 
            // libs by using our own version.
            toJSON: JSON.stringify,
            fData: function (o) {
                if (this.isStr(o)) {
                    return o;
                }
                return this.toJSON(o);
            },
            // does s have control chars or have '=' in it
            hasCC: function (s) {
                for (var i = 0, l = s.length; i < l; i++) {
                    var c = s.charCodeAt(i);
                    if (c < 0x20 || c === '=') {
                        return true;
                    }
                }
                return false;
            },
            isValidPair: function (k, v) {
                if (k.length > 8 || v.length > U.MAX_VALUE_LENGTH) {
                    logWarning('Invalid key/value pair (' + k + '=' + v + ') Size must be < 8/300 respectively.');
                    return false;
                }
                return true;
            },
            ser: function (o, replace_empty_string) {
                if (!o) {
                    return '';
                }
                if (typeof replace_empty_string === undefined) {
                    replace_empty_string = true;
                }
                var rv = [],
                    encoded = '';
                for (var i in o) {
                    if (!Object.prototype.hasOwnProperty || this.hasOwn(o, i)) {
                        var k = i,
                            v = o[i];
                        if (k === null || v === null) {
                            continue;
                        }
                        k = k + '';
                        v = v + '';
                        if (v && v.length > U.MAX_VALUE_LENGTH) {
                            v = v.substring(0, U.MAX_VALUE_LENGTH);
                        }
                        if (!this.isValidPair(k, v)) { continue; }
                        if (!this.hasCC(k) && !this.hasCC(v)) {
                            encoded = '';
                            v = this.trim(v);
                            if ((v === '' || v === ' ') && replace_empty_string) {
                                v = '_';
                            }
                            try {
                                encoded = this.enc(k + "\x03" + v);
                                // Safari doesn't encode single-quotes, so do it manually here
                                encoded = encoded.replace(/'/g, "%27");
                            } catch (e) {
                                encoded = '_ERR_ENCODE_';
                                logError(e);
                            }
                            rv.push(encoded);
                        }
                    }
                }
                return rv.join(this.cd);
            },
            rand: function () {
                var index = 0,
                    s = '',
                    c = '';
                while (index++ < 16) {
                    var n = Math.floor(Math.random() * 62);
                    if (n < 10) {
                        c = n;
                    } else {
                        c = String.fromCharCode(n < 36 ? n + 55 : n + 61);
                    }
                    s += c;
                }
                return s;
            },
            tms: function () {
                return +new Date();
            },
            ts: function () {
                return Math.floor(new Date().valueOf() / 1000);
            }
        };
    } // U closing
};

//#endregion Rapid