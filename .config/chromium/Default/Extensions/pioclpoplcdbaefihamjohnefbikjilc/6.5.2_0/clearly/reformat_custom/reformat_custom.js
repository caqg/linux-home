function initClearlyComponent__reformat_custom(_paramInstance){if(_paramInstance){}else{return false;}
var $RC=_paramInstance;switch(true)
{case(!($RC.settings)):case(!($RC.settings.path)):case(!($RC.window)):case(!($RC.window.document)):case(!($RC.window.document.body)):case(!($RC.jQuery)):if($RC.debug)
{console.log(!($RC.settings));console.log(!($RC.settings.path));console.log(!($RC.window));console.log(!($RC.window.document));console.log(!($RC.window.document.body));console.log(!($RC.jQuery));}
return false;}
$RC.document=$RC.window.document;var _default=function(_setting,_default_value){if($RC.settings[_setting]){}else{$RC.settings[_setting]=_default_value;}};_default('onCreateFrameUseThisId','clearly_frame_custom');_default('onCreateFrameUseThisBaseTimer',50);_default('onCreateFrameUseThisURLAsTheLocation','');_default('onCreateFrameDoNotInsertCSS',false);_default('onCreateFrameInjectThisHTMLAfter','');_default('onCreateFrameInjectThisHTMLBefore','');_default('onCreateFrameWaitForTheseWindowVars',[]);_default('createFrameInsideElementWithThisId','');_default('doDocumentWrite',function(_document,_html){_document.open();_document.write(_html);_document.close();});_default('imgPath',$RC.settings.path+'img/');_default('cssPath',$RC.settings.path+'css/');_default('cssImagesFile',$RC.settings.cssPath+'images.css');_default('cssFontsFile',$RC.settings.cssPath+'fonts.css');var $=$RC.jQuery;$RC.$window=$($RC.window);$RC.$document=$($RC.document);$RC.detected=false;$RC.checkedSections=false;$RC.uncheckedSections=false;$RC.debug=($RC.debug||false);$RC.debugRemembered={};if($RC.debug)
{switch(true)
{case(!(!($RC.window.console&&$RC.window.console.log))):$RC.logOneline=function(msg){$RC.window.console.log(msg);};break;case(!(!($RC.window.opera&&$RC.window.opera.postError))):$RC.logOneline=function(msg){$RC.window.opera.postError(msg);};break;default:$RC.logOneline=function(msg){};break;}
$RC.log=function()
{if($RC.debug){}else{return;}
for(var i=0,il=arguments.length;i<il;i++){$RC.logOneline(arguments[i]);}
$RC.logOneline('-----------------------------------------');};$RC.debugRemember=function(_k,_v)
{$RC.debugRemembered[_k]=_v;};}
else
{$RC.writeLog=function(){return false;};$RC.log=function(){return false;};$RC.debugRemember=function(){return false;};}
$RC.escape_html=function(_string)
{var _replace={"&":"amp",'"':"quot","<":"lt",">":"gt"};return((_string&&_string.replace)?_string.replace(/[&"<>]/g,function(_match){return("&"+_replace[_match]+";");}):'');};$RC.encode=function(_string)
{if(_string==''){return'none';}
var _replace={"!":"%21","'":"%27","(":"%28",")":"%29","*":"%2A"};return((_string&&_string.replace)?_string.replace(/[!'()*]/g,function(_match){return _replace[_match];}):'');};$RC.decode=function(_string)
{if(_string=='none'){return'';}
return((_string&&_string.replace)?decodeURIComponent(_string):'');};$RC.composer__loop=function(_array,_callback)
{for(var _item=false,_i=0,_ii=_array.length;_i<_ii;_i++)
{_item=_array[_i];_callback(_item,((_i===0)?0:((_i==_ii)?-1:_i)));}};$RC.composer__div=function(_content,_class,_after,_no_escape)
{if(_content){}else{return'';}
return''+'<div'+(_class?' class="'+$RC.composer__esc(_class)+'"':'')+'>'+
(_no_escape?_content:$RC.composer__esc(_content))+'</div>'+
(_after?_after:'')+'';};$RC.composer__raw=function(_content,_class,_after)
{return $RC.composer__div(_content,_class,_after,true);};$RC.composer__n2b=function(_text)
{if(_text){}else{return'';}
return _text.replace(/[\r][\n]/gi,"\n").replace(/[\r]/gi,"\n").replace(/[\n]/gi,$RC.composer__br());};$RC.composer__br=function()
{return(arguments.length?(arguments[0]?'<br>':''):'<br>');};$RC.composer__hr=function()
{return'<div class="hr"></div>';};$RC.composer__esc=function(_text)
{return $RC.escape_html(_text);};$RC.sites={'amazon':{'sections_order':['top','images','bullets','book_description','product_description','dp_review','technical_details','reviews'],'sections_unchecked':false,'translations':{},'composer':function(_data,_loop,_div,_raw,_n2b,_esc,_br,_hr){return{'top':(function()
{var _retina=(($RC.window.devicePixelRatio&&($RC.window.devicePixelRatio>1))?'@2x':''),_return=''+
_div(_data.name,'header')+
_raw('<a href="'+_esc(_data.url)+'">'+_esc(_data.url)+'</a>')+'<table class="middle"><tr>'+'<td>'+'<img class="stars" src="'+$RC.settings.imgPath+'amazon--stars--'+_esc(_data.stars_icon)+_retina+'.png" />'+'</td>'+'<td>'+'&nbsp;|&nbsp;'+'</td>'+'<td>'+'<spam>'+_esc(_data.stars_text)+'</span>'+'</td>'+'<td>'+'&nbsp;|&nbsp;'+'</td>'+'<td>'+'<spam>'+_esc(_data.stars_count)+'</span>'+'</td>'+'</tr></table>'+
_div(_data.price,'bold')+'';return _return;})(),'images':(function()
{var _return='';_loop(_data.images,function(_item,_index)
{_return+=''+'<img class="product_image" src="'+_esc(_item)+'" />'+'';});return(_return?(_div(_data.headers.images,'header',_br())+_return):'');})(),'bullets':(function()
{var _return='';_loop(_data.bullets,function(_item,_index)
{_return+=''+'<li>'+_esc(_item)+'</li>'+'';});return(_return?(_div(_data.headers.bullets,'header',_br())+'<ul>'+_return+'<ul>'):'');})(),'reviews':(function()
{var _retina=(($RC.window.devicePixelRatio&&($RC.window.devicePixelRatio>1))?'@2x':''),_return='';_loop(_data.reviews,function(_item,_index)
{_return+=''+
_br(_index)+
_div(_item.title,'bold')+'<table class="middle"><tr>'+'<td>'+'<img class="stars" src="'+$RC.settings.imgPath+'amazon--stars--'+_esc(_item.stars_icon)+_retina+'.png" />'+'</td>'+'<td>'+'&nbsp;|&nbsp;'+'</td>'+'<td>'+'<spam>'+_esc(_item.reviewer_and_date)+'</span>'+'</td>'+'</tr></table>'+
_div(_item.usefulness,'light')+
_raw((function()
{var _return_quote=_n2b(_esc(_item.quote));if(_item.quote_more_url&&_item.quote_more_label){_return_quote+=' <a href="'+_esc(_item.quote_more_url)+'" target="_blank">'+_esc(_item.quote_more_label)+'</a>';}
return _return_quote;})())+'';});return(_return?(_div(_data.headers.reviews,'header',_br())+_return):'');})(),'book_description':(function()
{var _return=''+
_raw(_n2b(_esc(_data.book_description)))+'';return(_return?(_div(_data.headers.book_description,'header',_br())+_return):'');})(),'product_description':(function()
{var _return=''+
_raw(_n2b(_esc(_data.product_description)))+'';return(_return?(_div(_data.headers.product_description,'header',_br())+_return):'');})(),'technical_details':(function()
{var _return_tables='';_loop(_data.technical_details,function(_item_table,_index_table)
{_return_tables+=''+
(function()
{var _return_rows='';_loop(_item_table,function(_item_row,_index_row)
{_return_rows+='<tr>'+'<td class="label">'+_esc(_item_row.label)+'</td>'+'<td>'+_n2b(_esc(_item_row.value))+'</td>'+'</tr>';});return(_return_rows?('<table class="technical">'+_return_rows+'</table>'+_br()):'');})()+'';});_return_tables=(_return_tables?_return_tables.substr(0,(_return_tables.length-_br().length)):'');return(_return_tables?(_div(_data.headers.technical_details,'header',_br())+_return_tables):'');})(),'dp_review':(function()
{if(_data.dp_review){}else{return'';}
var _return=''+
_div(_data.dp_review.score_label+' '+_data.dp_review.score+' | '+_data.dp_review.date,'bold')+
_div(_data.dp_review.summary)+
(function()
{var _return_pros='';_loop(_data.dp_review.pros,function(_item,_index)
{_return_pros+=''+'<li>'+_esc(_item)+'</li>'+'';});return(_return_pros?(_br()+_div(_data.dp_review.pros_label,'bold')+'<ul>'+_return_pros+'</ul>'):'');})()+
(function()
{var _return_cons='';_loop(_data.dp_review.cons,function(_item,_index)
{_return_cons+=''+'<li>'+_esc(_item)+'</li>'+'';});return(_return_cons?(_br()+_div(_data.dp_review.cons_label,'bold')+'<ul>'+_return_cons+'</ul>'):'');})()+
_br()+
_raw('<a href="'+_esc(_data.dp_review.more_url)+'" target="_blank">'+_esc(_data.dp_review.more_label)+'</a>')+'';return(_return?(_div(_data.headers.dp_review,'header',_br())+_return):'');})()};}},'linked_in':{'sections_order':['top','summary','experience','skills','education','endorsements'],'sections_unchecked':false,'composer':function(_data,_loop,_div,_raw,_n2b,_esc,_br,_hr){return{'top':(function()
{var _return=''+
_div(_data.name,'header')+
(_data.email?_raw('<a href="mailto:'+_esc(_data.email)+'">'+_data.email+'</a>'):'')+
_div(_data.headline)+
_div(_data.demographics)+
_br(_data.image)+
(_data.image?_raw('<img class="profile_picture" src="'+_esc(_data.image)+'" />'):'')+
_br()+
_raw('<a href="'+_esc(_data.url)+'">'+_esc(_data.url)+'</a>')+'';return _return;})(),'summary':(function()
{var _return=''+
_div(_data.current_summary)+
_div(_data.experience_summary)+
_div(_data.education_summary)+
_br(_data.description)+
_raw(_n2b(_esc(_data.description)))+'';return(_return?(_div(_data.headers.summary,'header',_br())+_return):'');})(),'experience':(function()
{var _return='';_loop(_data.experience,function(_item,_index)
{_return+=''+
_br(_index)+
_div(_item.title_and_company,'bold')+
_div(_item.period_and_location,'light')+
_raw(_n2b(_esc(_item.description)),'')+'';});return(_return?(_div(_data.headers.experience,'header',_br())+_return):'');})(),'skills':(function()
{var _return='';var _skill_count=false;_loop(_data.skills,function(_item){if(_item.count>0){_skill_count=true;}});if(_skill_count)
{_loop(_data.skills,function(_item)
{_return+='<tr>'+'<td>'+_esc(_item.count)+'</td>'+'<td>'+_esc(_item.name)+'</td>'+'</tr>';});_return=(_return?('<table class="skills">'+_return+'</table>'):'');}
else
{_loop(_data.skills,function(_item)
{_return+=_div(_item.name);});}
return(_return?(_div(_data.headers.skills,'header',_br())+_return):'');})(),'education':(function()
{var _return='';_loop(_data.education,function(_item,_index)
{_return+=''+
_br(_index)+
_div(_item.institution,'bold')+
_div(_item.major)+
_div(_item.period,'light')+'';});return(_return?(_div(_data.headers.education,'header',_br())+_return):'');})(),'endorsements':(function()
{var _return_jobs='';_loop(_data.endorsements,function(_item_job,_index_job)
{_return_jobs+=''+
_br(_index_job)+
_div(_item_job.position_and_company,'bold')+
(function()
{var _return_endorsements='';_loop(_item_job.endorsements,function(_item_endorsement,_index_endorsement)
{_return_endorsements+=''+
_br(_index_endorsement)+
_div(_item_endorsement.quote)+
_raw(('<a href="'+_esc(_item_endorsement.person_url)+'">'+_esc(_item_endorsement.person_and_position)+'</a>'),'light')+
_div(_item_endorsement.date_and_connection,'light')+'';});return _return_endorsements;})()+'';});return(_return_jobs?(_div(_data.headers.endorsements,'header',_br())+_return_jobs):'');})()};}},'youtube':{'sections_order':['top','summary','comments'],'sections_unchecked':false,'composer':function(_data,_loop,_div,_raw,_n2b,_esc,_br,_hr){return{'top':(function()
{var _return=''+
_div(_data.title,'header')+
_raw('<a href="'+_esc(_data.url)+'">'+_esc(_data.url)+'</a>')+
_div(_data.author)+
_div(_data.views+' '+_data.views_label)+
_div(_data.published)+
_br(_data.image)+
(_data.image?(''+'<table><tr><td><div class="video_image_container">'+'<img class="video_image" src="'+_esc(_data.image)+'" />'+'<a class="video_image_play" target="_blank" href="'+_esc(_data.url)+'"></a>'+'</div></td></tr></table>'+''):'')+'';return _return;})(),'summary':(function()
{var _return=''+
_raw(_data.summary_html)+'';return(_return?(_div(_data.headers.summary,'header',_br())+_return):'');})(),'comments':(function()
{var _return='';_loop(_data.comments,function(_item,_index)
{_return+=''+
_br(_index)+
_raw(''+'<span class="bold">'+_esc(_item.author)+'</span>'+'<span> | '+_esc(_item.date)+'</span>'+'')+
_raw(_item.quote_html)+'';});return(_return?(_div(_data.headers.comments,'header',_br())+_return):'');})()};}}};$RC.createFrame=function()
{var _frame_id=$RC.settings.onCreateFrameUseThisId;var _iframeElement=$RC.document.createElement('iframe'),_iframeBodyHTML=''+
$RC.settings.onCreateFrameInjectThisHTMLBefore+'<div id="bodyContent">'+'<div id="box">'+'<div class="content" id="contentToDisplay"></div>'+'<div class="content" id="contentToSave"></div>'+'</div>'+'<div id="background"><div id="backgroundInner"></div></div>'+'</div>'+'<link rel="stylesheet" href="'+$RC.settings.cssPath+'style.css" type="text/css" />'+'<link rel="stylesheet" href="'+$RC.settings.cssImagesFile+'" type="text/css" />'+'<link rel="stylesheet" href="'+$RC.settings.cssFontsFile+'" type="text/css" />'+
$RC.settings.onCreateFrameInjectThisHTMLAfter+'',_iframeDocumentHTML=''+'<!DOCTYPE html>'+'<html id="html">'+'<body id="body">'+
_iframeBodyHTML+'</body>'+'</html>'+'';_iframeElement.setAttribute('id',_frame_id);_iframeElement.setAttribute('frameBorder','0');_iframeElement.setAttribute('allowTransparency','true');_iframeElement.setAttribute('scrolling','auto');if($RC.settings.onCreateFrameUseThisURLAsTheLocation){_iframeElement.setAttribute('src',$RC.settings.onCreateFrameUseThisURLAsTheLocation);}
if($RC.settings.onCreateFrameDoNotInsertCSS){}else
{var _cssElement=$RC.document.createElement('style'),_cssText=''+'#'+_frame_id+' { '+'margin: 0; padding: 0; border: none; '+'position: absolute; '+'width: 10px; height: 10px; '+'top: -100px; left: -100px; '+'} '+'';_cssElement.setAttribute('id',_frame_id+'__css');_cssElement.setAttribute('type','text/css');if(_cssElement.styleSheet){_cssElement.styleSheet.cssText=_cssText;}
else{_cssElement.appendChild($RC.document.createTextNode(_cssText));}}
var _parent=($RC.settings.createFrameInsideElementWithThisId?$RC.document.getElementById($RC.settings.createFrameInsideElementWithThisId):false),_container=(_parent||$RC.document.body);if(_cssElement){_container.appendChild(_cssElement);}
_container.appendChild(_iframeElement);var _check1_interval=false;var _check1=function()
{var _iframe=$RC.document.getElementById(_frame_id);if(_iframe){}else{return;}
var _doc=(_iframe.contentDocument||_iframe.contentWindow.document);if(_doc){}else{return;}
if($RC.settings.onCreateFrameUseThisURLAsTheLocation)
{var _body=_doc.getElementById('body');if(_body){}else{return;}
_body.innerHTML=_iframeBodyHTML;}
else
{$RC.settings.doDocumentWrite(_doc,_iframeDocumentHTML);}
$RC.window.clearInterval(_check1_interval);};_check1_interval=$RC.window.setInterval(_check1,$RC.settings.onCreateFrameUseThisBaseTimer);var _check2_interval=false;var _check2=function()
{var _iframe=$RC.document.getElementById(_frame_id);if(_iframe){}else{return;}
var _doc=(_iframe.contentDocument||_iframe.contentWindow.document);if(_doc){}else{return;}
var _body=_doc.getElementById('bodyContent');if(_body){}else{return;}
for(var _var='',_i=0,_ii=$RC.settings.onCreateFrameWaitForTheseWindowVars.length;_i<_ii;_i++)
{_var=$RC.settings.onCreateFrameWaitForTheseWindowVars[_i];if(_var.indexOf('.')===false)
{if(_var in _iframe.contentWindow){}else{return;}}
else
{var _chain=_var.split('.'),_curr=_iframe.contentWindow;for(var _z=0,_zz=_chain.length;_z<_zz;_z++)
{if(_chain[_z]in _curr){}else{return;}
_curr=_curr[_chain[_z]];}}}
$RC.window.clearInterval(_check2_interval);$RC.iframe=_iframe;$RC.$iframe=$($RC.iframe);$RC.iframeDocument=_doc;$RC.$iframeDocument=$($RC.iframeDocument);$RC.iframeWindow=_iframe.contentWindow;$RC.$iframeWindow=$($RC.iframeWindow);$RC.$iframeBox=$RC.$iframeDocument.find('#box');$RC.$iframeContentToDisplay=$RC.$iframeDocument.find('#contentToDisplay');$RC.$iframeContentToSave=$RC.$iframeDocument.find('#contentToSave');$RC.$iframeBackground=$RC.$iframeDocument.find('#background');if($RC.callbacks&&$RC.callbacks.frameCreated){$RC.callbacks.frameCreated();}};_check2_interval=$RC.window.setInterval(_check2,($RC.settings.onCreateFrameUseThisBaseTimer));};$RC.displayDetected=function(_detected)
{switch(true)
{case(!_detected.site):case(!_detected.data):case(!$RC.sites[_detected.site.id]):$RC.detected=false;return;}
$RC.detected=_detected;$RC.$iframeDocument.find('#siteCSS').remove();$RC.$iframeDocument.find('head').append(''+'<link id="siteCSS" href="'+
$RC.escape_html($RC.settings.cssPath)+'site__'+$RC.escape_html($RC.detected.site.id)+'.css'+'" rel="stylesheet" type="text/css" />'+'');var _composer=$RC.sites[$RC.detected.site.id].composer;$RC.composed=_composer($RC.detected.data,$RC.composer__loop,$RC.composer__div,$RC.composer__raw,$RC.composer__n2b,$RC.composer__esc,$RC.composer__br,$RC.composer__hr);for(var _section in $RC.composed){if($RC.composed[_section]){}else{delete $RC.composed[_section];}}
var _sections_unchecked=(function(){var _r={},_a=$RC.sites[$RC.detected.site.id].sections_unchecked;for(var _i=0,_ii=_a.length;_i<_ii;_i++){_r[_a[_i]]=true;}
return _r;})();var _html='';$RC.loopThroughSections(function(_section,_index)
{_html+=''+'<div id="display__section__'+_section+'" class="section section__'+_section+' '+(_sections_unchecked[_section]?'unchecked':'checked')+'">'+
(_index?('<div class="checkbox" id="display__section__'+_section+'__checkbox"></div>'):'')+'<div class="section_content" id="display__section__'+_section+'__content">'+
$RC.composer__br(_index)+
$RC.composed[_section]+
$RC.composer__br()+'</div>'+'</div>'+
$RC.composer__hr()+'';});_html=_html.substr(0,(_html.length-$RC.composer__hr().length));$RC.$iframeContentToDisplay.html(_html);$RC.onlyCheckedSections();$RC.$iframeContentToDisplay.find('div.checkbox').click(function()
{var _$section=$(this.parentNode);switch(true)
{case(_$section.hasClass('unchecked')):_$section.removeClass('unchecked').addClass('checked');break;case(_$section.hasClass('checked')):_$section.removeClass('checked').addClass('unchecked');break;}
$RC.onlyCheckedSections();});};$RC.loopThroughSections=function(_callback)
{if($RC.detected){}else{return;}
if($RC.composed){}else{return;}
for(var _section=false,_i=0,_ii=$RC.sites[$RC.detected.site.id].sections_order.length;_i<_ii;_i++)
{_section=$RC.sites[$RC.detected.site.id].sections_order[_i];if($RC.composed[_section]){}else{continue;}
_callback(_section,((_i===0)?0:((_i==_ii)?-1:_i)));}};$RC.onlyCheckedSections=function()
{$RC.checkedSections=[];$RC.uncheckedSections=[];var _htmlToSave='';$RC.loopThroughSections(function(_section)
{var _$section=$RC.$iframeDocument.find('#display__section__'+_section),_$checkbox=$RC.$iframeDocument.find('#display__section__'+_section+'__checkbox'),_$content=$RC.$iframeDocument.find('#display__section__'+_section+'__content');if(_$section.hasClass('checked'))
{$RC.checkedSections.push(_section);_htmlToSave+=''+
_$content.html()+
$RC.composer__hr()+'';}
else
{$RC.uncheckedSections.push(_section);}});_htmlToSave=_htmlToSave.substr(0,(_htmlToSave.length-$RC.composer__hr().length));$RC.$iframeContentToSave.html(_htmlToSave);};$RC.getUncheckedSections=function()
{return $RC.uncheckedSections;};$RC.getCheckedSections=function()
{return $RC.checkedSections;};$RC.setUncheckedSections=function(_site_id,_unchecked_sections)
{if($RC.sites[_site_id]){}else{return;}
$RC.sites[_site_id].sections_unchecked=_unchecked_sections;};$RC.getContentToSaveNode=function()
{return $RC.$iframeContentToSave.get(0);};$RC.getContentToSaveHTML=function()
{var _node=$RC.getContentToSaveNode();if(_node){}else{return false;}
if(_node.innerHTML){}else{return false;}
var _html=_node.innerHTML;return _html;};return $RC;}