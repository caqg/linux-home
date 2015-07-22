/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Utils = function() {
    var gsArrText = new Array();
    var garrNodes = new Array();
    var gsarrFlag = new Array();
    var giIE7 = null;

    var giFireFox = navigator.userAgent.indexOf("Firefox");
    var nodeSet;
    var nextNode;
    var tempNode;
    var gbSAEnabled;
    var mixiExcludeURL = new Array("mixi.jp", "mmall.jp", "mixi.at", "mplace.jp", "mixi.co.jp", "www.find-job.net", "mreco.jp", "mreco0.jp", "mixi-nenga.jp");
    return {
        //Check SA installed & enabled
        IsSAEnabled: function() {
            if (false == gbSAEnabled) {
                //Check for multiple methods for confirmation
                //these methods needs to be changed if there is a change in SA impl
                var SAMethods = window.BubbleHide && window.MoveBubble && window.ShowBubble && window.pop;
                if (SAMethods != undefined)
                    gbSAEnabled = true;
            }

            return gbSAEnabled;
        },
        //Reset the SAEnabled flag 
        ResetSAEnabled: function() {
            gbSAEnabled = false;
        },
        //get SA protocol used for image display
        getSAProtocol: function() {
            var lsProt;
            //protocol needs to be changed if there is a change in SA protocol
            if (giFireFox != -1)//FF
                lsProt = new RegExp(/chrome:\/\/saff\/content/);
            else//IE
                lsProt = new RegExp(/^(sacore:|siteadvisor:)/);

            return lsProt;
        },
        //return SA detect interval
        getSADetectInterval: function() {
            var liTimeinterval = 100;
            return liTimeinterval;
        },
        //return SA detect count
        getSADetectCnt: function() {
            var liMaxCount = 30;
            return liMaxCount;
        },
        //Removing leading blanks from String
        LTrim: function(str) {
            //strip out spaces and non-printable chars (chars after the 'DEL' char in ASCII table)
            for (var k = 0; k < str.length && (str.charAt(k) <= " " || str.charAt(k) > "\177"); k++);
            return str.substring(k, str.length);
        },
        //Removing trailing blanks from String
        RTrim: function(str) {
            for (var j = str.length - 1; j >= 0 && str.charAt(j) <= " "; j--);
            return str.substring(0, j + 1);
        },
        //Remove leading and trailing blanks from String
        Trim: function(str) {
            return this.LTrim(this.RTrim(str));
        },
        //Format the link with protocol and extract the exact text of link
        getFormatLink: function(sLink) {
            var lsFormatLink = sLink;
            if (!lsFormatLink.match("^http")) {
                var liSearchIdx = lsFormatLink.indexOf("-");
                if (liSearchIdx == 0 || (giFireFox != -1 && liSearchIdx == 1)) {
                    lsFormatLink = lsFormatLink.slice(liSearchIdx + 1);
                }
                lsFormatLink = this.Trim(lsFormatLink);
                //do this check b'cos few sponsor links innertext has "-http://.."
                //without this check, after removing the '-', 'http' would get added twice
                //as "http://http://..."
                if (!lsFormatLink.match("^http")) {
                    lsFormatLink = "http://" + lsFormatLink;
                }
            }
            return lsFormatLink;
        },
        //Get the linktext array which has the href/text of all search and sponsor links
        getSearchText: function() {
            return gsArrText;
        },
        //Get the anchor node of search and sponsor links
        getSearchNodes: function() {
            return garrNodes;
        },
        //Get flags which has status differentiating Sponsor / Search Links
        getSearchFlags: function() {
            return gsarrFlag;
        },
        clearAll: function(rescan) {
            var nLen = gsArrText.length;
            gsArrText = []; garrNodes = []; gsarrFlag = [];
            if (rescan || nLen > 0)
                document.sbReParse();
            return true;
        },
        //Execute XPath Query for Search Results
        execSearchQuery: function(sNodeQuery, sSearchType) {
            if (typeof sNodeQuery == "undefined")
                return false;

            //Store "normal" search for undefined type
            //and arg passed search type for valid type
            if (typeof sSearchType == "undefined")
                sSearchType = "normal";

            nodeSet = document.evaluate(sNodeQuery, document, null, 0, null);
            //iterate through each node
            while (nextNode = nodeSet.iterateNext()) {
                tempNode = nextNode;
                gsArrText.push(tempNode.href);
                garrNodes.push(tempNode);
                gsarrFlag.push(sSearchType);
            }
            return true;
        },
        //
        excludeMixiDomain: function (urlCheck) {
            for (x in mixiExcludeURL) {
                if (-1 != urlCheck.indexOf(mixiExcludeURL[x])) {
                    return false
                }
            }
            return true;
        },
        //Excute XPath Query for Mixi pate
        execMixiSearchQuery: function(sNodeQuery, sSearchType) {
            if (typeof sNodeQuery == "undefined")
                return false;

            //Store "normal" search for undefined type
            //and arg passed search type for valid type
            if (typeof sSearchType == "undefined")
                sSearchType = "normal";

            nodeSet = document.evaluate(sNodeQuery, document, null, 0, null);
            //iterate through each node
            while (nextNode = nodeSet.iterateNext()) {
                tempNode = nextNode;
                //Mixi page: what's new part, example:
                if (-1 != tempNode.href.indexOf("redirect_page")) {
                    var arrD = tempNode.href.split("&")[1].split("=")[1];
                    if (this.excludeMixiDomain(arrD)) {
                        gsArrText.push(tempNode.href);
                        garrNodes.push(tempNode);
                        gsarrFlag.push(sSearchType);
                    }
                } else if (this.excludeMixiDomain(tempNode.href)) {
                    gsArrText.push(tempNode.href);
                    garrNodes.push(tempNode);
                    gsarrFlag.push(sSearchType);
                } else if (-1 != tempNode.href.indexOf("http://mixi.jp/redirect_check.pl")) {//Home page, example:
                    var arrD2 = tempNode.href.split("url=")[1].split("&")[0];
                    if (this.excludeMixiDomain(arrD2)) {
                        gsArrText.push(arrD2);
                        garrNodes.push(tempNode);
                        gsarrFlag.push(sSearchType);
                    }
                }
            }
            return true;
        },
        //Execute Xpath Query for Mixi direct URL(external)
        execMixiDirectSearchQuery: function (sNodeQuery, sSearchType) {
            if (typeof sNodeQuery == "undefined")
                return false;
            if (!this.execMixiSearchQuery(sNodeQuery, sSearchType)) {
                return false;
            }
            //specific to mixi promotion, stript out the date from URL
            for (var i = 0; i < gsArrText.length; i++) {
                if (gsArrText[i].indexOf("&url=") != -1) {
                    var arr = gsArrText[i].split("&");
                    var arrD = arr[1].split("=");
                    if (-1 == arrD[1].indexOf("mixi.jp") && -1 == arrD[1].indexOf("mmall.jp")) {
                    gsArrText[i] = arrD[1];
                    }
                }
            }
            return true;
        },
        //Execute XPath query to get collection of node and text
        execNodeTextQuery: function(sNodeQuery, sTextQuery, sSponsType) {
            var larrSponsNode = new Array();
            var larrSponsLinkText = new Array();
            var lbRetVal = false;

            if (typeof sNodeQuery == "undefined" || typeof sTextQuery == "undefined") {
                return lbRetVal;
            }
            //execute query to get collection of node
            this.GetNodeColl(sNodeQuery, larrSponsNode);
            if (larrSponsNode.length == 0)
                return lbRetVal;

            //execute query to get link text
            this.GetTextColl(sTextQuery, larrSponsLinkText);
            //If anchor and linktext length differs, don't add it to list which otherwise displays 
            //incorrect annotation
            if (larrSponsNode.length == larrSponsLinkText.length) {
                for (i = 0; i < larrSponsNode.length; i++) {
                    gsArrText.push(larrSponsLinkText[i]);
                    garrNodes.push(larrSponsNode[i]);
                    gsarrFlag.push(sSponsType);
                }
                return true;
            }

            return lbRetVal;
        },
        //Execute XPath query for Promotion result of Baidu engine
        execNodeTextQueryforBaiduPromotion: function(sNodeQuery, sTextQuery, sSponsType) {
        if (this.execNodeTextQuery(sNodeQuery, sTextQuery, sSponsType)) {
            //specific to baidu promotion, stript out the date from URL
                for (var i = 0; i < gsArrText.length; i++) {
                    if (gsArrText[i].indexOf(" ") != -1) {
                        var arr = gsArrText[i].split(" ");
                        //FF:arr[0] will null.Need to check the first not null string.
                        for (j = 0; j < arr.length; j++) {
                            if (arr[j] != "") {
                                gsArrText[i] = arr[j];
                                break;
                            }
                        }
                    }
                }
                return true;
            }
            else
                return false;
        },
        //Execute XPath query for Promotion result of Baidu engine
        execBaiduPromotionQuery: function(sNodeQuery, sTextQuery) {
            var lsSrchType = "baidupromotion";
            //if node query is valid and text query is not defined, it mean we get the
            //href value assuming the passed exp. returns anchor node
            if (typeof sNodeQuery != "undefined" && typeof sTextQuery == "undefined") {
                return this.execSearchQuery(sNodeQuery, lsSrchType);
            }
            return this.execNodeTextQueryforBaiduPromotion(sNodeQuery, sTextQuery, lsSrchType);
        },
        //Execute XPath query for Top/Bottom Sponsor links
        execTopBtmSponsQuery: function(sNodeQuery, sTextQuery) {
            var lsSrchType = "topbottom";
            //if node query is valid and text query is not defined, it mean we get the
            //href value assuming the passed exp. returns anchor node
            if (typeof sNodeQuery != "undefined" && typeof sTextQuery == "undefined") {
                return this.execSearchQuery(sNodeQuery, lsSrchType);
            }
            return this.execNodeTextQuery(sNodeQuery, sTextQuery, lsSrchType);
        },
        //Execute XPath query for Right Sponsor links
        execRightSponsQuery: function(sNodeQuery, sTextQuery) {
            var lsSrchType = "right";
            //if node query is valid and text query is not defined, it mean get the
            //href value assuming the passed exp. returns anchor node
            if (typeof sNodeQuery != "undefined" && typeof sTextQuery == "undefined") {
                return this.execSearchQuery(sNodeQuery, lsSrchType);
            }
            return this.execNodeTextQuery(sNodeQuery, sTextQuery, "right");
        },
        //Execute XPath Query to get node set
        GetNodeColl: function(sNodeQuery, arrNode) {
            nodeSet = document.evaluate(sNodeQuery, document, null, 0, null);
            //iterate through each node
            while (nextNode = nodeSet.iterateNext()) {
                tempNode = nextNode;
                arrNode.push(tempNode);
            }
        },
        //Execute XPath Query to get collection of link text(urls) 
        GetTextColl: function(sTextQuery, arrLinkText) {
            nodeSet = document.evaluate(sTextQuery, document, null, 0, null);
            //iterate through each node
            while (nextNode = nodeSet.iterateNext()) {
                tempNode = nextNode;
                arrLinkText.push(tempNode.innerText || tempNode.textContent);
            }
        },
        //Remove Attribute
        executeXPathSponsorAttrRemoveQuery: function(xPathQuery, attrName) {
            nodeSet = document.evaluate(xPathQuery, document, null, 0, null);
            //iterate through each node
            while (nextNode = nodeSet.iterateNext()) {
                tempNode = nextNode;
                tempNode.removeAttribute(attrName);
            }
        },
        //Return Image size based on image name
        //!important - hardcoded image width and height below should be updated 
        //whenever its size is changed
        getImageSize: function(sImageName)
        {
            var objImage = new Object();
            //not a shopping image
            if(sImageName.toLowerCase().indexOf("nortoncertified") != -1)
            {
                objImage.iWidth = 62;
                objImage.iHeight = 15;
            }
            else if(sImageName.toLowerCase().indexOf("shop") == -1)
            {
                objImage.iWidth = 46;
                objImage.iHeight = 15;
            }
            else
            {   // Shopping
                objImage.iWidth = 65;
                objImage.iHeight = 15;
            }			
            return objImage;
        },
        //Create the image element and apply the style
        createImage: function(index) {
            response = document.createElement('img');
            response.className = 'l sb-l';
            //Note: Since we pull the data async, let us wait till we have data to put a rating.
            //      Setting the src attribute at this stage causes the search annotation icon not to be displayed in Firefox 2.0 when going back and forth between search pages.
            //      Look like a bug in FireFox 2.0 that it does not refresh the element when the actuall image is set.. it assume src="".
            //response.src = "";//this.getResPath(sPath) +"sb_unknownAnnotation.png";
            var imgName = Shasta.getLinkSrcImg(index);
            var imgUrl = "images/SafeBrowse/" + imgName;
			response.src = chrome.extension.getURL(imgUrl);
            response.id = Shasta.getLinkId(index);
            response.style.padding = "0px";
            response.style.border = "none";
            response.style.textDecoration = "none";
            //to line up search result and annotation, apply the below style
            //Resolve issue: If IE8 browser with IE7 documentMode, img will not display inline while text and url location are changed on dynamic page. 
            response.style.cssText = "position:relative; *position:static; *zoom:1;";
            response.style.top = "2px";
            response.style.cursor = "pointer";

            //calculate size dynamically and set actual width and height if the size is not 0
            if (response.width > 0) {
                response.style.width = response.width + "px";
                response.style.height = response.height + "px";
            }
            //set hardcoded width and height
            else {
                var objImg = this.getImageSize(imgName);
                response.style.width = objImg.iWidth + "px";
                response.style.height = objImg.iHeight + "px";
            }

            //Used addEventListener() as global event is not supported by FF
            if (giFireFox != -1) {
                response.setAttribute("onmouseover", "coShasta(this, Shasta.getFrameId(), Utils.getMouseOffset(event,this))");
                response.setAttribute("onmouseup", "coShastaMouseUp(this, Shasta.getFrameId(), event.button)");
                response.addEventListener("DOMMouseScroll", function _coShastaScroll() { coShastaScroll(this, Shasta.getFrameId()); }, false);
            }
            else {
                //remove width and height attribute as it would be set when image "src" is set
                //if not removed two width and height would be shown in DOM(one as attr and other as css)
                response.removeAttribute("width");
                response.removeAttribute("height");

                if( this.IsIEQuirkMode() ){ // If its quirkmode in IE
                    response.setAttribute("onmouseover", function(){coShasta(this, Shasta.getFrameId(), Utils.getMouseOffset(event,this));});
                 } 
                else if ( this.IsIEDocumentMode8OrBetter() ) { // set attributes in IE 8/9 only. 
					response.onmouseover = function() { Utils.coShasta(this, Shasta.getFrameId(), Utils.getMouseOffset(event,this)); };
                    //response.setAttribute("onmouseover", "coShasta(this, Shasta.getFrameId(), Utils.getMouseOffset(event,this))");
                } 
                else {  // IE 7 does not support fly-out window so we dont need to set attributes
					response.onmouseover = function() { this.coShasta(this, Shasta.getFrameId(), Utils.getMouseOffset(event,this)); };
                }

                response.onmouseup = function() { Utils.coShastaMouseUp(this, Shasta.getFrameId(), event.button); };
                response.onmousewheel = function() { Utils.coShastaScroll(this, Shasta.getFrameId()); };
            }

            return response;
        },
        //Returns the mouse x,y position relative to the DOM element
        getMouseOffset: function(e, obj) {
            if ((typeof e == "undefined") || (typeof obj == "undefined")) {
                return "-1,-1";
            }

            var coords = "";
            if (giFireFox != -1) { // FF
                coords = e.layerX + "," + e.layerY;
            }
            else { // IE
                coords = e.offsetX + "," + e.offsetY;
            }
            return coords;
        },
        // Checks to see if browser version is IE8 or greater. It also accounts for current rendering mode.
        IsIEDocumentMode8OrBetter: function () {
            if (giIE7 != null)
                return !giIE7;

            // default assume IE8 or better
            giIE7 = false;

            // This will make sure that Browser is IE7 or not
            if (navigator.userAgent.search(/MSIE [67]/) != -1) {
                giIE7 = true;
                return !giIE7;
            }

            // To make sure what kind of rendering is required, we read meta data
            // ref: http://msdn.microsoft.com/en-us/library/cc288325(v=vs.85).aspx 
            var metaTags = document.getElementsByTagName('meta');
            for (var i = 0; i < metaTags.length; i++) {
                if (metaTags[i].httpEquiv.search("X-UA-Compatible") != -1) {
                    if (metaTags[i].content == "IE=7") {
                        giIE7 = true;
                        break;
                    }
                }
            }

            if( !giIE7 && document.documentMode == 7 )
                giIE7 = true;

            return !giIE7;
        },

        // Checks to see if documentMode is quirk mode in Internet Explorer
        IsIEQuirkMode: function () {
            return (document.documentMode == 5 && (/MSIE/.test(navigator.userAgent) || /Trident/.test(navigator.userAgent)));
        },
		coShasta: function (annotationObject,frameId,mouseOffsets) {
			var obj = new Object();
			var collectionData = [];
			obj.collectionIndex = 0;			
			obj.prop = $(annotationObject).getElementProperties();
			collectionData.push(obj);
            SendMessageToNativeHost({method: "coShasta", windowId: _windowId, tabId: _tabId, frameId: frameId, collectionData:collectionData, offset: mouseOffsets});
        },
		coShastaMouseUp: function (annotationObject,frameId,button) {
			var obj = new Object();
			var collectionData = [];
			obj.collectionIndex = 0;
			obj.prop = $(annotationObject).getElementProperties();
			collectionData.push(obj);
            SendMessageToNativeHost({method: "coShastaMouseUp", windowId: _windowId, tabId: _tabId, frameId: frameId, button: button, collectionData:collectionData});
        },
		coShastaScroll: function (annotationObject,frameId) {
            SendMessageToNativeHost({method: "coShastaScroll", windowId: _windowId, tabId: _tabId});
        }
    };
} (); 
