function initClearlyComponent__highlight(_paramInstance){if(_paramInstance){}else{return false;}
var $H=_paramInstance;switch(true)
{case(!($H.settings)):case(!($H.settings.path)):case(!($H.window)):case(!($H.window.document)):case(!($H.window.document.body)):case(!($H.jQuery)):if($H.debug)
{console.log(!($H.settings));console.log(!($H.settings.path));console.log(!($H.window));console.log(!($H.window.document));console.log(!($H.window.document.body));console.log(!($H.jQuery));}
return false;}
$H.document=$H.window.document;var _default=function(_setting,_default_value){if($H.settings[_setting]){}else{$H.settings[_setting]=_default_value;}};_default('elementWhichMustContainAllHighlights',$H.document.body);_default('elementsToAttachMouseHandlersTo',[$H.document.body]);_default('onInsertCSSUseThisId','clearly_highlighting_css');_default('onInsertCSSImagesUseThisId','clearly_highlighting_css_images');_default('highlightingEnabledCSSClass','clearly_highlighting_enabled');_default('highlightElementIdAttribute','clearly_highlight_id');_default('highlightElementCSSClass','clearly_highlight_element');_default('highlightElementFirstCSSClass','clearly_highlight_first');_default('highlightElementLastCSSClass','clearly_highlight_last');_default('highlightElementDeleteCSSClass','clearly_highlight_delete_element');_default('highlightElementDeleteIdPrefix','clearly_highlight_delete__');_default('highlightCleanHTMLElementStart','<span style="-evernote-highlighted:true; background-color:#f6ee96">');_default('highlightCleanHTMLElementEnd','</span>');_default('cssPath',$H.settings.path+'css/');_default('cssImagesFile',$H.settings.cssPath+'images.css');var $=$H.jQuery;$H.$window=$($H.window);$H.$document=$($H.document);$H.$html=$H.$document.find('html');$H.$elementWhichMustContainAllHighlights=$($H.settings.elementWhichMustContainAllHighlights);$H.enabled=false;$H.parseOptions={'_elements_ignore':'|button|input|select|textarea|optgroup|command|datalist|--|frame|frameset|noframes|--|style|link|script|noscript|--|canvas|applet|map|--|marquee|area|base|','_elements_ignore_tag':'|form|fieldset|details|dir|--|center|font|span|','_elements_container':'|body|--|article|section|--|div|--|td|--|li|--|dd|dt|','_elements_self_closing':'|br|hr|--|img|--|col|--|source|--|embed|param|--|iframe|','_elements_highlight_protect':'|video|audio|source|--|object|param|embed|','_elements_keep_attributes':{'a':['href','title','name'],'img':['src','width','height','alt','title'],'video':['src','width','height','poster','audio','preload','autoplay','loop','controls'],'audio':['src','preload','autoplay','loop','controls'],'source':['src','type'],'object':['data','type','width','height','classid','codebase','codetype'],'param':['name','value'],'embed':['src','type','width','height','flashvars','allowscriptaccess','allowfullscreen','bgcolor'],'iframe':['src','width','height','frameborder','scrolling'],'td':['colspan','rowspan'],'th':['colspan','rowspan']}};$H.debug=($H.debug||false);if($H.debug)
{switch(true)
{case(!(!($H.window.console&&$H.window.console.log))):$H.logOneline=function(msg){$H.window.console.log(msg);};break;case(!(!($H.window.opera&&$H.window.opera.postError))):$H.logOneline=function(msg){$H.window.opera.postError(msg);};break;default:$H.logOneline=function(msg){};break;}
$H.log=function()
{if($H.debug){}else{return;}
for(var i=0,il=arguments.length;i<il;i++){$H.logOneline(arguments[i]);}
$H.logOneline('-----------------------------------------');};}
else
{$H.logOneline=function(){return false;};$H.log=function(){return false;};}
$H.escape_html=function(_string)
{var _replace={"&":"amp",'"':"quot","<":"lt",">":"gt"};return((_string&&_string.replace)?_string.replace(/[&"<>]/g,function(_match){return("&"+_replace[_match]+";");}):'');};$H.rand=function(_min,_max)
{return(Math.floor(Math.random()*(_max-_min+1))+_min);};$H.insertCSS=function()
{$H.$document.find('head').append(''+'<link'+' id="'+$H.escape_html($H.settings.onInsertCSSUseThisId)+'"'+' href="'+$H.escape_html($H.settings.cssPath+'style.css')+'"'+' rel="stylesheet"'+' type="text/css" />'+'');$H.$document.find('head').append(''+'<link'+' id="'+$H.escape_html($H.settings.onInsertCSSImagesUseThisId)+'"'+' href="'+$H.escape_html($H.settings.cssImagesFile)+'"'+' rel="stylesheet"'+' type="text/css" />'+'');};$H.sel={};$H.sel.getWindowFromDocument=function(theDocument)
{if(theDocument){}else{return null;}
if('defaultView'in theDocument){arguments.calee=function(theDocument){if(theDocument){}else{return null;}
return theDocument.defaultView;};}
else if('parentWindow'in theDocument){arguments.calee=function(theDocument){if(theDocument){}else{return null;}
return theDocument.parentWindow;};}
else{arguments.calee=function(theDocument){return null;};}
return arguments.calee(theDocument);};$H.sel.getSelection=function(theWindow)
{if(theWindow){}else{return null;}
if('getSelection'in theWindow){arguments.calee=function(theWindow){if(theWindow){}else{return null;}
return theWindow.getSelection();};}
else if('selection'in theWindow.document){arguments.calee=function(theWindow){if(theWindow){}else{return null;}
return theWindow.document.selection;};}
else{arguments.calee=function(theWindow){return null;};}
return arguments.calee(theWindow);};$H.sel.getRange=function(selection)
{if(selection){}else{return null;}
if('getRangeAt'in selection){arguments.calee=function(selection){if(selection){}else{return null;}
if(selection.rangeCount>0){return selection.getRangeAt(0);}
else{return null;}};}
else if('createRange'in selection){arguments.calee=function(selection){if(selection){}else{return null;}
return selection.createRange();};}
else{arguments.calee=function(selection){return null;};}
return arguments.calee(selection);};$H.sel.getRangeHTML=function(range)
{if(range){}else{return null;}
if('htmlText'in range){arguments.calee=function(range){if(range){}else{return null;}
return range.htmlText;};}
else if('surroundContents'in range){arguments.calee=function(range){if(range){}else{return null;}
if(range.commonAncestorContainer&&range.commonAncestorContainer.ownerDocument){}else{return null;}
var dummy=range.commonAncestorContainer.ownerDocument.createElement("div");dummy.appendChild(range.cloneContents());return dummy.innerHTML;};}
else{arguments.calee=function(range){return null;};}
return arguments.calee(range);};$H.sel.getRangeText=function(range)
{if(range){}else{return null;}
if('text'in range){arguments.calee=function(range){if(range){}else{return null;}
return range.text;};}
else if('surroundContents'in range){arguments.calee=function(range){if(range){}else{return null;}
if(range.commonAncestorContainer&&range.commonAncestorContainer.ownerDocument){}else{return null;}
var dummy=range.commonAncestorContainer.ownerDocument.createElement("div");dummy.appendChild(range.cloneContents());return dummy.textContent;};}
else{arguments.calee=function(range){return null;};}
return arguments.calee(range);};$H.highlight__deleteSpansFromParents=function(_parents)
{var _done=[],_this_done=false,_inner='';for(var i=0,_i=_parents.length;i<_i;i++)
{_this_done=false;for(var ii=0,_ii=_done.length;ii<_ii;ii++)
{if(_done[ii]==_parents[i])
{_this_done=true;break;}}
if(_this_done){continue;}
_done.push(_parents[i]);_inner=_parents[i].innerHTML;if(_inner.indexOf('<span')>-1){}else{continue;}
_inner=_inner.replace(/<span([^>]*?)>/gi,'');_inner=_inner.replace(/<\/span>/gi,'');_parents[i].innerHTML=_inner;}};$H.highlight__getDeepestTextNode=function(_node)
{var _n=_node;while(true)
{switch(true)
{case(_n.nodeType&&_n.nodeType==3):return _n;case(_n.nodeType&&_n.nodeType==1&&_n.childNodes.length>0):_n=_n.childNodes[0];break;case(_n.nodeType&&_n.nodeType==1&&_n.childNodes.length==0&&_n.nextSibling):_n=_n.nextSibling;break;default:return _node;}}
return _node;};$H.highlight__getCommonAncestorContainerForNodes=function(_node1,_node2,_fallback)
{var _parent1=_node1,_parent2=_node2;while(true)
{_parent1=_parent1.parentNode;_parent2=_parent2.parentNode;switch(true)
{case(!(_parent1)):case(!(_parent2)):case(_parent1==_fallback):case(_parent2==_fallback):return _fallback;}
switch(true)
{case(_parent1==_parent2):return _parent1;case($.contains(_parent1,_node2)):return _parent1;case($.contains(_parent2,_node1)):return _parent2;case($.contains(_parent1,_parent2)):return _parent1;case($.contains(_parent2,_parent1)):return _parent2;}}
return _fallback;};$H.highlight__getParentElementOfNode=function(_thisNode)
{var _element=_thisNode;while(true){if(_element.nodeType==1){break;}
_element=_element.parentNode;}
return _element;};$H.highlight__getParentElementOfNodeWithThisParent=function(_thisNode,_thisParent)
{switch(true)
{case(_thisNode==_thisParent):return _thisNode;case(!($.contains(_thisParent,_thisNode))):return _thisNode;}
var _element=_thisNode;while(true){if(_element.parentNode==_thisParent){break;}
_element=_element.parentNode;}
return _element;};$H.highlight__buildHTMLForElementWithSelectedRange=function(_elementToBuildHTMLFor,_modeToBuildHTMLIn,_rangeToBuildHTMLWith)
{var _global__element_index=0,_global__the_html='',_global__highlight_on=((_modeToBuildHTMLIn=='boundry-end')?true:false);var _recursive=function(_node)
{_global__element_index++;var _explored=false,_tag_name=(_node.nodeType===3?'#text':((_node.nodeType===1&&_node.tagName&&_node.tagName>'')?_node.tagName.toLowerCase():'#invalid')),_tag_is_ignored=($H.parseOptions._elements_ignore_tag.indexOf('|'+_tag_name+'|')>-1),_tag_is_ignored=(_tag_is_ignored?((_tag_name=='span')?false:true):false),_pos__start__before=0,_pos__start__after=0,_pos__end__before=0,_pos__end__after=0,_to_write='',_selection_starts_here=false,_selection_ends_here=false;switch(true)
{case((_tag_name=='#invalid')):case(($H.parseOptions._elements_ignore.indexOf('|'+_tag_name+'|')>-1)):return;case(_tag_name=='#text'):_to_write=_node.nodeValue.replace(/</gi,'&lt;').replace(/>/gi,'&gt;');switch(true)
{case(_modeToBuildHTMLIn=='nothing'):break;case(_modeToBuildHTMLIn=='everything'):_to_write='<highlight>'+_to_write+'</highlight>';break;case(_modeToBuildHTMLIn=='boundry-start'):case(_modeToBuildHTMLIn=='boundry-end'):case(_modeToBuildHTMLIn=='boundry-both'):if(_node==_rangeToBuildHTMLWith.endContainer)
{_to_write=''+'<highlight>'+
_to_write.substr(0,_rangeToBuildHTMLWith.endOffset)+'</highlight>'+
_to_write.substr(_rangeToBuildHTMLWith.endOffset)+'';_global__highlight_on=false;_selection_ends_here=true;}
if(_node==_rangeToBuildHTMLWith.startContainer)
{_to_write=''+
_to_write.substr(0,_rangeToBuildHTMLWith.startOffset)+'<highlight>'+
_to_write.substr(_rangeToBuildHTMLWith.startOffset)+'</highlight>'+'';_global__highlight_on=true;_selection_starts_here=true;}
if(_selection_starts_here&&_selection_ends_here)
{_to_write=_node.nodeValue.replace(/</gi,'&lt;').replace(/>/gi,'&gt;');_to_write=''+
_to_write.substr(0,_rangeToBuildHTMLWith.startOffset)+'<highlight>'+
_to_write.substr(_rangeToBuildHTMLWith.startOffset,(_rangeToBuildHTMLWith.endOffset-_rangeToBuildHTMLWith.startOffset))+'</highlight>'+
_to_write.substr(_rangeToBuildHTMLWith.endOffset)+'';_global__highlight_on=false;}
if(_selection_starts_here&&(_rangeToBuildHTMLWith.startOffset>0))
{_to_write=_to_write.replace(/([ .,;?!])([a-z0-9]{1,2})<highlight>/gi,'$1<highlight>$2');_to_write=_to_write.replace(/<highlight>([\s])([^\s])/gi,'$1<highlight>$2');_to_write=_to_write.replace(/<highlight>([a-z0-9])([ ])([a-z0-9])/gi,'$1$2<highlight>$3');}
if(_selection_ends_here&&(_rangeToBuildHTMLWith.endOffset>0))
{var _do_end=true;if(_rangeToBuildHTMLWith.endContainer&&_rangeToBuildHTMLWith.endContainer.nodeValue&&_rangeToBuildHTMLWith.endContainer.nodeValue.length)
{_do_end=(_rangeToBuildHTMLWith.endOffset<_rangeToBuildHTMLWith.endContainer.nodeValue.length);}
if(_do_end)
{_to_write=_to_write.replace(/<\/highlight>([a-z0-9]{0,2})([ .,;?!])/gi,'$1$2</highlight>');_to_write=_to_write.replace(/([^\s])([\s])<\/highlight>/gi,'$1</highlight>$2');_to_write=_to_write.replace(/([ ])([a-z0-9])<\/highlight>([a-z0-9])/gi,'</highlight>$1$2$3');}}
if(!(_selection_starts_here)&&!(_selection_ends_here))
{_to_write=_node.nodeValue.replace(/</gi,'&lt;').replace(/>/gi,'&gt;');if(_global__highlight_on){_to_write='<highlight>'+_to_write+'</highlight>';}}
break;}
_global__the_html+=_to_write;return;}
if((_rangeToBuildHTMLWith.endContainer.nodeType==1)&&(_node==_rangeToBuildHTMLWith.endContainer)){_global__highlight_on=false;_selection_ends_here=true;}
if((_rangeToBuildHTMLWith.startContainer.nodeType==1)&&(_node==_rangeToBuildHTMLWith.startContainer)){_global__highlight_on=true;_selection_starts_here=true;}
if(_selection_starts_here&&_selection_ends_here){_global__highlight_on=false;}
if(_tag_is_ignored){}else
{_pos__start__before=_global__the_html.length;_global__the_html+='<'+_tag_name;if(_tag_name in $H.parseOptions._elements_keep_attributes)
{for(var i=0,_i=$H.parseOptions._elements_keep_attributes[_tag_name].length;i<_i;i++)
{var _attribute_name=$H.parseOptions._elements_keep_attributes[_tag_name][i],_attribute_value=_node.getAttribute(_attribute_name);if(_attribute_value>'')
{_global__the_html+=' '+_attribute_name+'="'+(_attribute_value)+'"';}}}
var _id_attribute=_node.getAttribute('id');if(_id_attribute>'')
{_global__the_html+=' id="'+_id_attribute+'"';}
if(_tag_name=='a')
{_global__the_html+=' target="_blank"';}
var _class_attribute=_node.getAttribute('class');if(_class_attribute>'')
{_global__the_html+=' class="'+_class_attribute+'"';}
if(_tag_name=='em'&&_modeToBuildHTMLIn!='everything')
{switch(true)
{case(_global__highlight_on):case((_rangeToBuildHTMLWith.startOffset==0)&&(_node.firstChild)&&(_node.firstChild==_rangeToBuildHTMLWith.startContainer)):break;default:var _highlight_id_attribute=_node.getAttribute($H.settings.highlightElementIdAttribute);if(_highlight_id_attribute>'')
{_global__the_html+=' '+$H.settings.highlightElementIdAttribute+'="'+_highlight_id_attribute+'"';}
break;}}
if($H.parseOptions._elements_self_closing.indexOf('|'+_tag_name+'|')>-1){_global__the_html+=' />';}
else{_global__the_html+='>';}
_pos__start__after=_global__the_html.length;}
if($H.parseOptions._elements_self_closing.indexOf('|'+_tag_name+'|')>-1){}else
{for(var i=0,_i=_node.childNodes.length;i<_i;i++)
{_recursive(_node.childNodes[i]);}}
switch(true)
{case(_tag_is_ignored):return;case(($H.parseOptions._elements_self_closing.indexOf('|'+_tag_name+'|')>-1)):_pos__end__before=_global__the_html.length;_pos__end__after=_global__the_html.length;break;default:_pos__end__before=_global__the_html.length;_global__the_html+='</'+_tag_name+'>';_pos__end__after=_global__the_html.length;break;}
switch(true)
{case(($H.parseOptions._elements_highlight_protect.indexOf('|'+_tag_name+'|')>-1)):case((_tag_name=='em')&&$(_node).hasClass($H.settings.highlightElementCSSClass)):_global__the_html=''+
_global__the_html.substr(0,_pos__start__after)+
_global__the_html.substr(_pos__start__after,(_pos__end__before-_pos__start__after)).replace(/<highlight>/gi,'').replace(/<\/highlight>/gi,'')+
_global__the_html.substr(_pos__end__before)+'';break;case((_tag_name=='a')&&(_node.className=='deleteHighlight')):_global__the_html=_global__the_html.substr(0,_pos__start__before)+_global__the_html.substr(_pos__end__after);break;}
return;};_recursive(_elementToBuildHTMLFor);_global__the_html=_global__the_html.replace(/<highlight>/gi,'<em class="'+$H.settings.highlightElementCSSClass+'">').replace(/<\/highlight>/gi,'</em>');return _global__the_html;};$H.highlight__doRange=function(_rangeToHighlight)
{var _commonAncestorElement=$H.highlight__getParentElementOfNode(_rangeToHighlight.commonAncestorContainer),_startElement=$H.highlight__getParentElementOfNodeWithThisParent(_rangeToHighlight.startContainer,_commonAncestorElement),_endElement=$H.highlight__getParentElementOfNodeWithThisParent(_rangeToHighlight.endContainer,_commonAncestorElement);if((_commonAncestorElement.tagName)&&!($.contains($H.settings.elementWhichMustContainAllHighlights,_commonAncestorElement))){return false;}
if($H.callbacks&&$H.callbacks.arbitraryRangeExclusion){if($H.callbacks.arbitraryRangeExclusion(_rangeToHighlight,_commonAncestorElement,_startElement,_endElement)===false){return false;}}
var _selection_id=$H.rand(1,1000);while(true)
{if($H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass+'['+$H.settings.highlightElementIdAttribute+'="'+_selection_id+'"]').length>0){}else{break;}
_selection_id=$H.rand(1,1000);}
var _chaingingElements=[],_currElement=_startElement,_currChainging=false;while(true)
{_currChainging={'_element':_currElement,'_tagName':(_currElement.nodeType===3?'#text':((_currElement.nodeType===1&&_currElement.tagName&&_currElement.tagName>'')?_currElement.tagName.toLowerCase():'#invalid'))};_chaingingElements.push(_currChainging);if(_currElement==_endElement){break;}
_currElement=_currElement.nextSibling;if(_currElement){}else{break;}}
var _parents_to_clean=[];for(var i=0,_i=_chaingingElements.length,_currElement=false;i<_i;i++)
{var _currElement=_chaingingElements[i],_currNode=_currElement._element,_currTag=_currElement._tagName,_boundryMode='',_currBuiltHTML=false,_resNode=false;switch(true)
{case((_i==1)&&(i==0)):_boundryMode='boundry-both';break;case((_i>1)&&(i==0)):_boundryMode='boundry-start';break;case((_i>1)&&(i==(_i-1))):_boundryMode='boundry-end';break;default:_boundryMode='everything';break;}
_currBuiltHTML=$H.highlight__buildHTMLForElementWithSelectedRange(_currNode,_boundryMode,_rangeToHighlight);switch(true)
{case((_currTag=='#text')):var _newElement=$H.document.createElement('span');_newElement.innerHTML=_currBuiltHTML;_resNode=_newElement;_currNode.parentNode.replaceChild(_resNode,_currNode);break;case(($H.parseOptions._elements_self_closing.indexOf('|'+_currTag+'|')>-1)):_resNode=_currNode;break;default:_resNode=_currNode;_currBuiltHTML=_currBuiltHTML.substr((_currBuiltHTML.indexOf('>')+1));_currBuiltHTML=_currBuiltHTML.substr(0,_currBuiltHTML.lastIndexOf('<'));if(_currBuiltHTML.indexOf('<em class="'+$H.settings.highlightElementCSSClass+'">')>-1){}else{break;}
_currNode.innerHTML=_currBuiltHTML;break;}
$(_resNode).find('em.'+$H.settings.highlightElementCSSClass+':not(['+$H.settings.highlightElementIdAttribute+'])').attr($H.settings.highlightElementIdAttribute,_selection_id);if((_currTag=='em')&&$(_resNode).hasClass($H.settings.highlightElementCSSClass))
{$(_resNode).attr($H.settings.highlightElementIdAttribute,_selection_id);}
_parents_to_clean.push(_resNode.parentNode);}
$H.highlight__deleteSpansFromParents(_parents_to_clean);return true;};$H.highlight__doCurentSelection=function()
{var _selection=$H.sel.getSelection($H.window),_range=$H.sel.getRange(_selection),_text=$H.sel.getRangeText(_range),_good_range=(_range?{'commonAncestorContainer':_range.commonAncestorContainer,'startContainer':_range.startContainer,'endContainer':_range.endContainer,'startOffset':_range.startOffset,'endOffset':_range.endOffset}:false);switch(true)
{case(!(_text)):case(!(_text.length>0)):case(!(_good_range)):return false;}
if(_good_range.startContainer.nodeType==1)
{if(_good_range.startContainer.childNodes[_good_range.startOffset])
{_good_range.startContainer=_good_range.startContainer.childNodes[_good_range.startOffset];_good_range.startOffset=0;}}
if(_good_range.endContainer.nodeType==1)
{if(_good_range.endContainer.childNodes[_good_range.endOffset])
{_good_range.endContainer=_good_range.endContainer.childNodes[_good_range.endOffset];_good_range.endOffset=0;}}
var _highlighted_range=$H.highlight__doRange(_good_range);if(_highlighted_range===false){return false;}
try{_selection.removeAllRanges();}catch(e){}
var _parents_double_to_clean=[];$H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass+' em.'+$H.settings.highlightElementCSSClass).each(function(_i,_e)
{$(_e).find('a.'+$H.settings.highlightElementDeleteCSSClass).remove();var _newElement=$H.document.createElement('span');_newElement.innerHTML=_e.innerHTML;_e.parentNode.replaceChild(_newElement,_e);_parents_double_to_clean.push(_newElement.parentNode);});$H.highlight__deleteSpansFromParents(_parents_double_to_clean);$H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass+' a.'+$H.settings.highlightElementDeleteCSSClass).remove();$H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass+'.'+$H.settings.highlightElementFirstCSSClass).removeClass($H.settings.highlightElementFirstCSSClass);$H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass+'.'+$H.settings.highlightElementLastCSSClass).removeClass($H.settings.highlightElementLastCSSClass);var _highlights_collection=$H.$elementWhichMustContainAllHighlights.find('em.'+$H.settings.highlightElementCSSClass),_highlights_collection_ids=[],_curr_delete_button=false;_highlights_collection.each(function(_i,_e){_highlights_collection_ids.push($(_e).attr($H.settings.highlightElementIdAttribute));});_highlights_collection.each(function(_i,_e)
{var _isFirst=(_highlights_collection_ids[(_i-1)]?(_highlights_collection_ids[_i]!=_highlights_collection_ids[(_i-1)]):true),_isLast=(_highlights_collection_ids[(_i+1)]?(_highlights_collection_ids[_i]!=_highlights_collection_ids[(_i+1)]):true);if(_isFirst)
{$(_e).addClass($H.settings.highlightElementFirstCSSClass);_curr_delete_button=$H.document.createElement('a');_curr_delete_button.className=$H.settings.highlightElementDeleteCSSClass;_curr_delete_button.id=$H.settings.highlightElementDeleteIdPrefix+_highlights_collection_ids[_i];_e.insertBefore(_curr_delete_button,_e.firstChild);}
if(_isLast)
{$(_e).addClass($H.settings.highlightElementLastCSSClass);}});return true;};$H.highlight__deleteAllHighlights=function()
{$H.highlight__deleteHighlight('all');};$H.highlight__deleteHighlight=function(_highlight_id)
{var _expression='em.'+$H.settings.highlightElementCSSClass+(_highlight_id=='all'?'':'['+$H.settings.highlightElementIdAttribute+'="'+_highlight_id+'"]'),_parents_to_clean=[];$H.$elementWhichMustContainAllHighlights.find(_expression).each(function(_index,_e)
{var _s=$H.document.createElement('span');_s.innerHTML=_e.innerHTML;_e.parentNode.replaceChild(_s,_e);_parents_to_clean.push(_s.parentNode);});$H.highlight__deleteSpansFromParents(_parents_to_clean);};$H.enable=function()
{if($H.enabled){return;}
$H.enabled=true;$H.$html.addClass($H.settings.highlightingEnabledCSSClass);};$H.disable=function()
{if($H.enabled){}else{return;}
$H.enabled=false;$H.$html.removeClass($H.settings.highlightingEnabledCSSClass);};$H.highlight__mouseUp_timeout=false;$H.highlight__deleteButton__byId__mouseEnter_timeout={};$H.highlight__deleteButton__byId__mouseLeave_timeout={};$H.highlight__mouseUp=function()
{if($H.enabled){}else{return;}
$H.highlight__mouseUp_timeout=$H.window.setTimeout(function()
{$H.highlight__mouseUp_timeout=false;var _didSelection=$H.highlight__doCurentSelection();if(_didSelection===false){}else{if($H.callbacks&&$H.callbacks.highlightAdded){$H.callbacks.highlightAdded();}}},250);};$H.highlight__mouseDown=function()
{if($H.enabled){}else{return;}
$H.window.clearTimeout($H.highlight__mouseUp_timeout);};$H.highlight__deleteButton__show=function(_highlight_id){$H.$elementWhichMustContainAllHighlights.find('#'+$H.settings.highlightElementDeleteIdPrefix+_highlight_id).fadeIn(250);};$H.highlight__deleteButton__hide=function(_highlight_id){$H.$elementWhichMustContainAllHighlights.find('#'+$H.settings.highlightElementDeleteIdPrefix+_highlight_id).fadeOut(250);};$H.addMouseHandlers=function()
{for(var i=0,_i=$H.settings.elementsToAttachMouseHandlersTo.length;i<_i;i++)
{$($H.settings.elementsToAttachMouseHandlersTo[i]).mouseup($H.highlight__mouseUp).mousedown($H.highlight__mouseDown);}
$H.$elementWhichMustContainAllHighlights.on('mouseenter','em.'+$H.settings.highlightElementCSSClass,function()
{var _highlight_id=$(this).attr($H.settings.highlightElementIdAttribute);$H.window.clearTimeout($H.highlight__deleteButton__byId__mouseLeave_timeout[_highlight_id]);$H.highlight__deleteButton__byId__mouseEnter_timeout[_highlight_id]=$H.window.setTimeout(function()
{$H.highlight__deleteButton__byId__mouseEnter_timeout[_highlight_id]=false;$H.highlight__deleteButton__show(_highlight_id);},250);});$H.$elementWhichMustContainAllHighlights.on('mouseleave','em.'+$H.settings.highlightElementCSSClass,function()
{var _highlight_id=$(this).attr($H.settings.highlightElementIdAttribute);$H.window.clearTimeout($H.highlight__deleteButton__byId__mouseEnter_timeout[_highlight_id]);$H.highlight__deleteButton__byId__mouseLeave_timeout[_highlight_id]=$H.window.setTimeout(function()
{$H.highlight__deleteButton__byId__mouseLeave_timeout[_highlight_id]=false;$H.highlight__deleteButton__hide(_highlight_id);},250);});$H.$elementWhichMustContainAllHighlights.on('click','em.'+$H.settings.highlightElementCSSClass+' a.'+$H.settings.highlightElementDeleteCSSClass,function()
{var _id=$(this.parentNode).attr($H.settings.highlightElementIdAttribute);$(this).remove();$H.highlight__deleteHighlight(_id);if($H.callbacks&&$H.callbacks.highlightDeleted){$H.callbacks.highlightDeleted();}});};$H.getCleanHTML=function(_rawHTML)
{var _html=_rawHTML;_html=_html.replace(/<span([^>]*?)>/gi,'');_html=_html.replace(/<\/span>/gi,'');var _highlight_delete_reg=new RegExp('<a ([^>]*?)'+$H.settings.highlightElementDeleteCSSClass+'([^>]*?)></a>','gi');_html=_html.replace(_highlight_delete_reg,'');var _highlight_element_reg=new RegExp('<em ([^>]*?)'+$H.settings.highlightElementCSSClass+'([^>]*?)>([^>]+?)</em>','gi');_html=_html.replace(_highlight_element_reg,'<highlight>$3</highlight>');var _two_highlights_reg=new RegExp('<highlight>([\\s\\S]*?)</highlight>([ \\n\\r\\t]*?)<highlight>([\\s\\S]*?)</highlight>','gi');while(true&&(_html.match(_two_highlights_reg)!=null)){_html=_html.replace(_two_highlights_reg,'<highlight>$1$3</highlight>');}
var _highlight_reg=new RegExp('<highlight>([\\s\\S]*?)</highlight>','gi');_html=_html.replace(_highlight_reg,$H.settings.highlightCleanHTMLElementStart+'$1'+$H.settings.highlightCleanHTMLElementEnd);return _html;};return $H;}