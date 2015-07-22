/* Symantec Watermark: CB70-4860-5397-06-15-6 */
//$$NCO_SCRIPT_FILE$$ - marker do not remove
var Yahoo = function(){
	var gbHongkongSrchPage = false;
    var gbKoreanSrchPage = false; 
    var gbSponsLink = false;
    var gbAlign = false;
    var garrNodeColl = new Array();  
	return{
			//Yahoo Search Results Parsing, returns an array of URLs
			parsePage : function()
            {
                //Cancel event handler for the event of specific object
                cancelEventHandler = function(evt)
                {
                    var e = evt ? evt : window.event; 
                    if (window.event) //IE
                        e.cancelBubble=true;
                    else //FF
                        e.stopPropagation(); 
                };
                //Execute Search and Sponsor Link query
                executeXPathQuery = function()
                {
                    var lbExecute = true;
                    //For HongKong site
                    if(window.location.href.indexOf("http://hk.search.yahoo.com") != -1 )
                        
                    {
                        // Search links, 'or contains(@id,'ysch') = search text:laptop -> bottom knownledge base links
                        Utils.execSearchQuery("//div[contains(@id,'web') or contains(@id,'kp') or contains(@id,'ysch')]//li/div//a[contains(@class,'ttl')]");
                        //Knowledge links
                        Utils.execSearchQuery("//div[contains(@class,'sc-knowledge')]//li/a[not(child::img)][1]"); 
                        // Top/Bottom sponser links
                        Utils.execTopBtmSponsQuery("//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/div/a[not(child::img)][1]",
                                                    "//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/em[1]");
                        //Right Sponsor link
                        Utils.execRightSponsQuery("//div[@id='east' or contains(@id,'sec')]//ul/li[not(@class)]/a[not(child::img)]", "//div[@id='east' or contains(@id,'sec')]//li[not (@class='yschprom')]//em[(not(@class))][1]");
                        //Finance result
                        Utils.execSearchQuery("//div[@id='yschiy']/cite/a[not(child::img)]");
                        //Dictionary Results [Fix for incident :2280799]
                        Utils.execSearchQuery("//div[@class='res sc']//div/a[contains(@class,'spt')]");
                        // right sponsored links
                        Utils.execRightSponsQuery("//div[@id='east']/ul[starts-with(@class,'ead')]//li/a", "//div[@id='east']/ul[starts-with(@class,'ead')]//li/em");
                        lbExecute = false;
                        gbHongkongSrchPage = true;
                    }
                    else if(window.location.href.indexOf("http://hk.m.search.yahoo.com") != -1)//IE redirect to this location, FF to above location?
                    {
                        // Search links
                        Utils.execSearchQuery("//div[contains(@id,'web') or contains(@id,'kp')]//li/div//a[contains(@class,'ttl')]");
                        //Knowledge links
                        Utils.execSearchQuery("//div[contains(@class,'sc-knowledge')]//li/a[not(child::img)][1]"); 
                        // Top/Bottom sponser links
                        Utils.execTopBtmSponsQuery("//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/div/a[not(child::img)][1]",
                                                    "//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/em[1]");
                        //Right Sponsor link
                        Utils.execRightSponsQuery("//div[@id='east' or contains(@id,'sec')]//ul/li[not(@class)]/a[not(child::img)]", "//div[@id='east' or contains(@id,'sec')]//li[not (@class='yschprom')]//em[(not(@class))][1]");
                        //Finance result
                        Utils.execSearchQuery("//div[@id='yschiy']/cite/a[not(child::img)]");
                        //Dictionary Results [Fix for incident :2280799]
                        Utils.execSearchQuery("//div[@class='res sc']//div/a[contains(@class,'spt')]");
                        // right sponsored links
                        Utils.execRightSponsQuery("//div[@id='east']/ul[starts-with(@class,'ead')]//li/a", "//div[@id='east']/ul[starts-with(@class,'ead')]//li/em");
                        lbExecute = false;
                        gbHongkongSrchPage = true;				    
                    }
                    //For Korea site
                    else if(window.location.href.indexOf("http://kr.search.yahoo.com") != -1)
                    {
                        //Web - Altered [Altered as a fix for incident : 2279541]
                        Utils.execSearchQuery("//div[@id='web']//li//div/h3/a[not(child::img)]");
                        //Blog / Clipings and Secondary results
                        Utils.execSearchQuery("//div[starts-with(@id,'bl') or @id='vdo']//li/div[@class='cn']/h4/a[not(child::img)]");
                        //Yahoo Q&A
                        Utils.execSearchQuery("//div[@id='ks2']//div[@class='box']/p/a[not(child::img)]");
                        //Downloads
                        Utils.execSearchQuery("//div[@id='vpr']//div/strong//a[not(child::img)]");
                        //News
                        Utils.execSearchQuery("//div[@id='nws']//div[@class='box']//div[@class='rt']/p/a[not(child::img)]");
                        //Books
                        Utils.execSearchQuery("//div[@id='gg1']//div[@class='box']/span/p/a[not(child::img)]");
                        //Other Results
                        Utils.execSearchQuery("//div[@id='go']//dd/strong//a[not(child::img)and not(parent::span)]");
                        //Dictonary Results
                        Utils.execSearchQuery("//div[@id='dic']//dd/span/a[1][not(child::img)]");
                        //Map Results - Fix for incident: 2280808
                        Utils.execSearchQuery("//div[(@id='poi')]//div/h5//a[contains(@class,'spt')]");
                        //Shopping results
                        Utils.execSearchQuery("//div[@id='sp1']//dd//a[(parent::h3) or ((parent::dd) and not(child::img))]");
                        //Theme Results - Shopping theme search [Added as a fix for incident : 2279541]
                        Utils.execSearchQuery("//div[@class='yiy']/h4[(preceding-sibling::span)]/a[1]");
                        //Special Links[Added as a fix for incident : 2279541]
                        Utils.execTopBtmSponsQuery("//div[contains(@class,'special-link')]//li//h3/a[not(child::img) and not(@class)]", "//div[contains(@class,'special-link')]//li/em[1]");
                        //Premium Links -Search phrase like canon,iphone [Added as a fix for incident : 2279541]
                        Utils.execTopBtmSponsQuery("//div[contains(@class,'premium-link')]//li//h3/a[not(child::img) and not(@class)]", "//div[contains(@class,'premium-link')]//li/div/a[not(child::img) and not(@class)]");
                        //Top/Bottom Sponsor[Altered as a fix for incident : 2279541]
                        Utils.execTopBtmSponsQuery("//div[starts-with(@class,'ads horiz ')]//ul[@class='spns']//div[not(@class)]/a[not(child::img)]", "//div[starts-with(@class,'ads horiz ')]//ul[@class='spns']//em/a[not(@class) and not(child::img)]");
                        
                        gbKoreanSrchPage = true;
                    }
                    //For Japan site
                    else if (window.location.href.indexOf("http://search.yahoo.co.jp") != -1)
                    {
                        // Search links - search string:yes
                        Utils.execSearchQuery("//div[@id='mIn']//div[@class='hd']//h3/a");
                        Utils.execSearchQuery("//div[@id='mIn']//div[@class='bd']//div[@class='row']//ul/li//a[not(child::img)]"); //sub-results searchstring:toyota, ipod, news

                        // Top/Bottom sponser links search:worldcup
                        Utils.execTopBtmSponsQuery("//div[@id='mIn']//div[@class='bd']//ul/li//a[@class='t' and not(child::img)]", "//div[@id='mIn']//div[@class='bd']//ul/li//span[@class='u']");
                        //Additional Right Sponsor links(search string:ipod/worldcup/TCS)
                        Utils.execRightSponsQuery("//div[@id='sIn']//div[@class='bd']//a[not(child::img)]", "//div[@id='sIn']//div[@class='bd']//span[@class='u']");
                    } 
                    //For China site
                    else if (window.location.href.indexOf("http://search.cn.yahoo.com") != -1 ||
                            window.location.href.indexOf("http://one.cn.yahoo.com") != -1)
                    {
                        // Search links
                        Utils.execSearchQuery("//div[@class='rst' or @class='yst-web']//h3/a[not(child::img)]");
                        // Top/Bottom sponser links
                        Utils.execTopBtmSponsQuery("//div[contains(@class,'p4p') or contains(@id,'p4p')]//h3/em[1]", "//div[contains(@class,'p4p') or contains(@id,'p4p')]//h3/em[1]");
                        //Right sponser links
                        Utils.execRightSponsQuery("//div[@class='pr']//a[@class='pa']//em", "//div[@class='pr']//a[@class='pa']//div[@class='f1']//div[@class='rel']");
                    } else if (window.location.href.indexOf("http://www.yahoo.cn/s?") != -1) {
                        //Search links
                        Utils.execSearchQuery("//div[@class='main_content']/div[@class='content']/ul[@class='results']/li[@class='record']/h3[@class='title']/a");
                        //Search result:Relative information for search result(search key: beijing)
                        Utils.execSearchQuery("//div[@class='main_content']/div[@class='content']/ul[@class='results']/li[@class='record sc_news']/div/ul/li/a[@class='sub_title']");
                        //Search result:site list (search key: taobao)
                        Utils.execSearchQuery("//div[@class='main_content']/div[@class='content']/ul[@class='results']/li[@class='record']/ul[@class='sitelink']/li/a");
                    } 
                    //For Canada site
                     else if (window.location.href.indexOf("http://ca.search.yahoo.com") != -1)
                    {
                      //For Canada site double annotation is displayed due to Node duplication. 
                      //Node duplication is handled is htmlxpath.js
                      // Search links
                      Utils.execSearchQuery("//div[@id='web']//a[contains(@class,'yschttl')]"); 
                      // Top/Bottom sponser links
                      Utils.execTopBtmSponsQuery("//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/div/a[not(contains(@class,'pp-'))and not(child::img)]", "//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li//em[1]");
                      //Right Sponsor Results 
                      Utils.execRightSponsQuery("//div[@id='east']//li[not(@class)]/a[not(child::img)]", "//div[@id='east']//li//em[1]");
                      
                      // right sponsored links
                      Utils.execRightSponsQuery("//div[@id='east']/ul[starts-with(@class,'ead')]//li/a", "//div[@id='east']/ul[starts-with(@class,'ead')]//li/em");
                        
                      lbExecute = false;
                    }
                    //For Korean
                    else if (window.location.href.indexOf("http://tw.search.yahoo.com") != -1) 
                    {
                        // Search links
                        Utils.execSearchQuery("//div[contains(@id,'web')]//a[contains(@class,'ttl')]");
                        // Top/Bottom sponser links
                        gbSponsLink = Utils.execTopBtmSponsQuery("//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li//div/a[1 and not(@class) and not(child::img)]",
                                                                     "//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li//em[1 and not(parent::a)]");
                        //Knowledge+ results, shopping - string: laptop, news, kbs
                        Utils.execSearchQuery("//div[contains(@class,'sc-knowledge') or contains(@class,'sc-shopping')]//li/a[not(child::img)]");
                        //Dictionary results - string: news
                        Utils.execSearchQuery("//div[@class='res sc']/div[contains(@class,'ttl')]/a[contains(@class,'spt')and not(child::img)]");
                    }
                    //Sponsored Results Page [Fix for Incident: 2088400]
                    else if (window.location.href.indexOf("http://search.yahoo.com/sponsored_search") != -1)
                    {
                        gbSponsLink = Utils.execTopBtmSponsQuery("//div[@id='ad-srp']//li//h3/a[not(child::img)]", "//div[@id='ad-srp']//li//div[(@class='res')]/span[(@class='url')]");
                    }
                    //Fix for Incident:2173804 -Sponsored links not annotated in directory search
                    else if (window.location.href.indexOf("search/dir") != -1)
                    {
                        // Search links
                        Utils.execSearchQuery("//div[contains(@id,'web')]//a[contains(@class,'ttl')]");
                        // Top/Bottom sponsor links
                        gbSponsLink = Utils.execTopBtmSponsQuery("//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li/div[not(@class='abst')]/a[1 and not(@class) and not(child::img)]",
                                                                  "//div[contains(@class,'spns') or contains(@class,'ads horiz')]//li//em[1 and not(parent::a)]");
                    }
                    else 
                    {
                        // Search links
                        Utils.execSearchQuery("//div[contains(@id,'web')]//a[contains(@class,'ttl')]");
                        // Top/Bottom sponser links[Fix for Incident:2118988:Sponsored results at the bottom are not annotated for au.search.yahoo.com]
                        gbSponsLink = Utils.execTopBtmSponsQuery("//ul[contains(@class,'spns') or contains(@class,'ads horiz') or contains(@class,'eads')]/li/div[contains(@class,'ad-ttl') or contains(@class,'vert-ad-ttl')]/a[not(child::img)]",
																 "//ul[contains(@class,'spns') or contains(@class,'ads horiz') or contains(@class,'eads')]//li/em[1 and not(parent::a)]");
                    }
                    //Right Sponsor Results (this is found to be common for all regional sites)
                    //argument 1 - Anchor Element expression
                    //argument 2 - Span Text expression / equivalent to get the static link text
                    //Purpose of using Argument 2 is hyperlink doesn't point to the correct url
                    if(lbExecute)
                    {
                        Utils.execRightSponsQuery("//div[@id='east']/ul[starts-with(@class,'ead')]//li/a", "//div[@id='east']/ul[starts-with(@class,'ead')]//li/em");
                        //For "yahoo.co.in" glue page's Sponsor Link
                        if(window.location.href.indexOf("http://in.search.yahoo.com") != -1)
                        {
                             Utils.execRightSponsQuery("//div[@class='mod glue-spl']//li[not (@class='yschprom')]//a[(not(@class) and not(child::img))]", "//div[@class='mod glue-spl']//li[not (@class='yschprom')]//em[1]");
                        }
                    }
                    //News results  
                    Utils.execSearchQuery("//div[starts-with(@class,'res sc')]//tr/td[@class='news-r']//li/a[not(child::img)]");
                    //Sub links of news result
                    Utils.execSearchQuery("//div[starts-with(@class,'res sc')]//tr/td//li/a[not(child::img) and (@class='spt')]");       
                    //Shopping Results
                    Utils.execSearchQuery("//div[@class='shpnr']//*[contains(@class,'ttl')]");
                    //Promotional Results[Fix for Incident:2118988:Sponsored results at the bottom are not annotated for au.search.yahoo.com]
                    Utils.execTopBtmSponsQuery("//div[@class='abst']//h3//a[(not(@class) and not(child::img))]", "//div[@class='abst']//em[1 and not(parent::a)]");
                    //Travel/Image/MovieOldStyle Results displayed before Web Results - e.g in.yahoo.com - 'sachin', 'laptop', yahoo.com - 'happy endings'
                    Utils.execSearchQuery("//div[starts-with(@class,'res sc') and (following::div[contains(@id,'web')])]//a[contains(@class,'yschttl')]");             
                    //Stock Results
                    Utils.execSearchQuery("//div[starts-with(@class,'res sc')]/h4/a[(not(@class) or (@class='spt')) and not(child::img)]");
                    //Latest News results [Fix for Incident no. :2103844-Annotation for news results]
                    Utils.execSearchQuery("//div[contains(@class,'navset')]//div[contains(@class,'cnt')]//li[not(@class)]/a[not(child::img)]");
                    //Clues
                    Utils.execSearchQuery("//div[contains(@class,'sc-clues')]//a[contains(@class,'ttl')and not(child::img)]");
                    //Quick Prompts
                    Utils.execSearchQuery("//div[@id='main']//ol[@id='quickapp-prompt']//li//a[contains(@class,'ttl')and not(child::img)]");
                    //MovieNewStyle, album section - e.g: yahoo.com - 'Cars 2' 
                    Utils.execSearchQuery("//div[contains(@class,'tabview-content')]//li//div[contains(@class,'accrdn-panel')]//div[@class='wt-bd']/h3/a[not(child::img)]");
                    //AlbumNewStyle section - e.g: yahoo.com - 'Happy End' 
                    Utils.execSearchQuery("//div[contains(@class,'tabview-content')]//li//div[contains(@class,'accrdn-panel')]//li/h3/a[not(child::img)]");
                };
                //Return matching node to get its innertext(implemented for redirect links)
                getMatchNode = function(sNodeName, sClassName, lnkNode)
                {
                    if(lnkNode && lnkNode.parentNode && lnkNode.parentNode.parentNode && lnkNode.parentNode.parentNode.parentNode)
                    {
                        var prntSrchNode = lnkNode.parentNode.parentNode.parentNode;
                        var arrNodeColl = prntSrchNode.getElementsByTagName(sNodeName);
                        var liNodeLen = arrNodeColl.length;
                        if(liNodeLen)
                        {
                            for(var liIdx=0; liIdx<liNodeLen; liIdx++)
                            {
                               if(arrNodeColl[liIdx].className == sClassName)
                               {
                                   return arrNodeColl[liIdx];
                               }
                            }
                        } 
                    }
                    return null;
                };
                //Get the exact link
                getLink = function(surl, linkNode)
                {
                    var lsarrSrchPattern = ["/**", "/*-"];
                    var liSearchIdx;
                    var lsOriUrl;

                    //note: these following non-baseline advance char as per UNICODE spec
                    //      can appear without any UI presence and can become encoded and cause errors.
                    //      Need to filter out. Incident:
                    var lsUnEscUrl = surl.replace(/\u200B|\u2060/g, '');				    
                    //decode the url
                    lsUnEscUrl = unescape(lsUnEscUrl);
                    //remove blank space
                    var lsFormatUrl =  Utils.getFormatLink(lsUnEscUrl);
                    //original URL follows "/**" or "/*" in href for most of the regional sites
                    //except "yahoo.com"(search url has redirects)
                    //check url text with search strings provided in array to extract the original url
                    for(var liIndex=0; liIndex<lsarrSrchPattern.length; liIndex++)
                    {
                        if((liSearchIdx = lsFormatUrl.lastIndexOf(lsarrSrchPattern[liIndex])) != -1)
                        {
                            break;
                        } 
                    }
                    //match found
                    if(liSearchIdx != -1)
                        lsOriUrl = lsFormatUrl.slice(liSearchIdx+lsarrSrchPattern[liIndex].length);
                    //no match
                    else
                        lsOriUrl = lsFormatUrl;
                        
                     //in few cases redirect url is found followed by 'RU=' in href
                    if (lsOriUrl.match(/\.yahoo\.com/) && lsOriUrl.match(/RU=/))
                    {
                        //get <span class='url'> innertext for redirects
                        var matchNode = getMatchNode('SPAN', 'url', linkNode);
                        //<span class='url'> found(only for US and Canada site)
                        if(matchNode)
                        {
                            var lsUnEscUrl = unescape(matchNode.innerText||matchNode.textContent);
                            //remove blank space
                            var lsFormatUrl =  Utils.getFormatLink(lsUnEscUrl);
                            lsOriUrl = lsFormatUrl;
                        }                    
                        //if not found get the url followed by 'click'
                        else
                        {
                            lsOriUrl = lsOriUrl.slice(lsOriUrl.lastIndexOf("click?u=")+8);
                        }
                    }
                    return encodeURI(lsOriUrl);
                };

                if(typeof Utils != "undefined")
                {
                    executeXPathQuery();
                    //Get collection of text links
                    var lsarrLinkText = new Array();
                    lsarrLinkText = Utils.getSearchText();
                    if(lsarrLinkText.length <= 0)
                    {
                       return false;
                    }
                    //Get collection of anchor nodes
                    garrNodeColl = Utils.getSearchNodes();
                    for(var iLinkIdx = 0; iLinkIdx<lsarrLinkText.length; iLinkIdx++)
                    {
                        var lsFormatLink;
                        var response;
                        lsFormatLink = getLink(lsarrLinkText[iLinkIdx], garrNodeColl[iLinkIdx]);
                        var liUrlIndex = Shasta.addURL(lsFormatLink);
                    }
                    
                } //end of if utils
    
                return true;
            },
			
			createAnnotation : function()		
			{
				//Add the unknown annotation by default against search links
				addAnnotation = function(anchorElement, response)
				{
					var lbSponsorLinkEm = false;
					//Get the parent node of anchor element
					var prntNode = anchorElement.parentNode;
					//Get the next sibling
					var startNode = anchorElement.nextSibling;
					var lbAppendChild = false;

					if (!prntNode)
						return false; //anchorelement is getting updated, can happen in ajax - when refine searches(left side sections) are clicked(Incident:  2329965)

					//Apply inline & float to none to override any values we might inherit
					//Was needed for trending search incident: 1990893
					response.style.cssFloat = response.style.styleFloat = "none";
					response.style.display = "inline";
					
					//For korean search page, annotation is displayed in line with the link if
					//"P" tag is parent. Set the "top" position to "0px" for other elements  
					if(gbKoreanSrchPage)
					{
						if(prntNode.nodeName.toLowerCase() != "p")
							response.style.top = "0px";
					}  
					//Cancel the event bubbling for "onclick" event for hongkong top sponsor results 
					if(gbHongkongSrchPage && (lsarrFlag[i].toLowerCase() == "topbottom"))
					{
						var spanTag = document.createElement('span');
						spanTag.style.display = "inline";
						anchorElement.style.display = "inline";
						spanTag.onclick = cancelEventHandler;
						var appendedElement = spanTag.appendChild(response);

						var brTag = document.createElement('br');
						spanTag.appendChild(brTag);

						response = spanTag;
					}
					//Anchor element doesn't have next sibling
					if(!startNode)
					{
						lbAppendChild = true;
					}           
					//Append the annotation to the Parent element
					if(lbAppendChild)
					{               
						 //For "Hongkong" site we get enlarged annotation if the sponsor link 
						 //has image. Hardcoded the annotation image size and applied margin left to line 
						 //up with previous element
						 if(gbHongkongSrchPage && (lsarrFlag[i].toLowerCase() == "right"))
						 {   
							  //IE
							  if (anchorElement.currentStyle)
								 response.style.marginLeft = anchorElement.currentStyle.marginLeft;
							  //FF
							  else if(window.getComputedStyle)
							  {
								var comStyle = window.getComputedStyle(anchorElement,null); 
								if(comStyle)
									response.style.marginLeft = comStyle.getPropertyValue("margin-left");
							  }
						 }
						 prntNode.appendChild(document.createTextNode(" "));
						 prntNode.appendChild(response);
					}
					//Insert the annotation before anchor's next sibling
					else
					{
						//Check for Sponsor link with "em" tag as next node(e.g. yahoo.in search)
					   if(lsarrFlag[i].toLowerCase() != "normal" &&  startNode && (startNode.nodeName.toLowerCase() == "em"))
					   {
						   lbSponsorLinkEm = true;
					   }
					   //Apply "display:inline" style for <A> to get annotation at the end of sponsor link
					   //If anchor's next sibling is "em" in top sponsor or if it's a right sponsor
					   if(lbSponsorLinkEm || (lsarrFlag[i].toLowerCase() == "right"))
					   {
							anchorElement.style.display = "inline";
					   }
					   prntNode.insertBefore(document.createTextNode(" "), startNode);
					   prntNode.insertBefore(response, startNode);
					   //As safe web rating icon "display" style is "inline", search content in 
					   //second line(has "em" tag) will get appended with sponsor result link.
					   //insert "br" tag to move the search content to next line
					   if(lbSponsorLinkEm)
					   {
							var brTag = document.createElement("br");
							prntNode.insertBefore(brTag, startNode);  
							gbAlign = true;
							//store Parent element in a separate array
							larrSponsNode[spIdx++] = prntNode;
					   }
					}
					return true;
				};		
				//detect for SA image inserted
				detectSA = function()
				{
					var lbEnabled = Utils.IsSAEnabled();
					if(lbEnabled)
					{ 
						for(var idx = 0;idx<larrSponsNode.length; idx++)
						{
							var liNSWPos = 0;
							var liSAPos = 0;
							var lbNSWStyleChange = false;
							var prntNode = larrSponsNode[idx].parentNode;//anchor element parent
							var imgs = prntNode.getElementsByTagName('img');
							for(var liIndex = 0; liIndex < imgs.length; liIndex++)
							{
								if(imgs[liIndex].src.indexOf(Shasta.getResProtocol()) != -1) 
								{
									liNSWPos = liIndex;
								}
								//Check for sa icon
								if(imgs[liIndex].src.match(lsSAProtocol)) 
								{
									liSAPos = liIndex;
									lbSAImg = true;
								}    
							}
							//sa icon found
							if(lbSAImg)
							{
								//change sa style if sa is displayed next to link
								if(liSAPos < liNSWPos)
								{
									imgs[liSAPos].style.cssFloat = imgs[liSAPos].style.styleFloat = "left";
									imgs[liNSWPos].style.left = "5px";//to give some space btw icons
								}
								else
								{  
									//check whether to change style or not
									saParent = imgs[liSAPos].parentNode; //SA parent element(anchor)
									saNextNode = saParent.nextSibling;
									//check whether sa is next to safe web
									while(saNextNode != null)
									{
										if(saNextNode.nodeName.toLowerCase() == "em")
										{
											lbNSWStyleChange = true;
											break;
										}
										saNextNode = saNextNode.nextSibling;
									}  
									//if sa is next to safe web, change all previous element style
									//till "em" or "br"
									if(lbNSWStyleChange)
									{  
										var liChildLen = larrSponsNode[idx].childNodes.length;
										var childNodes = larrSponsNode[idx].childNodes;
										for(liStartIdx = 0; liStartIdx < liChildLen; liStartIdx++)
										{
											var child = childNodes[liStartIdx];
											if(child.nodeName.toLowerCase() == "br" || child.nodeName.toLowerCase() == "em")
											{
												break;
											}
											if(child.nodeType != 3)
											{
												child.style.cssFloat = child.style.styleFloat = "left";
											}
										}  
									}
								}//end of else
							}//end of lbSAImg
						}//end of for
					}//end of lbEnabled
					//SA icon is present or SA not enabled, cancel the setInterval
					 if(lbSAImg || (!lbEnabled && (++liDelayCnt > liSADetectCnt)))
					 {
						clearInterval(intval);
					 }
				};//end of detectSA     
				
				if(typeof Utils != "undefined")
				{
					if(garrNodeColl.length <= 0)
					{
						return false;
					}
					var lsarrFlag = new Array();	
					var larrSponsNode = new Array(); 
					var spIdx = 0;
					//Get Sponsor Flags
					lsarrFlag = Utils.getSearchFlags();          
					for(var i = 0;i<garrNodeColl.length;i++)
					{
						var response;
						//Create the image element applying styles
						response = Utils.createImage(i);
						//Add Annotation
						if (!addAnnotation(garrNodeColl[i], response))
						{
							return false;
						}
					}

					//detect for SA image inserted if there is an alignment issue
					//with safe web icon in Sponsor results
					if(gbAlign)
					{
						var liDelayCnt = 0;
						var lbSAImg = false;   
						var liSADetectInt = Utils.getSADetectInterval();
						var liSADetectCnt = Utils.getSADetectCnt();
						Utils.ResetSAEnabled();
						var lsSAProtocol = Utils.getSAProtocol();
						var intval = setInterval(detectSA, liSADetectInt);         
					}
					
				}//end of if utils
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
