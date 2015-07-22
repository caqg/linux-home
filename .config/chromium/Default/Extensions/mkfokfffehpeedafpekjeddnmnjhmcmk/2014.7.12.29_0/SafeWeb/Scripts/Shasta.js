/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Shasta = function () {
    var _sPageDir;

    var img_url = "$RESOURCES$";
    if (img_url.charAt(0) == "$") img_url = "";
    var gsResProtocol = "$RESPROTOCOL$";
    //Resource Protocol macro not replaced properly
    if (gsResProtocol.charAt(0) == "$") {
        gsResProtocol = "symres:"; //default protocol name
    }
    return {
        URLS: new Array(),
        collectURLs: function (frameid, siteid, rescan) {
			var CollectedURLs = new Array();
			var success = false;
			this.setAnnotationState(false);
            this.frame_id = frameid;
            this.site_id = siteid;
            this.URLS = [];
            Utils.clearAll(rescan);
			if((window.location.host.toLowerCase()).search("ask") >= 0 || document.referrer.search("nortonsafe.search.ask.com") >= 0)
			{
				success = Ask.parsePage();
			}
			else if((window.location.host.toLowerCase()).search("google") >= 0)
			{
				success = Google.parsePage();
			}
			else if((window.location.host.toLowerCase()).search("yahoo") >= 0)
			{
				success = Yahoo.parsePage();
			}
			else if((window.location.host.toLowerCase()).search("bing") >= 0)
			{
				success = Bing.parsePage();
			}
			
			if (success == true) {
                for (var i = 0; i < this.URLS.length; i++)
				{
					CollectedURLs[i] = this.URLS[i].url;
				}	
            }            
            return CollectedURLs;
        },
        addURL: function (url) {
            var tmpObj = new Object();
            tmpObj.id = 'sbresult_' + this.URLS.length;
            tmpObj.url = url;
            tmpObj.srcimage = 'sb_unknownannotation.png';
            tmpObj.hasResult = false;
            this.URLS.push(tmpObj);
            return this.URLS.length - 1;
        },
        setResults: function (data) {
            data = (typeof data != "undefined" && data != "") ? data : false;
            if (!data) return false;

            var xmlDoc;
            var parser;
			var isIe = /MSIE/.test(navigator.userAgent) || /Trident/.test(navigator.userAgent);
            if (isIe)//IE
            {
                xmlDoc = new ActiveXObject('Microsoft.XMLDOM');
                xmlDoc.async = false;
                xmlDoc.loadXML(data);
            }
            else {
                // Firefox or chrome
                if (/Firefox[\/\s](\d+\.\d+)/.test(navigator.userAgent)) { //Check Firefox/x.x or Firefox x.x (ignoring remaining digits);
                    var ffversion = new Number(RegExp.$1);
                    if ((ffversion <= "19") || (ffversion >= "24")) {
                        try {
                            parser = new DOMParser();       // Firefox 19 or below or 24 and above
                        }
                        catch (e) {
                            parser = new DOMParser(null);
                        }
                    }
                    else {
                        parser = new DOMParser(null);    // Firefox 20 to 23
                    }
                }
                else if (/Chrome[\/\s](\d+\.\d+)/.test(navigator.userAgent)) { //Check Chrome/x.x or Chrome x.x (ignoring remaining digits);
                    parser = new DOMParser();
                }
				//Though this section may not be relevant to PC since it deals with the Safari browser (similarly IE for Mac), they wanted to keep all the changes merged to the PC trunk.
				else if (/Safari[\/\s](\d+\.\d+)/.test(navigator.userAgent)) { //Check Safari/x.x or Safari x.x (ignoring remaining digits);
                    parser = new DOMParser();
                }

                xmlDoc = parser.parseFromString(data, "text/xml");
            }

            var root = xmlDoc.documentElement;
            if (root == null) return false;

            var urls = root.getElementsByTagName('url');
            if (urls == null || (urls != null && urls.length == 0)) return false;

            for (var i = 0; i < urls.length; i++) {
                var currentURL = urls[i];
                var index = currentURL.getElementsByTagName('index');
                index = (index.length > 0) ? index[0].firstChild.nodeValue : 0;
                var srcimage = currentURL.getElementsByTagName('srcimage');
                srcimage = (srcimage.length > 0) ? srcimage[0].firstChild.nodeValue : "sb_unknownannotation.png";
                if (this.URLS[index]) {
                    this.URLS[index].hasResult = true;
                    this.URLS[index].srcimage = srcimage;
                }
            }

            var eleFirstImg = document.getElementById('sbresult_0');
            if (undefined == eleFirstImg) {
                //create annotation, ONLY if we have not annotated before
                if((window.location.host.toLowerCase()).search("google") >= 0)
				{
					if (!Google.createAnnotation())
						return false;
					return this.setAnnotationState(true);
				}
				else if((window.location.host.toLowerCase()).search("yahoo") >= 0)
				{
					if(!Yahoo.createAnnotation())
						return false;
					return this.setAnnotationState(true);
				}
				else if((window.location.host.toLowerCase()).search("ask") >= 0)
				{
					if(!Ask.createAnnotation())
						return false;
					return this.setAnnotationState(true);
				}
				else if((window.location.host.toLowerCase()).search("bing") >= 0)
				{
					if(!Bing.createAnnotation())
						return false;
					return this.setAnnotationState(true);
				}
            }            
            return true;
        },
        //returns the 'direction' style of webpage as 'rtl' or 'ltr'
        getPageDirection: function () {
            var lsDir;

            if (window.getComputedStyle) //Firefox & Chrome
            {
                try {
                    var compStyle = window.getComputedStyle(document.body, null);
                    if(compStyle ) {
                        lsDir = _sPageDir = compStyle.direction;    // can throw exception in FF4 if window!=window.self, in that case we return cached _sPageDir
                    }
                }
                catch (e) {             
                    lsDir = _sPageDir;
                }
            }
            else //IE
                lsDir = document.body.currentStyle.blockDirection;
            return lsDir;
        },
        getLinkId: function (index) {
            return this.URLS[index].id;
        },
        getLinkSrcImg: function (index) {
            return this.URLS[index].srcimage;
        },
        getFrameId: function () {
            return this.frame_id;
        },
        setAnnotationState: function (bShow) {
            var len = this.URLS.length;
            var attrbval = (bShow == true) ? 'visible' : 'hidden';
            for (var i = 0; i < len; i++) {
                var ele = document.getElementById('sbresult_' + i);
                if (undefined != ele) {
                    ele.style.visibility = attrbval;
                }
            }
            return true;
        },
        getResProtocol: function () {
            return gsResProtocol;
        }
    };
} ();   //Init this Object
