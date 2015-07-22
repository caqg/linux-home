function initClearlyComponent__reformat(_paramInstance){if(_paramInstance){}else{return false;}
var $R=_paramInstance;switch(true)
{case(!($R.settings)):case(!($R.settings.path)):case(!($R.window)):case(!($R.window.document)):case(!($R.window.document.body)):case(!($R.jQuery)):if($R.debug)
{console.log(!($R.settings));console.log(!($R.settings.path));console.log(!($R.window));console.log(!($R.window.document));console.log(!($R.window.document.body));console.log(!($R.jQuery));}
return false;}
$R.document=$R.window.document;var _default=function(_setting,_default_value){if($R.settings[_setting]){}else{$R.settings[_setting]=_default_value;}};_default('onCreateFrameUseThisId','clearly_frame');_default('onCreateFrameUseThisBaseTimer',50);_default('onCreateFrameUseThisURLAsTheLocation','');_default('onCreateFrameDoNotInsertCSS',false);_default('onCreateFrameInjectThisHTMLAfter','');_default('onCreateFrameInjectThisHTMLBefore','');_default('onCreateFrameWaitForTheseWindowVars',[]);_default('onGetCSSFromOptionsInjectThisCSSAfter','');_default('onAddPageAttachFootnotesToLinks',false);_default('createFrameInsideElementWithThisId','');_default('pageLabel',function(_nr){return _nr;});_default('linksLabel','');_default('articleTitleMarker__end','</h1><div id="articleHeader__separator"></div></div>');_default('articleTitleMarker__end__separator','<div id="articleHeader__separator"></div>');_default('doDocumentWrite',function(_document,_html){_document.open();_document.write(_html);_document.close();});_default('cssPath',$R.settings.path+'css/');_default('https',(/^https:/gi.test($R.window.location.href)));var $=$R.jQuery;$R.$window=$($R.window);$R.$document=$($R.document);$R.pagesCount=0;$R.footnotedLinksCount=0;$R.debug=($R.debug||false);$R.debugRemembered={};$R.debugTimers=[];if($R.debug)
{switch(true)
{case(!(!($R.window.console&&$R.window.console.log))):$R.logOneLine=function(msg){$R.window.console.log(msg);};break;case(!(!($R.window.opera&&$R.window.opera.postError))):$R.logOneLine=function(msg){$R.window.opera.postError(msg);};break;default:$R.logOneLine=function(msg){};break;}
$R.log=function()
{if($R.debug){}else{return;}
for(var i=0,il=arguments.length;i<il;i++){$R.logOneLine(arguments[i]);}
$R.logOneLine('-----------------------------------------');};$R.debugRemember=function(_k,_v)
{$R.debugRemembered[_k]=_v;};}
else
{$R.logOneLine=function(){return false;};$R.log=function(){return false;};$R.debugRemember=function(){return false;};}
$R.escape_html=function(_string)
{var _replace={"&":"amp",'"':"quot","<":"lt",">":"gt"};return((_string&&_string.replace)?_string.replace(/[&"<>]/g,function(_match){return("&"+_replace[_match]+";");}):'');};$R.encode=function(_string)
{if(_string==''){return'none';}
var _replace={"!":"%21","'":"%27","(":"%28",")":"%29","*":"%2A"};return((_string&&_string.replace)?_string.replace(/[!'()*]/g,function(_match){return _replace[_match];}):'');};$R.decode=function(_string)
{if(_string=='none'){return'';}
return((_string&&_string.replace)?decodeURIComponent(_string):'');};(function()
{if($R.defaultThemes){return true;}
$R.defaultThemes={'newsprint':{'text_font':'"PT Serif"','text_font_header':'"PT Serif"','text_font_monospace':'Inconsolata','text_size':'16px','text_line_height':'1.5em','box_width':'36em','color_background':'#f3f2ee','color_text':'#1f0909','color_links':'#065588','text_align':'normal','base':'newsprint','footnote_links':'on_print','large_graphics':'do_nothing','custom_css':''},'notable':{'text_font':'Helvetica, Arial','text_font_header':'Helvetica, Arial','text_font_monospace':'"Droid Sans Mono"','text_size':'14px','text_line_height':'1.5em','box_width':'42em','color_background':'#fff','color_text':'#333','color_links':'#090','text_align':'normal','base':'notable','footnote_links':'on_print','large_graphics':'do_nothing','custom_css':''},'night_owl':{'text_font':'"PT Serif"','text_font_header':'"PT Serif"','text_font_monospace':'Inconsolata','text_size':'16px','text_line_height':'1.5em','box_width':'36em','color_background':'#2d2d2d','color_text':'#e3e3e3','color_links':'#e3e3e3','text_align':'normal','base':'night_owl','footnote_links':'on_print','large_graphics':'do_nothing','custom_css':''}};return true;})();(function()
{if($R.availableFontSizes){return true;}
$R.availableFontSizes={'small':{'newsprint':'12px','notable':'12px','night_owl':'12px'},'medium':{'newsprint':'16px','notable':'16px','night_owl':'16px'},'large':{'newsprint':'20px','notable':'20px','night_owl':'20px'}};return true;})();(function()
{if($R.availableGoogleFonts){return true;}
var __google_fonts_array=['Arvo','Bentham','Cardo','Copse','Corben','Crimson Text','Droid Serif','Goudy Bookletter 1911','Gruppo','IM Fell','Josefin Slab','Kreon','Meddon','Merriweather','Neuton','OFL Sorts Mill Goudy TT','Old Standard TT','Philosopher','PT Serif','Radley','Tinos','Vollkorn','Allerta','Anton','Arimo','Bevan','Buda','Cabin','Cantarell','Coda','Cuprum','Droid Sans','Geo','Josefin Sans','Lato','Lekton','Molengo','Nobile','Orbitron','PT Sans','Puritan','Raleway','Syncopate','Ubuntu','Yanone Kaffeesatz','Anonymous Pro','Cousine','Droid Sans Mono','Inconsolata'];$R.availableGoogleFonts={};for(var i=0,ii=__google_fonts_array.length;i<ii;i++){$R.availableGoogleFonts[__google_fonts_array[i]]=1;}
return true;})();(function()
{if($R.defaultOptions){return true;}
$R.defaultOptions={'text_font':$R.encode('"PT Serif"'),'text_font_header':$R.encode('"PT Serif"'),'text_font_monospace':$R.encode('Inconsolata'),'text_size':$R.encode('16px'),'text_line_height':$R.encode('1.5em'),'box_width':$R.encode('36em'),'color_background':$R.encode('#f3f2ee'),'color_text':$R.encode('#1f0909'),'color_links':$R.encode('#065588'),'text_align':$R.encode('normal'),'base':$R.encode('newsprint'),'footnote_links':$R.encode('on_print'),'large_graphics':$R.encode('do_nothing'),'custom_css':$R.encode('')};return true;})();$R.getCSSFromOptions=function(_options)
{var _paddingTop='4.5em',_paddingBottom='9em';switch(true)
{case(_options['text_line_height'].match(/%/)!=null):case(_options['text_line_height'].match(/^([0-9.]+)$/)!=null):break;default:_paddingTop=(_options['text_line_height'].replace(/^([0-9.]+)/,function(_x,_nr){return((0+_nr)*3);}));_paddingBottom=(_options['text_line_height'].replace(/^([0-9.]+)/,function(_x,_nr){return((0+_nr)*6);}));break;}
var _cssText=(''+'#body { '+'font-family: [=text_font]; '+'font-size: [=text_size]; '+'line-height: [=text_line_height]; '+'color: [=color_text]; '+'text-align: '+(_options['text_align']=='justified'?'justify':'left')+'; '+'} '+'#text { '+'padding-top: '+_paddingTop+';'+'padding-bottom: '+_paddingBottom+';'+'} '+'#background { background-color: [=color_background]; } '+'.setTextColorAsBackgroundColor { background-color: [=color_text]; } '+'.setBackgroundColorAsTextColor { color: [=color_background]; } '+'.setBackgroundColor { background-color: [=color_background]; } '+'.setTextColor { color: [=color_text]; } '+'#box, .setBoxWidth { width: [=box_width]; } '+'a { color: [=color_links]; } '+'a:visited { color: [=color_text]; } '+'@media print { body.footnote_links__on_print a, body.footnote_links__on_print a:hover { color: [=color_text] !important; text-decoration: none !important; } } '+'body.footnote_links__always a, body.footnote_links__always a:hover { color: [=color_text] !important; text-decoration: none !important; } '+'img { border-color: [=color_text]; } '+'a img { border-color: [=color_links]; } '+'a:visited img { border-color: [=color_text]; } '+'h1 a, h2 a, a h1, a h2 { color: [=color_text]; } '+'h1, h2, h3, h4, h5, h6 { font-family: [=text_font_header]; } '+'pre { background-color: [=color_background]; } '+'pre, code { font-family: [=text_font_monospace]; } '+'hr { border-color: [=color_text]; } '+'html.rtl #body #text { text-align: '+(_options['text_align']=='justified'?'justify':'right')+' !important; } '+'h1, h2, h3, h4, h5, h6 { text-align: left; } '+'html.rtl h1, html.rtl h2, html.rtl h3, html.rtl h4, html.rtl h5, html.rtl h6 { text-align: right !important; } '+'#text div.separatorLine, #text section::before { '+'background:      -o-linear-gradient(0, [=color_background] 1%, [=color_text] 50%, [=color_background] 99%); '+'background:    -moz-linear-gradient(0, [=color_background] 1%, [=color_text] 50%, [=color_background] 99%); '+'background: -webkit-linear-gradient(0, [=color_background] 1%, [=color_text] 50%, [=color_background] 99%); '+'}'+'[=custom_css] '+
$R.settings.onGetCSSFromOptionsInjectThisCSSAfter+'').replace(/\[=([a-z_]+?)\]/gi,function(_match,_key){return _options[_key];});return _cssText;};$R.appliedOptions={};$R.loadedGoogleFonts={};$R.applyUnencodedOptions=function(_unencodedOptions)
{var _encodedOptions={};for(var _x in _unencodedOptions){_encodedOptions[_x]=$R.encode(_unencodedOptions[_x]);}
$R.applyEncodedOptions(_encodedOptions);};$R.applyEncodedOptions=function(_encodedOptions)
{var _possible_options=$R.defaultOptions;if(_encodedOptions){}else{_encodedOptions={};}
for(var _option in _possible_options)
{switch(true)
{case(!(_option in _encodedOptions)):case(!(_encodedOptions[_option]>'')):_encodedOptions[_option]=($R.appliedOptions[_option]?$R.appliedOptions[_option]:_possible_options[_option]);break;}}
var _resetBase=false,_resetOptions=false,_decodedOptions={};switch(true)
{case(!('base'in $R.appliedOptions)):case(!(_encodedOptions['base']==$R.appliedOptions['base'])):_resetBase=true;break;}
for(var _option in _possible_options)
{switch(true)
{case(!(_option in $R.appliedOptions)):case(!(_encodedOptions[_option]==$R.appliedOptions[_option])):_resetOptions=true;break;}
if(_resetOptions){break;}}
for(var _option in _possible_options)
{$R.appliedOptions[_option]=_encodedOptions[_option];_decodedOptions[_option]=$R.decode(_encodedOptions[_option]);}
if(_resetBase)
{$R.$iframeDocument.find('#baseCSS').remove();if(_decodedOptions['base']>'')
{var _b=_decodedOptions['base'];switch(_b){case'theme-1':_b='newsprint';break;case'theme-2':_b='notable';break;case'theme-3':_b='night_owl';break;}
$R.$iframeDocument.find('head').append(''+'<link id="baseCSS" href="'+
$R.escape_html($R.settings.cssPath)+'base__'+$R.escape_html(_b)+'.css'+'" rel="stylesheet" class="'+$R.escape_html(_b)+'" type="text/css" />'+'');}}
if(_resetOptions)
{var _cssText=$R.getCSSFromOptions(_decodedOptions);$R.$iframeDocument.find('#optionsCSS').remove();var _cssElement=$R.iframeDocument.createElement('style');_cssElement.setAttribute('type','text/css');_cssElement.setAttribute('id','optionsCSS');if(_cssElement.styleSheet){_cssElement.styleSheet.cssText=_cssText;}
else{_cssElement.appendChild($R.iframeDocument.createTextNode(_cssText));}
$R.$iframeDocument.find('head').append(_cssElement);$R.$iframeDocument.find('body').removeClass('footnote_links__on_print footnote_links__always footnote_links__never').removeClass('large_graphics__do_nothing large_graphics__hide_on_print large_graphics__hide_always').addClass('footnote_links__'+_decodedOptions['footnote_links']).addClass('large_graphics__'+_decodedOptions['large_graphics']);}};$R.applyCustomCSSFile=function(_file)
{var _file_name=_file;switch(_file_name){case'theme-1':_file_name='newsprint';break;case'theme-2':_file_name='notable';break;case'theme-3':_file_name='night_owl';break;}
var _new_url=$R.settings.cssPath+'custom__'+_file_name+'.css';var _current_url=$R.$iframeDocument.find('#customFileCSS').attr('href');if(_new_url==_current_url){return;}
$R.$iframeDocument.find('#customFileCSS').remove();$R.$iframeDocument.find('head').append('<link id="customFileCSS" href="'+$R.escape_html(_new_url)+'" rel="stylesheet" type="text/css" />');};$R.getGoogleFontsFromOptions=function(_options)
{var _fonts={},_fonts_urls=[],_check_font=function(_match,_font){if(_font in $R.availableGoogleFonts){_fonts[_font]=1;}};_options['text_font'].replace(/"([^",]+)"/gi,_check_font);_options['text_font'].replace(/([^",\s]+)/gi,_check_font);_options['text_font_header'].replace(/"([^",]+)"/gi,_check_font);_options['text_font_header'].replace(/([^",\s]+)/gi,_check_font);_options['text_font_monospace'].replace(/"([^",]+)"/gi,_check_font);_options['text_font_monospace'].replace(/([^",\s]+)/gi,_check_font);_options['custom_css'].replace(/font-family: "([^",]+)"/gi,_check_font);_options['custom_css'].replace(/font-family: ([^",\s]+)/gi,_check_font);for(var _font in _fonts)
{_fonts_urls.push(''+'http'+($R.settings.https?'s':'')+'://fonts.googleapis.com/css?family='+
_font.replace(/\s+/g,'+')+':regular,bold,italic'+'');}
return _fonts_urls;};$R.loadGoogleFontsRequiredByAppliedOptions=function()
{var _decodedOptions={};for(var _option in $R.appliedOptions)
{_decodedOptions[_option]=$R.decode($R.appliedOptions[_option]);}
var _fonts_urls=$R.getGoogleFontsFromOptions(_decodedOptions);for(var i=0,_i=_fonts_urls.length;i<_i;i++){if($R.loadedGoogleFonts[_fonts_urls[i]]){continue;}
$R.$iframeDocument.find('head').append('<link href="'+$R.escape_html(_fonts_urls[i])+'" rel="stylesheet" type="text/css" />');$R.loadedGoogleFonts[_fonts_urls[i]]=1;}};$R.createFrame=function()
{var _frame_id=$R.settings.onCreateFrameUseThisId;var _iframeElement=$R.document.createElement('iframe'),_iframeBodyHTML=''+
$R.settings.onCreateFrameInjectThisHTMLBefore+'<div id="bodyContent">'+'<div id="box">'+'<div id="box_inner">'+'<div id="text">'+'<div id="pages"></div>'+'<div id="footnotedLinks" class="separateSection">'+'<div id="footnotedLinks__separator" class="separator">'+'<div class="separatorLine setTextColorAsBackgroundColor"></div>'+
(($R.settings.linksLabel>'')?(''+'<div class="separatorLabel setBackgroundColor">'+
$R.escape_html($R.settings.linksLabel)+'</div>'):'')+'</div>'+'<ol id="footnotedLinks__list"></ol>'+'</div>'+'<div id="measure__lineHeight">Measure</div>'+'<div id="measure__fontSize">Measure</div>'+'</div>'+'</div>'+'</div>'+'<div id="background"></div>'+'</div>'+'<link rel="stylesheet" href="'+$R.settings.cssPath+'style.css" type="text/css" />'+
$R.settings.onCreateFrameInjectThisHTMLAfter+'',_iframeDocumentHTML=''+'<!DOCTYPE html>'+'<html id="html">'+'<body id="body">'+
_iframeBodyHTML+'</body>'+'</html>'+'';_iframeElement.setAttribute('id',_frame_id);_iframeElement.setAttribute('frameBorder','0');_iframeElement.setAttribute('allowTransparency','true');_iframeElement.setAttribute('scrolling','auto');if($R.settings.onCreateFrameUseThisURLAsTheLocation>''){_iframeElement.setAttribute('src',$R.settings.onCreateFrameUseThisURLAsTheLocation);}
if($R.settings.onCreateFrameDoNotInsertCSS){}else
{var _cssElement=$R.document.createElement('style'),_cssText=''+'#'+_frame_id+' { '+'margin: 0; padding: 0; border: none; '+'position: absolute; '+'width: 10px; height: 10px; '+'top: -100px; left: -100px; '+'} '+'';_cssElement.setAttribute('id',_frame_id+'__css');_cssElement.setAttribute('type','text/css');if(_cssElement.styleSheet){_cssElement.styleSheet.cssText=_cssText;}
else{_cssElement.appendChild($R.document.createTextNode(_cssText));}}
var _parent=($R.settings.createFrameInsideElementWithThisId>''?$R.document.getElementById($R.settings.createFrameInsideElementWithThisId):false),_container=(_parent||$R.document.body);if(_cssElement){_container.appendChild(_cssElement);}
_container.appendChild(_iframeElement);var _check1_interval=false;var _check1=function()
{var _iframe=$R.document.getElementById(_frame_id);if(_iframe){}else{return;}
var _doc=(_iframe.contentDocument||_iframe.contentWindow.document);if(_doc){}else{return;}
if($R.settings.onCreateFrameUseThisURLAsTheLocation>'')
{var _body=_doc.getElementById('body');if(_body){}else{return;}
_body.innerHTML=_iframeBodyHTML;}
else
{$R.settings.doDocumentWrite(_doc,_iframeDocumentHTML);}
$R.window.clearInterval(_check1_interval);};_check1_interval=$R.window.setInterval(_check1,$R.settings.onCreateFrameUseThisBaseTimer);var _check2_interval=false;var _check2=function()
{var _iframe=$R.document.getElementById(_frame_id);if(_iframe){}else{return;}
var _doc=(_iframe.contentDocument||_iframe.contentWindow.document);if(_doc){}else{return;}
var _body=_doc.getElementById('bodyContent');if(_body){}else{return;}
for(var _var='',_i=0,_ii=$R.settings.onCreateFrameWaitForTheseWindowVars.length;_i<_ii;_i++)
{_var=$R.settings.onCreateFrameWaitForTheseWindowVars[_i];if(_var.indexOf('.')===false)
{if(_var in _iframe.contentWindow){}else{return;}}
else
{var _chain=_var.split('.'),_curr=_iframe.contentWindow;for(var _z=0,_zz=_chain.length;_z<_zz;_z++)
{if(_chain[_z]in _curr){}else{return;}
_curr=_curr[_chain[_z]];}}}
$R.window.clearInterval(_check2_interval);$R.iframe=_iframe;$R.$iframe=$($R.iframe);$R.iframeDocument=_doc;$R.$iframeDocument=$($R.iframeDocument);$R.iframeWindow=_iframe.contentWindow;$R.$iframeWindow=$($R.iframeWindow);$R.$iframeBox=$R.$iframeDocument.find('#box');$R.$iframePages=$R.$iframeDocument.find('#pages');$R.$iframeBackground=$R.$iframeDocument.find('#background');$R.$iframeFootnotedLinksList=$R.$iframeDocument.find('#footnotedLinks__list');if($R.callbacks&&$R.callbacks.frameCreated){$R.callbacks.frameCreated();}};_check2_interval=$R.window.setInterval(_check2,($R.settings.onCreateFrameUseThisBaseTimer));};$R.addNewPage=function(_pageHTML,_pageURL)
{var _pageNr=$R.pagesCount+1;$R.pagesCount++;if(_pageNr>1)
{$R.$iframePages.append(''+'<div class="separator">'+'<div class="separatorLine setTextColorAsBackgroundColor"></div>'+'<div class="separatorLabel setBackgroundColor"><em>'+$R.escape_html($R.settings.pageLabel($R.escape_html(''+_pageNr)))+'</em></div>'+'</div>'+'');}
if((_pageNr==1)&&($R.settings.articleTitleMarker__end>''))
{var _new_end=$R.settings.articleTitleMarker__end.replace($R.settings.articleTitleMarker__end__separator,'<div id="articleHeader__separator" class="separator">'+'<div class="separatorLine setTextColorAsBackgroundColor"></div>'+'</div>');_pageHTML=_pageHTML.replace($R.settings.articleTitleMarker__end,_new_end);}
$R.$iframePages.append(''+'<div class="page" id="page'+$R.escape_html(''+_pageNr)+'">'+'<div class="page_content">'+
_pageHTML+'</div>'+'</div>'+'');var _$page=$R.$iframeDocument.find('#page'+_pageNr);if($R.settings.onAddPageAttachFootnotesToLinks)
{_$page.find('a').each(function(_index,_element)
{var _href=_element.href;if(_href>''){}else{return;}
if(_href.indexOf){}else{return;}
if(_href.indexOf('#')>-1){return;}
$R.footnotedLinksCount++;var _nr=$R.footnotedLinksCount;$(_element).append('<sup class="readableLinkFootnote">['+$R.escape_html(''+_nr)+']</sup>');$R.$iframeFootnotedLinksList.append('<li><a href="'+$R.escape_html(_href)+'">'+$R.escape_html(_href)+'</a></li>');});}};$R.clearAllPages=function()
{$R.pagesCount=0;var _p=$R.$iframePages.get(0);while(_p.firstChild){_p.removeChild(_p.firstChild);}
$R.footnotedLinksCount=0;var _f=$R.$iframeFootnotedLinksList.get(0);while(_f.firstChild){_f.removeChild(_f.firstChild);}};return $R;}