/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Ask = function(){
    
        //Ask Search Results Parsing, returns an array of URLs
    return {
		parsePage : function()
        {
            //Execute Query for Search and SponsorLink
            executeXPathQuery = function()
            {
                if(window.location.href.indexOf("http://jp.ask.com") != -1)
                {
                    Utils.execTopBtmSponsQuery("//div[@class='ovbox']/a[not(@class)]/span[@class='l']", "//div[@class='ovbox']/a[not(@class)]/span[last()]");
                }
                else {
                    //Fix issue 2906104
                    var sponsoredRight = document.getElementById("sponsoredRight");
                    var midRail = document.getElementById("midRail");
                    var rrsa = document.getElementById("rr_sa");
					
					Utils.execTopBtmSponsQuery("//div[contains(@class,'adStd')]/div[not(@class)]/a/span","//div[contains(@class,'adStd')]/a/span");
                    if (null != midRail) 
                    {
                        // Fix: 2940988 
                        Utils.execTopBtmSponsQuery(".//*[@id='midRail']/div/div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='L4' or @class='newAdFont']", ".//*[@id='rpane']/div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='T10']");
                    }

                    if (null != sponsoredRight) 
                    {
                        Utils.execRightSponsQuery(".//*[@id='sponsoredRight']//div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='L4' or @class='newAdFont']", ".//*[@id='sponsoredRight']//div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='T10']");
                    }
                    else if (null != rrsa) 
                    {
                        // Fix: 2940988 
                        Utils.execRightSponsQuery(".//*[@id='rr_sa']/div/div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='L4' or @class='newAdFont']", ".//*[@id='rr_sa']/div/div[contains(@class,'spl_shd') or contains(@class,'spl_unshd')]/div[contains(@class,'spl_ad')]/a[@class='nu']/span[@class='T10']");
                    }
                }
            };
            
            if(typeof Utils != "undefined")
            {
                executeXPathQuery();
                var lsarrLinkText = new Array();
                var lsFormatLink;
                //Get the list of text links 
                lsarrLinkText = Utils.getSearchText();
                for(var i = 0;i<lsarrLinkText.length;i++)
                {
                    lsFormatLink = Utils.getFormatLink(unescape(lsarrLinkText[i]));
                    var liIndex = Shasta.addURL(encodeURI(lsFormatLink));
                }	
            }	
            return true;
        },
        
        createAnnotation : function()		
        {
            //Add safe web icon next to Search and Sponsor links
            addAnnotation = function(anchElem, response)
            {
                //Get the parent node of anchor element
                var prntNode = anchElem.parentNode;
                //Get the next node of anchor element
                var nextNode = anchElem.nextSibling;
                var lbAppendChild = false;
                
                //create new element 'a' and enclose the safe web icon in it
                var nswParent = document.createElement('a');
                //cancel the page loading by returning false
                //if this check is not done, two windows would be opened
                //on clicking safe web icon, as icon is inserted within
                //search result link. Whole sponsor content is enclosed within 'a' tag
                nswParent.setAttribute("onclick", "return false");
                if(giFireFox != -1)//Firefox
                {
                    response.style.zIndex = "0";
                }
                else//IE
                {
                    nswParent.style.position = "relative";
                }
                nswParent.appendChild(response);
                
                //If anchor element doesn't have next sibling, append the annotation to the parent
                if(!nextNode)
                {
                    lbAppendChild = true;
                }

                //Append the annotation to the parent element
                if(lbAppendChild)
                {
                     prntNode.appendChild(document.createTextNode(" "));
                     prntNode.appendChild(nswParent);
                }
                //Insert the annotation before anchor's next node
                else
                {
                     prntNode.insertBefore(document.createTextNode(" "), nextNode);
                     prntNode.insertBefore(nswParent, nextNode);
                }
            };
            
            if(typeof Utils != "undefined")
            {
                var giFireFox = navigator.userAgent.indexOf("Firefox");
                var larrNodeColl = new Array();            
                //Get list of anchor nodes to insert annotation
                larrNodeColl = Utils.getSearchNodes();
                for(var i=0;i<larrNodeColl.length;i++)
                {
                    //Create the image element applying styles
                    var response = Utils.createImage(i);
                    if(response)
                    {
                        //Add Annotation
                        addAnnotation(larrNodeColl[i], response);
                    }
                }
            }
            return true;
        }
	};
    	
}();

//To check and create events to fire.
function sb_collectURLs(frameid, siteid, rescan, isFF30orGreater) {

	if (!isFF30orGreater)
	{
		// To support FireFox 29, IE and Chrome
		if (typeof Shasta != "undefined") return Shasta.collectURLs(frameid, siteid, rescan); 
	}
	else
	{
		//Only FireFox 30 and Greater will fire the event
		var element = document.createElement("MyExtensionDataElement");          
		element.setAttribute("CollectURL", 1);
		element.setAttribute("frameid", frameid);
		element.setAttribute("siteid", siteid);
		element.setAttribute("rescan", rescan);
		document.documentElement.appendChild(element);
		
		var evt = document.createEvent("Events");               
		evt.initEvent("SBCollectURLEvent", true, false);            
		element.dispatchEvent(evt); 
		var count = 0;
		
		var sdate = new Date();
		var startTimeStamp = sdate.getTime();
		
		while (1)
		{
			var result = element.getAttribute("result");
			count++;
			
			if(result && result !== "") {
				var  resultarr = result.split(",");
				element.setAttribute("result", "");
				return resultarr;
			}
			
			var edate = new Date();
			var endTimeStamp = edate.getTime();
			var timeInterval = endTimeStamp - startTimeStamp;
			if (timeInterval > 1000)
			{
				return;
			}
		}
	}
}

function SBCollectURLEventCallback(frameid, siteid, rescan) {
    if (typeof Shasta != "undefined") return Shasta.collectURLs(frameid, siteid, rescan);
}

function sb_setResults(data){
    if(typeof Shasta != "undefined") return Shasta.setResults(data);
}

function sb_getPageDirection(){
    if(typeof Shasta != "undefined") return Shasta.getPageDirection(); 
}
