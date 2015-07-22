/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Google = function(){
       var sPageDir;
		return {
        //Google Search Results Parsing, returns an array of URLs
			parsePage : function()
			{
				//Execute Search and Sponsor Link query
				executeXPathQuery = function()
				{
					if (navigator.userAgent.indexOf("MSIE 6.0") != -1)
					{
						if (window.location.href.indexOf("http://news.google.") != -1)
						{ //Note: For news.google.com - it same for IE6 and other browsers(secton below)
							//news links
							Utils.execSearchQuery("//div[starts-with(@class,'blended-wrapper')]//td//h2[starts-with(@class,'esc-lead')]//a[starts-with(@class,'article') and not(child::img)]");
							//news sub links
							Utils.execSearchQuery("//div[starts-with(@class,'blended-wrapper')]//td//div[starts-with(@class,'esc-secondary-article-title-wrapper')]/a[starts-with(@class,'article') and not(child::img)]");
							//Right news links
							Utils.execSearchQuery("//div[starts-with(@class,'story')]//div[@class='title']//a[(starts-with(@class,'usg') or contains(@class,'article'))and not(child::img)]");
							//Right mostshared links
							Utils.execSearchQuery("//div[starts-with(@class,'microblog-story')]//a[contains(@class,'usg') and not(child::img)]");
							//filtered - news links   . E.g CLick on the left pane keywords 
							Utils.execSearchQuery("//div[starts-with(@class,'story')]//h2[starts-with(@class,'title')]//a[starts-with(@class,'usg') and not(child::img)]");
							//filtered - news sub links
							Utils.execSearchQuery("//div[starts-with(@class,'story')]//div[@class='aa-inner']/a[starts-with(@class,'usg') and not(child::img)]");
							//Top/Bottom Sponsor Links
							Utils.execTopBtmSponsQuery("//table//td//div[contains(@class,'top-ad')]//a[not(child::img)]", "//table//td//div[contains(@class,'top-ad')]//span");

						}
						// Directory Search - Fix for Incident 2173804 [Sponsored links not annotated] 
						else if (window.location.href.indexOf("cat=gwd%2FTop") != -1)
						{
							// Top/Bottom Sponsor links
							Utils.execTopBtmSponsQuery("//div[contains(@class,'ta')]//a[not(child::img)]", "//div[contains(@id,'tads')]//span[@class]");
							//Right Sponsor Links
							Utils.execRightSponsQuery("//table//td//a[contains(@id,'an')]", "//table//td//div//span[(@class)]");
							//Search Results
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
						}
						else if (window.location.href.indexOf("http://www.google.com/products") != -1)
						{
							//Shopping Links ---- Start
							Utils.execSearchQuery("//div[@class='content-cont']//ol[@id='results']//li//h3//a[not(child::img)]");
							//Top sponsor links
							Utils.execTopBtmSponsQuery("//div[@class='content-cont']//div[@id='ads-top']//ol//h3//a[not(child::img)]",
												   "//div[@class='content-cont']//div[@id='ads-top']//ol//cite");
							//Bottom sponsor links
							Utils.execTopBtmSponsQuery("//div[@class='content-cont']//div[@id='ads-bot']//ol//h3//a[not(child::img)]",
													"//div[@class='content-cont']//div[@id='ads-bot']//ol//cite");
							//Additional Results- Guides
							Utils.execSearchQuery("//div[contains(@class,'guide')]/a[not(child::img)]");

						}
						//Blogs [Altered as a fix for incident: 2277195]
						else if (window.location.href.search(/[?&]tb[sm]=blg/) != -1) //tbs=blg or tbm=blg
						{
							//Search results
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[not(child::img)]");
							//Related Blogs - Fix for incident 2198261
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//li/a[not(@class)and not(child::img)]");
							//Note: Top results is not needed in IE6 as it creates dbl annotation but is needed in below section for non-IE6
						}
						else
						{
							//Search Links - Altered as was fetching the related strings in the shopping page
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
							//Top/Bottom sponsor links
							Utils.execTopBtmSponsQuery("//*[contains(@class,'ads-ad')]//a[starts-with(@id,'vs')]", "//*[contains(@class,'ads-ad')]//cite");
							Utils.execTopBtmSponsQuery("//div[contains(@class,'adStd')]/div[not(@class)]/a","//div[contains(@class,'adStd')]/a");
							//Right sponsor links
							Utils.execRightSponsQuery("//table//tbody//tr/td[@class='std']//li//a[starts-with(@id,'an')]",
												  "//table//tbody//tr/td[@class='std']//li//cite");
							//Right sponsor links with images, search string: laptop
							Utils.execRightSponsQuery("//table//tbody//tr/td[@class='std']//table[@class='ts']//td/a[not(child::img)]",
												  "//table//tbody//tr/td[@class='std']//table[@class='ts']//td/span[@class='a']");
							//Finance- Altered to work in IE8/FF
							Utils.execSearchQuery("//div[starts-with(@class,'e')]//*[@class='r']//a[not(child::img)]");
							//Books, search options->right side pane->books
							// Updated for ETrack#2626183
							Utils.execSearchQuery("//li[starts-with(@class,'g')]//h3[@class='r']/a[not(child::img)and (not(@class)) and not(starts-with(@id,'http'))]");
							// videos in web-searches dont get annotations => added
							Utils.execSearchQuery("//li[starts-with(@class,'g')]/table[starts-with(@class,'ts')]//table[starts-with(@class,'ts')]//a/img/ancestor::li/h3/a");
							//Book sub-results embedded in the search -E.g : search phrase- networks in google.com
							Utils.execSearchQuery("//li[starts-with(@class,'g')]/div/a[not(@class) and not(child::img)]");
							//News and Shopping Results
							Utils.execSearchQuery(" //*[starts-with(@class,'g')]//table[@class='ts']//td[not(@class)or (@class='tsw')]//a[not(child::img)and not(@class)][not(parent::h3)]");
							//Youtube results: google.co.in->'windows longhorn+hyoutube+youtube'
							Utils.execSearchQuery("//li[@class='g']//table[not(@class)]//td/div/a[not(@class) and not(child::img) and not(preceding-sibling::*)]");
							//Google trends - go to www.google.com/trends find the most popular in region and search for that string
							Utils.execSearchQuery("//li[@class='g']//div[@class='rbt']//tr[not(preceding-sibling::*)]/td/a[1 and not(@class)]");
							//Google search - For sub links which has different domains.
							Utils.execSearchQuery("//li[@class='g']//div[@class='rbt']//tr//td//div[@class='s']//a[not(@class)]");
							//Movies - search string: movies [Altered as a fix for Incident :2166965]
							Utils.execSearchQuery("//div[starts-with(@class,'e')]//table[not(@class)]//tr[not(@class)or @class='std']/td//a[parent::td or parent::div]");
							//Related Sites - Altered [Fix for Incident -2198871]
							Utils.execSearchQuery("//li [starts-with(@class,'g')]/div//a[(@class='l')and (following-sibling::cite)]");
							
							if (window.location.href.search(/[?&]tb[sm]=shop/) != -1) //tbs=shop or tbm=shop
							{
								//Additional Results- Guides[Specific to shopping page]
								Utils.execSearchQuery("//div[contains(@class,'guide')]/a[not(child::img)]");
							}
							else if (window.location.href.search(/[?&]tb[sm]=nws/) != -1)
							{
								//News sublinks 
								Utils.execSearchQuery("//*[starts-with(@class,'g')]//td/a[not(child::img) and not(child::cite)]");
							}
						}
					}
				
					//for news.google
					else if (window.location.href.indexOf("http://news.google.") != -1)
					{
						//news links
						Utils.execSearchQuery("//div[starts-with(@class,'blended-wrapper')]//td//h2[starts-with(@class,'esc-lead')]//a[starts-with(@class,'article') and not(child::img)]");
						//news sub links
						Utils.execSearchQuery("//div[starts-with(@class,'blended-wrapper')]//td//div[starts-with(@class,'esc-secondary-article-title-wrapper')]/a[starts-with(@class,'article') and not(child::img)]");
						//Right news links
						Utils.execSearchQuery("//div[starts-with(@class,'story')]//div[@class='title']//a[(starts-with(@class,'usg') or contains(@class,'article'))and not(child::img)]");
						//Right mostshared links
						Utils.execSearchQuery("//div[starts-with(@class,'microblog-story')]//a[contains(@class,'usg') and not(child::img)]");
						//filtered - news links   . E.g CLick on the left pane keywords 
						Utils.execSearchQuery("//div[starts-with(@class,'story')]//h2[starts-with(@class,'title')]//a[starts-with(@class,'usg') and not(child::img)]");
						//filtered - news sub links
						Utils.execSearchQuery("//div[starts-with(@class,'story')]//div[@class='aa-inner']/a[starts-with(@class,'usg') and not(child::img)]");
						//Top/Bottom Sponsor Links
						Utils.execTopBtmSponsQuery("//table//td//div[contains(@class,'top-ad')]//a[not(child::img)]", "//table//td//div[contains(@class,'top-ad')]//span");

					}
					// Directory Search - Fix for Incident 2173804 [Sponsored links not annotated] 
					else if (window.location.href.indexOf("cat=gwd%2FTop") != -1)
					{
						// Top/Bottom Sponsor links
						Utils.execTopBtmSponsQuery("//div[contains(@class,'ta')]//a[not(child::img)]", "//div[contains(@id,'tads')]//span[@class]");
						//Right Sponsor Links
						Utils.execRightSponsQuery("//table//td//a[contains(@id,'an')]", "//table//td//div//span[(@class)]");
						//Search Results
						Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
					}
					else if (window.location.href.indexOf("http://www.google.com/products") != -1)
					{
						//Shopping Links ---- Start
						Utils.execSearchQuery("//div[@class='content-cont']//ol[@id='results']//li//h3//a[not(child::img)]");
						//Top sponsor links
						Utils.execTopBtmSponsQuery("//div[@class='content-cont']//div[@id='ads-top']//ol//h3//a[not(child::img)]",
												   "//div[@class='content-cont']//div[@id='ads-top']//ol//cite");
						//Bottom sponsor links
						Utils.execTopBtmSponsQuery("//div[@class='content-cont']//div[@id='ads-bot']//ol//h3//a[not(child::img)]",
													"//div[@class='content-cont']//div[@id='ads-bot']//ol//cite");
						//Additional Results- Guides
						Utils.execSearchQuery("//div[contains(@class,'guide')]/a[not(child::img)]");

					}
					// Not annotating the Real-time updates 
					else if (window.location.href.search(/[?&]tb[sm]=(rltm|mbl)/) != -1)//tbs=rltm or tbs=mbl or tbm=rltm or tbm=mbl
					{

					}
					//Blogs[Altered as a fix for incident: 2277195]
					else if (window.location.href.search(/[?&]tb[sm]=blg/) != -1) //tbs=blg or tbm=blg
					{
						//Search results
						Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
						//Related Blogs - Fix for incident 2198261
						Utils.execSearchQuery("//*[starts-with(@class,'g')]/div//li/a[starts-with(@class,'l')and not(child::img)]");
						//Headings(Top Results, Secondary Search Results, News Results, Video Results, Blog Results, Image Results,..)[Fix for Incident no :2151820]
						//Books, search options->right side pane->books  [Altered as fix for Incident:2292052]
						Utils.execSearchQuery("//li[starts-with(@class,'g')]//h3[@class='r']/a[not(child::img)][(not(@class)) or (@class='noline')]");
					}
					else if (window.location.href.search(/[?&]tbm=vid/) != -1) // tbm=vid  // ETrack#2595682
					{
						// Any browser but IE6, IE6 seems to work OK.
						if (navigator.userAgent.indexOf("MSIE 7") != -1) 
						{
							Utils.execSearchQuery("//li[starts-with(@class, 'g')]//table[@class='ts']//tr/td[2]/a","//li[starts-with(@class, 'g')//table[@class='ts']//tr/td[2]/cite");
						}
						else
						{
						Utils.execSearchQuery("//li[starts-with(@class, 'g')]//div[@class='rc']//h3[@class='r']/a", "//li[starts-with(@class, 'g')//div[@class='s']//cite[@class='_Uc']");
						}
						// Right Sponsored Results
						Utils.execRightSponsQuery("//table//tbody//tr/td[@class='std']//table[@class='ts']//td/a[not(child::img)]",
											  "//table//tbody//tr/td[@class='std']//table[@class='ts']//td/span[@class='a']");
						// Top Sponsored results
						Utils.execTopBtmSponsQuery("//*[contains(@class,'ads-ad')]//a[starts-with(@id,'vs')]", "//*[contains(@class,'ads-ad')]//cite");
					}
					else
					{
						if ((window.location.href.search(/zh-CN/) != -1) && (Utils.IsIEDocumentMode8OrBetter())) {
							Utils.execSearchQuery("//li[starts-with(@class,'g')]//h4[@class='r']//a[not(child::img) and not(child::span)]");
							Utils.execSearchQuery("//div[@id='results']//tbody//tr//a[@class='fl']");
							// if <li> has ID, then it must have @class=l for <a>
							Utils.execSearchQuery("//li[starts-with(@class,'g') and @id]//h3//a[@class='l' and not(child::img) and not(child::span)]");
						}
						else {
							//Search Links - Altered as was fetching the related strings in the shopping page
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//*[@class='r']//a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
						}
						//Sponsor Links
						//argument 1 - Anchor Element expression
						//argument 2 - Span Text expression / equivalent to get the static link text
						//Purpose of using Argument 2 is hyperlink doesn't point to the correct url
						//Right sponsor links Etrack# 3047061 google ads are not annotated
						var isIe = /MSIE/.test(navigator.userAgent) || /Trident/.test(navigator.userAgent);
						if (isIe) {
							if (!Utils.IsIEDocumentMode8OrBetter()) {

								Utils.execRightSponsQuery("//table//tbody//tr/td[@class='std']//li//a[starts-with(@id,'an')]",
													 "//table//tbody//tr/td[@class='std']//li//cite");
							}else{
								Utils.execRightSponsQuery("//div[starts-with(@id,'rhs')]//div[@class='std']//li//a[starts-with(@id,'an')]",
													"//div[starts-with(@id,'rhs')]//div[@class='std']//li//cite");
							}
						} else {
							Utils.execRightSponsQuery("//div[starts-with(@id,'rhs')]//div[@class='std']//li//a[starts-with(@id,'van')]",
											 "//div[starts-with(@id,'rhs')]//div[@class='std']//li//div[@class='kv kva']/cite");
						}
						//Right sponsor links with images, search string: laptop
						Utils.execRightSponsQuery("//table//tbody//tr/td[@class='std']//table[@class='ts']//td/a[not(child::img)]",
											  "//table//tbody//tr/td[@class='std']//table[@class='ts']//td/span[@class='a']");
						//Top/Bottom sponsor links
						// This query will fail in IE7 because there are no 'tads', there are '     tad     '
						// Utils.execTopBtmSponsQuery("//div[starts-with(@id,'tads')]//*[starts-with(@class,'ta')]//a[starts-with(@id,'pa')or starts-with(@id,'an')]", "//div[starts-with(@id,'tads')]//*[starts-with(@class,'ta')]//cite");
						// More generic query would be to search based on id pattern
						Utils.execTopBtmSponsQuery("//*[contains(@class,'ads-ad')]//a[starts-with(@id,'vs')]", "//*[contains(@class,'ads-ad')]//cite");
						Utils.execTopBtmSponsQuery("//div[contains(@class,'adStd')]/div[not(@class)]/a","//div[contains(@class,'adStd')]/a");
						
						//Below are related to search results with images
						//Maps 
						//Utils.execSearchQuery("//li[not(@class)]/table//*[@class='r']//a[not(child::img)]");
						//Finance- Altered to work in IE8/FF
						Utils.execSearchQuery("//div[starts-with(@class,'e')]//*[@class='r']//a[not(child::img)]");
						//Google Sublinks- Fix for Incident 2201135
						Utils.execSearchQuery("//li[starts-with(@class,'g')]//h3[@class='r hcw']/a[not(child::img)]");
						//some additional search results
						//We were not annotating for specific strings like 'bars/fmr' when google threw up
						//search results in a separate section
						Utils.execSearchQuery("//div[@class='g']//*[(@class='r') and (following-sibling::div[@class='std'])]//a[not(@class) and not(child::img)]");
						//Not annotating for specific search result like "Olympic" which has separate section
						Utils.execSearchQuery("//div[@class='g rbt']//a[not(preceding-sibling::*) and not(@class) and not(child::img)]");
						//news archive results for search like "nuclear energy"
						Utils.execSearchQuery("//div[@class='e']//table//tr[@class='std']/td/a[not(@class) and not(child::img)]");
						//Shopping Results
						Utils.execSearchQuery("//*[contains (@id,'productbox')]/table//td//a[not(child::img)][not(@class) or (@class='l')]");
						//Headings(Top Results, Secondary Search Results, News Results, Video Results, Blog Results, Image Results,..)[Fix for Incident no :2151820]
						//Books, search options->right side pane->books  [Altered as fix for Incident:2292052]
						Utils.execSearchQuery("//li[starts-with(@class,'g')]//h3[@class='r' or (not(@class))]/a[not(child::img) and not(starts-with(@id,'http'))][(not(@class)) or (@class='noline')]");
						//Book sub-results embedded in the search -E.g : search phrase- networks in google.com
						Utils.execSearchQuery("//li[contains(@class,'g booksbox')]/div/a[not(@class) and not(child::img)]");
						//Video Results
						if (navigator.userAgent.indexOf("MSIE 7") != -1) //for IE 7
						{
							Utils.execSearchQuery("//li[starts-with(@class, 'g')]//table[@class='ts']//tr/td[2]/a", "//li[starts-with(@class, 'g')//table[@class='ts']//tr/td[2]/cite");
							//ETrack#2779511 : ABAT one link is not annotated.
							Utils.execSearchQuery("//div[@id='center_col']/div[@id='res']/div[@id='ires']//li[starts-with(@class,'g')]/table[@class='ts']/../h3/a");
						}
						else // for all others
						{
							Utils.execSearchQuery("//li[contains(@class,'g videobox')]/table[@class='ts']//div//td/a[not(descendant::img)]");
						}
						//Youtube results: google.co.in->'windows longhorn+hyoutube+youtube'
						Utils.execSearchQuery("//li[@class='g']//table[not(@class)]//td/div/a[not(@class) and not(child::img) and not(preceding-sibling::*)]");
						//Google trends - go to www.google.com/trends find the most popular in region and search for that string
						Utils.execSearchQuery("//li[@class='g']//div[@class='rbt']//tr[not(preceding-sibling::*)]/td/a[1 and not(@class)]");
						//Google search - For sub links which has different domains.
						Utils.execSearchQuery("//li[@class='g']//div[@class='rbt']//tr//td//div[@class='s']//a[not(@class)]");
						//Movies - search string: movies [Altered as a fix for Incident :2166965]
						Utils.execSearchQuery("//div[starts-with(@class,'e')]//table[not(@class)]//tr[not(@class)or @class='std']/td//a[parent::td or parent::div]");
						//Related Sites - Altered [Fix for Incident -2198871]
						Utils.execSearchQuery("//li [starts-with(@class,'g')]/div//a[(@class='l')and (following-sibling::cite)]");
						//News Sublinks for the web search- added as a condition to avoid double annotations in news tab
						if (window.location.href.search(/[?&]tb[sm]=nws/) == -1) //tbs=nws or tbm=nws
						{
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//table[@class='ts']//td[not(@class)or (@class='tsw') or (@class='nrtd')]/li[@class='w0']//a[not(child::img) and (@class='l')][not(parent::h3)]");
						}
						else
						{
							//News sublinks in news tab
							Utils.execSearchQuery("//*[starts-with(@class,'g')]//td/a[starts-with(@class,'l') and not(child::img) and not(child::span)]");
						}
						//Additional Results- Guides[Specific to shopping page]
						if (window.location.href.search(/[?&]tb[sm]=shop/) != -1) //tbs=shop or tbm=shop
						{
							Utils.execSearchQuery("//div[contains(@class,'guide')]/a[not(child::img)]");
						}

						//ET#2933808 : Shopping sponsored links are not annotated
						Utils.execSearchQuery("//div[@id='rhscol']/div[@id='rhs']//ol//li//table[@class='ts']//tr/td/div/div/a[not(child::img)]");
						Utils.execSearchQuery("//div[@id='rhscol']/div[@id='rhs']//ol//li//div[starts-with(@id,'plaimgdiv')]/..//a[not(child::img)]");
						Utils.execSearchQuery("//div[@id='knop']//div[starts-with(@class,'kno')]//span[@class='kno-fa']/a"); // references
						Utils.execSearchQuery("//div[@id='knop']//div[starts-with(@class,'kno')]//span[@class='kno-desca']/.."); // wiki
					}
				};

				if (typeof Utils != "undefined")
				{
					var lsarrLinkText = new Array();
					var lsFormatLink;
					var lsUnEscUrl;
					var liSearchIdx;

					executeXPathQuery();
					//Get links and anchornode list
					lsarrLinkText = Utils.getSearchText();
					if (lsarrLinkText.length > 0)
					{
						//Get Page Direction
						sPageDir = Shasta.getPageDirection().toLowerCase();
					}
					for (var i = 0; i < lsarrLinkText.length; i++)
					{
						//decode the string
						lsUnEscUrl = unescape(lsarrLinkText[i]);
						//blog and few other results has redirects and we do check for '/url?' followed by
						//'url='(for Cricket Scores in FF) or 'q='(for Cricket Scores and few others in IE) in 
						//search result link to get redirected url
						if ((liSearchIdx = lsUnEscUrl.indexOf("/url?")) != -1)
						{
							var urlMatch = lsUnEscUrl.match(/(url=|q=)/);
							if (urlMatch)
							{
								lsOriUnEscUrl = lsUnEscUrl;
								var liMatchIdx = lsUnEscUrl.indexOf(urlMatch[1]);
								//we need to stop our url extraction at next '&' that signifies the next arg in redirect and is not part of the url						 
								var liEndIdx = lsUnEscUrl.indexOf("&", liMatchIdx);
								lsUnEscUrl = lsUnEscUrl.slice(liMatchIdx + urlMatch[1].length, (-1 == liEndIdx) ? (lsUnEscUrl.length - 1) : liEndIdx);
								//if the search url is from google(google finance), redirect starts with '/'
								//and we need to add the google location url to that to make a valid url
								if (lsUnEscUrl.charAt(0) == "/")
								{
									var lsLocUrl = lsOriUnEscUrl.slice(0, liSearchIdx);
									lsUnEscUrl = lsLocUrl + lsUnEscUrl;
								}
							}
						}
						
						//if ( lsUnEscUrl.match(/adurl=/) )
						if ((liSearchIdx = lsUnEscUrl.indexOf("adurl=")) != -1)
						{
							var urlMatch = lsUnEscUrl.match(/adurl=/);
							if (urlMatch) 
							{
								lsOriUnEscUrl = lsUnEscUrl;
								var liMatchIdx = lsUnEscUrl.indexOf(urlMatch);
								//we need to stop our url extraction at next '&' that signifies the next arg in redirect and is not part of the url						 
								var liEndIdx = lsUnEscUrl.indexOf("&", liMatchIdx);
								lsUnEscUrl = lsUnEscUrl.slice(liMatchIdx + urlMatch[0].length, (-1 == liEndIdx) ? (lsUnEscUrl.length - 1) : liEndIdx);
								//if the search url is from google(google finance), redirect starts with '/'
								//and we need to add the google location url to that to make a valid url
								if (lsUnEscUrl.charAt(0) == "/")
								{
									var lsLocUrl = lsOriUnEscUrl.slice(0, liSearchIdx);
									lsUnEscUrl = lsLocUrl + lsUnEscUrl;
								}
							}
						 }   
							
						//check for google harmful sites and extract the correct url to get server ratings
						if (lsUnEscUrl.match(/\/interstitial\?/) && lsUnEscUrl.match(/google/))
						{
							var arrMatch = lsUnEscUrl.match(/[\?&]url=([^&]*)/);
							if (arrMatch)
							{
								lsUnEscUrl = arrMatch[1];
							}
						}
						lsFormatLink = Utils.getFormatLink(lsUnEscUrl);
						var liIndex = Shasta.addURL(encodeURI(lsFormatLink));
					}
				}
				return true;
			},

			createAnnotation : function()
			{
            cancelWebNavigation = function()
            {
                return false;
            };
            //Embed image within newly created <a> tag
            createEmbeddedImage = function(nswImage, applyStylePosition)
            {
                //Apply the style to enclose the markup icon within the new anchor 
                var newAnc = document.createElement('a');
                newAnc.style.textDecoration = "none";
                newAnc.style.cursor = "pointer";
                newAnc.style.padding = "0px";
                newAnc.style.display = "inline";
                newAnc.style.border = "none";
                if (applyStylePosition)
                {
                    //for "ltr" page, both <a> and <img> elements are relatively positioned
                    if (sPageDir == "ltr")
                    {
                        newAnc.style.position = "relative";
                    }
                    //for "rtl" page, both <a> and <img> elements are statically positioned
                    else
                    {
                        nswImage.style.position = "static";
                    }
                }
                newAnc.style.top = "2px";
                nswImage.style.top = "0px";
                //Cancel page load by returning false
                newAnc.onclick = cancelWebNavigation;
                //Append markup icon to new anchor element
                newAnc.appendChild(nswImage);
                return newAnc;
            };

            // Check if element is a child of the parent element
            contains = function(parent, element)
            {
                if (typeof parent == 'undefined')
                {
                    return false;
                }
                if (typeof parent.contains != 'undefined')
                {
                    return parent.contains(element); // IE has element.contains method
                }
                return false; // we dont care about FF
            };

            //Add the unknwon annotation by default against search links
            addAnnotation = function(anchorElement, response)
            {
                // Latest Results Container box (the one with scrollbars)
                var eLatestResultsContainer;

                //Get the parent node of anchor element
                var prntNode = anchorElement.parentNode;
                if (!prntNode)
                    return false; //anchorelement is getting updated, can happen in IE8 instance serach incident: 

                //Get the next sibling
                var nextNode = anchorElement.nextSibling;
                var lbAppendChild = false;
                //If anchor element doesn't have next sibling, append the annotation to the parent
                if (!nextNode)
                {
                    lbAppendChild = true;
                }

                // if the element is inside the latest results box then we dont want to apply position style
                var applyStyle = applyPositionStyle(anchorElement);
                var newElem = createEmbeddedImage(response, applyStyle);
                if (!applyStyle)
                {
                    response.style.position = "";
                }

                //Append the annotation to the parent element
                if (lbAppendChild)
                {
                    prntNode.appendChild(document.createTextNode(" "));
                    prntNode.appendChild(newElem);
                }
                //Insert the annotation before anchor's next sibling
                else
                {
                    prntNode.insertBefore(document.createTextNode(" "), nextNode);
                    prntNode.insertBefore(newElem, nextNode);
                }

                // for ie 6 & 7, sponsored links on the right side have limited visibility.
                // instead of adding annotation inline, we should add them in the next line.
                if (navigator.userAgent.search(/MSIE [67].0/) != -1)
                {
                    if (anchorElement.id && anchorElement.id.search(/an[0-9]+/) != -1)
                    {
                        anchorElement.style.display = 'block';
                    }
                } 
                // We have problems of clipped annotation with chrome, IE 8 & 9, FF 8
                // We are searching for => li[starts-with(@class,'g')]//*[@class='r']
                // Enable wrap on that.
                if (prntNode.parentNode && prntNode.parentNode.parentNode) 
                {
                    var liNode = prntNode.parentNode.parentNode;
                    if ((liNode.className.indexOf('g') == 0) && prntNode.className == 'r')
                    {   
                        prntNode.style.whiteSpace="normal";
                    }
                }

                return true;
            };

            // Check if we need to remove the position style due to zoom and layout issues which effecks only a few link. If the link is inside the given container do so
            applyPositionStyle = function(anchorElement)
            {
                //Latest results, dynamically populated inside box with scrollbar
                var eContainer = document.getElementById('rtr');
                if (eContainer != null)
                {
                    if (eContainer.parentNode.nodeName == 'OL')
                    {
                        return !contains(eContainer.parentNode, anchorElement);
                    }
                    return true;
                }
                // Google Shopping grid layout, bottom sponsored, remove position style to fix IE7 layout issue			
                eContainer = document.getElementById('ads-bot');
                if (eContainer != null)
                {
                    if (eContainer.lastChild.nodeName == 'OL')
                    {
                        return !contains(eContainer.lastChild, anchorElement);
                    }
                    return true;
                }
                return true;
            };

            //detect for SA image inserted
            detectSA = function()
            {
                var lbEnabled = Utils.IsSAEnabled();
                if (lbEnabled)
                {
                    for (var idx = 0; idx < larrNodeColl.length; idx++)
                    {
                        var prntNode = larrNodeColl[idx].parentNode.parentNode; //top parent(li)
                        var imgs = prntNode.getElementsByTagName('img');
                        for (var ind = 0; ind < imgs.length; ind++)
                        {
                            //change SA absolute position to relative to avoid
                            //overlap btw SA and Safe Web only if both of them
                            //have same parents
                            if (imgs[ind].src.match(lsSAProtocol))
                            {
                                if (imgs[ind].parentNode.parentNode == nswImg[idx].parentNode.parentNode)
                                {
                                    if (sPageDir == "ltr")
                                    {
                                        imgs[ind].parentNode.style.position = "relative";
                                        imgs[ind].style.position = "relative";
                                    }
                                    else
                                    {
                                        imgs[ind].style.position = "static";
                                    }

                                }
                                lbSAImg = true;
                                break;
                            }
                        }
                    }
                }
                //SA icon is present or SA not enabled, cancel the setInterval
                if (lbSAImg || (!lbEnabled && (++liDelayCnt > liSADetectCnt)))
                {
                    clearInterval(intval);
                }
            };

            AdjustSponsoredHeight = function(anchorElement)
            {
                // we want to adjust height only for select anchors, following is criterion
                // 1. Must be advertisement url (adurl)
                // 2. Must be on the right hand side of the page 
                //      we took care of this in .execSearchQuery()
                // 3. Must not have numbering. (num)
                // 4. Must not have any ID
                // 5. grandParent and parent must have height element set.
                var urlMatchAdurl;
                var urlMatchNum;
				if(anchorElement.href)
				{
					urlMatchAdurl = anchorElement.href.match(/adurl=/);
					urlMatchNum = anchorElement.href.match(/num=/);
				}
                var anchorID = anchorElement.id;
                
                if( urlMatchAdurl && !urlMatchNum && !anchorID)
                {
                    var lparentNode = anchorElement.parentNode;
                    if( ! lparentNode || !lparentNode.style.height)
                        return false;
                        
                    var lgrandParentNode = lparentNode.parentNode;
                    if( !lgrandParentNode || !lgrandParentNode.style.height)
                        return false;
                        
                    lgrandParentNode.style.height = "auto";
                    lparentNode.style.height = "auto";
                    
                    return true;
                }
                else
                    return false;
            };

            if (typeof Utils != "undefined")
            {
                var larrNodeColl = new Array();
                var nswImg = new Array();
                //Get anchornode list
                larrNodeColl = Utils.getSearchNodes();
                for (var i = 0; i < larrNodeColl.length; i++)
                {
                    //Create the image element applying styles
                    nswImg[i] = Utils.createImage(i);
                    //Add annotation image
                    if (!addAnnotation(larrNodeColl[i], nswImg[i]))
                    {
                        return false;
                    }
                    
                    //Adjust height
					// function is commented because it doesn't allow annotations for sponsors for nortonsafe.search.ask.com to be displayed.
					// not sure whether this function itself is needed and so just commenting out  the function call.
                    //AdjustSponsoredHeight(larrNodeColl[i]);
                }
                
                //detect for SA image inserted 
                if (larrNodeColl.length > 0)
                {
                    var liDelayCnt = 0;
                    var lbSAImg = false;
                    var liSADetectInt = Utils.getSADetectInterval();
                    var liSADetectCnt = Utils.getSADetectCnt();
                    Utils.ResetSAEnabled();
                    var lsSAProtocol = Utils.getSAProtocol();
                    var intval = setInterval(detectSA, liSADetectInt);
                }
            }
            return true;

        }
		};
}();

function sb_collectURLs(frameid, siteid, rescan) {
    if (typeof Shasta != "undefined") return Shasta.collectURLs(frameid, siteid, rescan) 
}

function sb_setResults(data){
    if(typeof Shasta != "undefined") return Shasta.setResults(data);
}

function sb_getPageDirection(){
    if(typeof Shasta != "undefined") return Shasta.getPageDirection(); 
}

  
