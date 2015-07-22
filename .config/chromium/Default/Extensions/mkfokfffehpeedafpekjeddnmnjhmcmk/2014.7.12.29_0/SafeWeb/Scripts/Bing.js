/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Bing = function(){
	var gbKoreaSrchPage = false;
    var sPageDir;
	return {		
        //Bing Search Results Parsing, returns an array of URLs
        parsePage : function()
        {
            //Execute Search and SponsorLink query
            executeXPathQuery = function()
            {
                //For Korea site 
                if (window.location.href.indexOf("http://livesearch.msn.co.kr") != -1)
                {
                    //Search Results
                    Utils.execSearchQuery("//div[@class='iePngFix']//li/dl/dt/a[(@class='a_blue') and (not(child::img))]");
                    //Right Sponsor Links 
                    Utils.execRightSponsQuery("//div[@id='news_side']//*[@id='news_side_list']/li/dl//dt/a[(@class='a_blue') and (not(child::img))]");
                    //Top / Bottom Sponsor Links
                    Utils.execTopBtmSponsQuery("//*[@id='overture_list']/li/dl/dt[@class='txt_inline']/a[@class='a_blue']", "//*[@id='overture_list']/li/dl/dd[@class='txt_inline']");
                    gbKoreaSrchPage = true;
                }
                //Another Bing Korean site, looks like kr.msn.com now navigates here
                else if (window.location.href.indexOf("http://bing.search.daum.net") != -1)
                {
                    //Search Results
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//li//span[@class='tit']/a[1][not(@class)]");
                    //Knowledge
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//li//span[@class='fl']/a[1]");
                    //Images search string: laptop
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//table//td[contains(@class,'l_') or @class='txt']/a[1]");
                    //Videos
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//dd[contains(@id,'vclip_DD')]//span[@class='tit']/a[1]");
                    //Web
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//dd[@class='c_desc']//li[@class='t']/a[1]");
                    //Books search:Netowrking+pdf
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//li//span[@class='tit']/a[contains(@class,'fL')]");
                    //Dic Title search:maps (look for top title)
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//li//div[contains(@class,'dicObj')]/a[1]");

                    //sponsor links, search string: hotles, stock
                    Utils.execTopBtmSponsQuery("//div[contains(@class,'collTotAd')]//ul/li/a[1]",
                                               "//div[contains(@class,'collTotAd')]//ul/li/span[@class='url']/a");
                    //News results
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//span/a[not(child::img) and (@class='newsTit fL')]");
                    //Real-time Updates [Incident :2127360- Addressing the real-time results]
                    Utils.execSearchQuery("//div[contains(@class,'collTot')]//li[not(@class)]//p[not(child::span)]/a[not(child::img)] ");

                }
                else if (window.location.href.indexOf("http://www.bing.com/news/search") != -1) {
                    // Incident 2290707 - annotation support for bing.com news results.
                    Utils.execSearchQuery("//div[contains(@class,'sn_hd')]/a"); //bing usa
                    Utils.execSearchQuery("//div[contains(@class,'TextContainer entry-content')]/ul/li/a[not(child::img)]"); //bing india, australia
                }
                //For rest all sites
                else
                {
                    //Search Results
                    Utils.execSearchQuery("//div[@id='results']//li//div[contains(@class,'lst')]//h3/a[not(child::img)]");
                    //Incident : 3315846 New bing page.
                    Utils.execSearchQuery("//ol[@id='b_results']//li//div[contains(@class,'sb_add')]/h2/a[not(child::img)]");
                    Utils.execSearchQuery("//ol[@id='b_results']//li[contains(@class,'b_algo')]/h2/a[not(child::img)]");
                    Utils.execSearchQuery("//ol[@id='b_context']//li//div[contains(@class,'sb_add')]/h2/a[not(child::img)]");
                    //Right Sponsor Links 
                    //argument 1 - Anchor Element expression
                    //argument 2 - Span Text expression / equivalent to get the static link text
                    //Purpose of using Argument 2 is hyperlink doesn't point to the correct url
                    Utils.execRightSponsQuery("//div[starts-with(@class,'sb_adsN')]//li/div/h3/a|//div[starts-with(@class,'sb_adsN')]//li/a/h3", "//div[starts-with(@class,'sb_adsN')]//li//cite");
                    //Top / Bottom Sponsor Links
                    Utils.execTopBtmSponsQuery("//div[starts-with(@class,'sb_adsW')]//li/div/h3/a|//div[starts-with(@class,'sb_adsW')]//li/a/h3", "//div[starts-with(@class,'sb_adsW')]//li//cite");
                    //News Sub-links & Blog [e.g: 'Symantec in News']as a fix for Incident no. 2088491 & Incident no 2130196(Annotating the news results)and Blog results[fix for Incident :2088159-Addressing sublinks under blog results]
                    Utils.execSearchQuery("//div[starts-with(@class,'ans')or (@id='sa_bop')]//li//h5/a[1]");
                    //Best Results
                    Utils.execSearchQuery("//div[@class='sr_dcard' or @class='ec']//h3/a[not(child::img)]");
                    //Top local listings and Video Results
                    Utils.execSearchQuery("//div[starts-with(@class,'ans')]//h2[not(descendant::span)]/div/a[not(child::img)]");
                    Utils.execSearchQuery("//li[starts-with(@class, 'sb_ans')]//div[starts-with(@class,'ans')]//h2[not(descendant::span)]/a[not(child::img)]");
                    // BING MOVIES listing
                    Utils.execSearchQuery("//div[starts-with(@class,'ans')]//h2[descendant::span]/div/a[not(child::img)]", "align");
                    //Visual Search links and Health Link[Incident 2132812 - Annotating the visual search link ;Incident 2133630 - Bing health link is not annotated for medical terms]
                    Utils.execSearchQuery("//div[(@class='vsa')or (@class='ans')]//h2/a[not(@class) and not(child::img)]");
                    //Related Sites [ Incident 2172870- URLs in "Sites Related To:" are not annotated in bing.com]
                    Utils.execSearchQuery("//div[@id='sa_bop']//div[@class='ans3']//li[not(parent::div)]/a[not(child::img)]");
                    //Cricket scores[ Incident  2327301 - "cricket score"]
                    Utils.execSearchQuery("//div[starts-with(@class,'ans')or (@id='sa_bop')]//div[@class='sn_rct']//li//span/a[1]");
                    // Norton sponsored results are not annotated
                    Utils.execTopBtmSponsQuery("//div[@id='results_container']/div[@class='sx_m']/h3[@class='sx_t']/span[@class='sx_b']/a", "//div[@id='results_container']/div[@class='sx_m']/div[@class='sx_su']/cite");
                }
            };

            if (typeof Utils != "undefined")
            {
                executeXPathQuery();
                var lsarrLinkText = new Array();
                var lsFormatLink;
                //Get links list
                lsarrLinkText = Utils.getSearchText();
                if (lsarrLinkText.length > 0)
                {
                    //Get Page Direction
                    sPageDir = Shasta.getPageDirection().toLowerCase();
                }
                //iterate through the links and add annotation against search and sponsor link
                for (var i = 0; i < lsarrLinkText.length; i++)
                {
                    lsFormatLink = Utils.getFormatLink(unescape(lsarrLinkText[i]));
                    var liIndex = Shasta.addURL(encodeURI(lsFormatLink));
                }
            }
            return true;
        },

        createAnnotation : function()
        {
            //Check for empty text node
            IsEmptyTextNode = function(node)
            {
                if ((node.nodeType == 3) && !/\S/.test(node.nodeValue))
                    return true;

                return false;
            };
            cancelWebNavigation = function()
            {
                return false;
            };
            //Embed image within newly created <a> tag
            createEmbeddedImage = function(nswImage)
            {
                //Apply the style to enclose the markup icon within the new anchor 
                var newAnc = document.createElement('a');
                newAnc.style.textDecoration = "none";
                newAnc.style.cursor = "pointer";
                newAnc.style.padding = "0px";
                nswImage.style.top = "0px";
                newAnc.style.display = "inline";
                newAnc.href = "http://www.safeweb.norton.com";
                //Cancel page load by returning false
                newAnc.onclick = cancelWebNavigation;
                //Append markup icon to new anchor element
                newAnc.appendChild(nswImage);
                return newAnc;
            };
            //insert the annotation in search page
            addAnnotation = function(anchorElement, response)
            {
                var prntNode = anchorElement.parentNode;
                var nextNode = anchorElement.nextSibling;
                var lbAppendChild = false;
                //If anchor element doesn't have next sibling, append the annotation to the parent
                if (!nextNode || (true == IsEmptyTextNode(nextNode)))
                {
                    lbAppendChild = true;
                }
                //create embedded image
                var newAnc = createEmbeddedImage(response);
                anchorElement.style.display = "inline";

                var bFF = true;
                if (giFireFox == -1)
                {//IE
                    bFF = false;
                    //set static position to fix zoom issue
                    response.style.position = "static";
                    //For web results, we append embedded image to web page <a> tag
                    if (lsarrFlag[i].toLowerCase() == "normal")
                    {//Web Results
                        anchorElement.appendChild(document.createTextNode(" "));
                        anchorElement.appendChild(newAnc);
                    }
                    //Sponsor results
                    else
                    {
                        if (sPageDir == "ltr")
                        {
                            //set relative position to fix zoom issue
                            newAnc.style.position = "relative";
                        }
                    }
                }

                //For FF Web results and Sponsor results(IE/FF), we add the annotation
                //to web page <Heading> tag
                if ((lsarrFlag[i].toLowerCase() != "normal") || (bFF == true))
                {
                    //append to parent element
                    if (lbAppendChild)
                    {
                        prntNode.appendChild(document.createTextNode(" "));
                        prntNode.appendChild(newAnc);
                    }
                    else
                    {
                        //insert before matching pattern next sibling
                        prntNode.insertBefore(document.createTextNode(" "), nextNode);
                        prntNode.insertBefore(newAnc, nextNode);
                    }
                }
            };

            if (typeof Utils != "undefined")
            {
                var giFireFox = navigator.userAgent.indexOf("Firefox");
                var larrNodeColl = new Array();
                var lsarrFlag = new Array();
                var lsWebLayout = Shasta.getPageDirection();
                //Get flag and anchornode list
                lsarrFlag = Utils.getSearchFlags();
                larrNodeColl = Utils.getSearchNodes();
                for (var i = 0; i < larrNodeColl.length; i++)
                {
                    var response;
                    //Create the image element applying styles
                    response = Utils.createImage(i);
                    //Add Annotation
                    addAnnotation(larrNodeColl[i], response);
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

function sb_setResults(data)
{
    if (typeof Shasta != "undefined") return Shasta.setResults(data);
}

function sb_getPageDirection()
{
    if (typeof Shasta != "undefined") return Shasta.getPageDirection();
}
