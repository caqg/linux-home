/*! Copyright 2009-2015 Evernote Corporation. All rights reserved. */
function calcBodyWidth(){var a=154;/hidable/.test(document.body.className)&&(a=172);var b=0,c=document.querySelector(".tooltipon:first-child");if(c){var d=parseInt(window.getComputedStyle(c,":before").width)+23;b=d-25}if(c=document.querySelector(".tooltipon:last-child")){var d=parseInt(window.getComputedStyle(c,":before").width)+23;b=Math.max(d-78,0)}var e=document.querySelector(".subtool_panel.visible");return e?Math.max(a+b,330):a+b}function finishNotebookLoading(){userSelectedNotebook||(smartFilingNotebook&&startingNotebookAllowed(smartFilingNotebook)?notebookSelector.select(smartFilingNotebook):alwaysStartInNotebook&&startingNotebookAllowed(alwaysStartInNotebook)?notebookSelector.select(alwaysStartInNotebook):recentNotebook&&startingNotebookAllowed(recentNotebook)&&notebookSelector.select(recentNotebook)),notebookSelector.markStatus(!0)}function handleClipperToolClick(){switch(activeClipType&&activeClipType.classList.remove("active"),activeClipType=this,activeClipType.classList.add("active"),this.id){case"article":Browser.sendToExtension({name:"setPersistentValue",key:"lastUsedAction",value:"ARTICLE"}),Browser.sendToExtension({name:"bounce",message:{name:"previewArticle"}});break;case"clearly":Browser.sendToExtension({name:"setPersistentValue",key:"lastUsedAction",value:"CLEARLY"}),Browser.sendToExtension({name:"bounce",message:{name:"previewClearly"}});break;case"custom":Browser.sendToExtension({name:"bounce",message:{name:"previewCustom"}});break;case"fullPage":Browser.sendToExtension({name:"setPersistentValue",key:"lastUsedAction",value:"FULL_PAGE"}),Browser.sendToExtension({name:"bounce",message:{name:"previewFullPage"}});break;case"pdf":Browser.sendToExtension({name:"bounce",message:{name:"previewPdf"}});break;case"url":Browser.sendToExtension({name:"setPersistentValue",key:"lastUsedAction",value:"URL"}),Browser.sendToExtension({name:"bounce",message:{name:"previewUrl"}});break;case"screenshot":document.body.classList.contains("skitchReady")?Browser.sendToExtension({name:"bounce",message:{name:"clearPreview"}}):(document.body.classList.add("skitchWaiting"),Browser.sendToExtension({name:"bounce",message:{name:"previewSkitch"}}),setHeight()),Browser.sendToExtension({name:"setPersistentValue",key:"lastUsedAction",value:"SKITCH"});break;case"email":Browser.sendToExtension({name:"bounce",message:{name:"previewEmail"}});break;case"selection":Browser.sendToExtension({name:"bounce",message:{name:"previewSelection"}})}}function handleEscape(a){document.activeElement===title?title.blur():notebookSelector.close()||tagSelector.abort()||(document.activeElement===comments?comments.blur():Browser.sendToExtension({name:"bounce",message:{name:"duplicateKeyboardShortcut",keycode:a.keycode}}))}function handleSkitchToolClick(a){if("colors"!==this.id&&"zoomin"!==this.id&&"zoomout"!==this.id&&"crop"!==this.id){var b=document.getElementsByClassName("selectedSkitchTool")[0];b&&b.classList.remove("selectedSkitchTool"),this.classList.add("selectedSkitchTool")}"shapes"===this.id||"stamps"===this.id?Browser.sendToExtension({name:"bounce",message:{name:"skitch_useTool",tool:this.getAttribute("data-tool")}}):"zoomin"===this.id?Browser.sendToExtension({name:"bounce",message:{name:"skitch_zoomIn"}}):"zoomout"===this.id?Browser.sendToExtension({name:"bounce",message:{name:"skitch_zoomOut"}}):"colors"!==this.id&&(Browser.sendToExtension({name:"bounce",message:{name:"skitch_useTool",charCode:a?a.charCode:null,loc:a?a.loc:null,tool:this.id}}),"highlighter"===this.id&&Browser.sendToExtension({name:"getPersistentValue",key:"changedHighlighterColor"}));var c=document.querySelector(".subtools.open");c&&c.classList.remove("open"),(a&&!a.noOpenSubtools||!a)&&this.classList.contains("expandable")&&window[this.id+"Subtools"].classList.add("open")}function handleSubtoolClick(){SHAPE_NAMES.indexOf(this.id)>-1?(DOMTokenList.prototype.remove.apply(shapesTool.classList,SHAPE_NAMES),shapesTool.classList.add(this.id),shapesTool.setAttribute("data-tool",this.id),shapesSubtools.classList.remove("open")):STAMP_NAMES.indexOf(this.id)>-1?(DOMTokenList.prototype.remove.apply(stampsTool.classList,STAMP_NAMES),stampsTool.classList.add(this.id),stampsTool.setAttribute("data-tool",this.id),Browser.sendToExtension({name:"setPersistentValue",key:"lastSkitchStamp",value:this.id}),stampsSubtools.classList.remove("open")):COLOR_NAMES.indexOf(this.id)>-1&&(DOMTokenList.prototype.remove.apply(colorsTool.classList,COLOR_NAMES),colorsTool.classList.add(this.id),colorsTool.setAttribute("data-tool",this.id),Browser.sendToExtension({name:"setPersistentValue",key:"lastSkitchColor",value:this.id}),colorsSubtools.classList.remove("open"),Browser.sendToExtension({name:"bounce",message:{name:"skitch_useColor",color:this.id}}),"highlighter"===document.getElementsByClassName("selectedSkitchTool")[0].id&&Browser.sendToExtension({name:"setPersistentValue",key:"changedHighlighterColor",value:!0})),COLOR_NAMES.indexOf(this.id)<0&&Browser.sendToExtension({name:"bounce",message:{name:"skitch_useTool",tool:this.id}})}function initialize(a){a.ssoRequired?document.body.classList.add("ssoRequired"):document.body.classList.remove("ssoRequired"),title.value=a.title.substr(0,EDAM_NOTE_TITLE_LEN_MAX),title.dispatchEvent(new CustomEvent("input"))}function openNotebook(){notebookSelector.open()}function openTags(){tagSelector.focus()}function reactivateClipperTool(){handleClipperToolClick.call(activeClipType)}function receiveAlwaysTags(a){for(var b=0;b<a.tags.length;b++)tagSelector.addTagAndClearInput(a.tags[b])}function receiveBusinessNotebooks(a){for(var b=0;b<a.notebooks.length;b++){var c=notebookSelector.addNotebook(a.notebooks[b]);a.notebooks[b].guid===a.recentNotebookGuid&&(recentNotebook=c),a.notebooks[b].guid===a.alwaysStartInNotebookGuid&&(alwaysStartInNotebook=c),smartFilingNotebookGuid&&a.notebooks[b].guid===smartFilingNotebookGuid&&(smartFilingNotebook=c)}receivedBusinessNotebooks=!0,receivedPersonalNotebooks&&receivedSharedNotebooks&&receivedSmartFilingInfo&&finishNotebookLoading()}function receiveBusinessTags(a){tagSelector.addBusinessTags(a.tags)}function receiveOption(a){if("clipAction"==a.key){var b=new RegExp("(?:"+document.body.className.replace(/\s+/,"|")+")");document.body.classList.contains("selection")?handleClipperToolClick.call(selection):document.body.classList.contains("email")?handleClipperToolClick.call(email):document.body.classList.contains("custom")?handleClipperToolClick.call(custom):"ARTICLE"==a.value&&b.test(article.className)?handleClipperToolClick.call(article):"CLEARLY"==a.value&&b.test(clearly.className)?handleClipperToolClick.call(clearly):"FULL_PAGE"==a.value&&b.test(fullPage.className)?handleClipperToolClick.call(fullPage):"URL"==a.value&&b.test(url.className)?handleClipperToolClick.call(url):"SKITCH"==a.value&&b.test(screenshot.className)?handleClipperToolClick.call(screenshot):b.test(pdf.className)?handleClipperToolClick.call(pdf):b.test(article.className)?handleClipperToolClick.call(article):b.test(fullPage.className)?handleClipperToolClick.call(fullPage):b.test(url.className)&&handleClipperToolClick.call(url)}}function receivePersistentValue(a){"lastSkitchStamp"===a.key?(a.value||(a.value="stampAccept"),stampsTool.classList.add(a.value),stampsTool.setAttribute("data-tool",a.value)):"lastSkitchColor"===a.key?(a.value||(a.value="pink"),colorsTool.classList.add(a.value),colorsTool.setAttribute("data-tool",a.value)):"changedHighlighterColor"===a.key&&(a.value?Browser.sendToExtension({name:"bounce",message:{name:"skitch_useColor",color:colorsTool.getAttribute("data-tool")}}):handleSubtoolClick.call(document.getElementById("yellow")))}function receivePersonalNotebooks(a){for(var b in a.notebooks){((a.notebooks[b].sharedNotebookIds?a.notebooks[b].sharedNotebookIds.length:0)>0||a.notebooks[b].published)&&(a.notebooks[b].visibleToOthers=!0);var c=notebookSelector.addNotebook(a.notebooks[b]);a.notebooks[b].defaultNotebook&&notebookSelector.select(c),a.notebooks[b].guid===a.recentNotebookGuid&&(recentNotebook=c),a.notebooks[b].guid===a.alwaysStartInNotebookGuid&&(alwaysStartInNotebook=c),smartFilingNotebookGuid&&a.notebooks[b].guid===smartFilingNotebookGuid&&(smartFilingNotebook=c)}receivedPersonalNotebooks=!0,receivedBusinessNotebooks&&receivedSharedNotebooks&&receivedSmartFilingInfo&&finishNotebookLoading()}function receivePersonalTags(a){tagSelector.addPersonalTags(a.tags)}function receiveSmartFilingInfo(a){if(a.notebook&&(smartFilingNotebookGuid=a.notebook.guid,smartFilingNotebook=notebookSelector.findNotebookByGuid(a.notebook.guid)),a.tags&&a.tags.list)for(var b=0;b<a.tags.list.length;b++)tagSelector.addTagAndClearInput(a.tags.list[b].name);receivedSmartFilingInfo=!0,receivedPersonalNotebooks&&receivedSharedNotebooks&&finishNotebookLoading()}function receiveSharedNotebooks(a){for(var b=0;b<a.notebooks.length;b++){var c=notebookSelector.addNotebook(a.notebooks[b]);a.notebooks[b].guid===a.recentNotebookGuid&&(recentNotebook=c),a.notebooks[b].guid===a.alwaysStartInNotebookGuid&&(alwaysStartInNotebook=c),smartFilingNotebookGuid&&a.notebooks[b].guid===smartFilingNotebookGuid&&(smartFilingNotebook=c)}receivedSharedNotebooks=!0,receivedPersonalNotebooks&&receivedBusinessNotebooks&&receivedSmartFilingInfo&&finishNotebookLoading()}function save(){var a=notebookSelector.getSelected(),b=!1;if(smartFilingNotebook&&a.guid!==smartFilingNotebookGuid){var c=GlobalUtils.NOTEBOOK_TYPE_PERSONAL;smartFilingNotebook.classList.contains("nbBusinessNotebook")?c=GlobalUtils.NOTEBOOK_TYPE_BUSINESS:smartFilingNotebook.classList.contains("nbLinkedNotebook")&&(c=GlobalUtils.NOTEBOOK_TYPE_LINKED),b={from:{type:c},to:{defaultNotebook:a.defaultNotebook,recentNotebook:recentNotebook?recentNotebook.getAttribute("guid")===a.guid:!1,type:a.type}}}Browser.sendToExtension({name:"bounce",message:{name:"startSubmission",clipType:activeClipType.id,title:title.value,notebook:a,tags:tagSelector.getTags(),comment:comments.value,changedSmartFilingNotebook:b,smartFilingNotebookAvailable:!!smartFilingNotebook,userSelectedNotebook:userSelectedNotebook}})}function setHeight(){var a=main.offsetHeight,b=(main.offsetHeight-main.clientHeight)/2,c=notebookSelector?notebookSelector.height-(a-notebook.offsetTop-b):0,d=tagSelector?tagSelector.height-(a-tags.offsetTop-b):0;Browser.sendToExtension({name:"bounce",message:{name:"setGlobalToolsHeight",height:a+Math.max(Math.max(c,d),0)}})}function setKeyboardHandlers(a){if(shortcutsEnabled=a.enabled,a.handlers){var b={};for(var c in a.handlers)for(var d=0;d<a.handlers[c].length;d++)b[a.handlers[c][d]]=["expandArticleShortcut","contractArticleShortcut","moveArticleUpShortcut","moveArticleDownShortcut"].indexOf(c)>-1?function(a,b){"function"==typeof shortcutHandlers[a]&&["INPUT","TEXTAREA"].indexOf(b.nodeName)<0&&"true"!==b.contentEditable&&shortcutHandlers[a](a,b)}:function(a,b){shortcutsEnabled&&"function"==typeof shortcutHandlers[a]&&["INPUT","TEXTAREA"].indexOf(b.nodeName)<0&&"true"!==b.contentEditable&&shortcutHandlers[a](a,b)},"closeWebClipperShortcut"===c?(shortcutHandlers[a.handlers[c][d]]=function(a){handleEscape({keycode:a})},b[a.handlers[c][d]]=function(a,b){"function"==typeof shortcutHandlers[a]&&shortcutHandlers[a](a,b)}):shortcutHandlers[a.handlers[c][d]]="previewArticleShortcut"===c?function(){useClipType({clipType:"article"})}:"previewFullPageShortcut"===c?function(){useClipType({clipType:"fullPage"})}:"previewUrlShortcut"===c?function(){useClipType({clipType:"url"})}:"selectionModeShortcut"===c?function(){useClipType({clipType:"selection"})}:"takeScreenshotShortcut"===c?function(){useClipType({clipType:"screenshot"})}:"clearlyShortcut"===c?function(){useClipType({clipType:"clearly"})}:"pdfShortcut"===c?function(){useClipType({clipType:"pdf"})}:"emailShortcut"===c?function(){useClipType({clipType:"email"})}:"selectNotebookShortcut"===c?openNotebook:"addTagsShortcut"===c?openTags:"saveShortcut"===c?save:"arrowShortcut"===c?function(){useSkitchTool({tool:"shapes",subtool:"arrow"})}:"textShortcut"===c?function(){useSkitchTool({tool:"text"})}:"rectangleShortcut"===c?function(){useSkitchTool({tool:"shapes",subtool:"rectangle"})}:"roundedRectangleShortcut"===c?function(){useSkitchTool({tool:"shapes",subtool:"roundedRectangle"})}:"ellipseShortcut"===c?function(){useSkitchTool({tool:"shapes",subtool:"ellipse"})}:"lineShortcut"===c?function(){useSkitchTool({tool:"shapes",subtool:"line"})}:"markerShortcut"===c?function(){useSkitchTool({tool:"marker"})}:"highlighterShortcut"===c?function(){useSkitchTool({tool:"highlighter"})}:"stampShortcut"===c?function(){useSkitchTool({tool:"stamps"})}:"pixelateShortcut"===c?function(){useSkitchTool({tool:"pixelate"})}:"cropShortcut"===c?function(){useSkitchTool({tool:"crop"})}:function(a){Browser.sendToExtension({name:"bounce",message:{name:"duplicateKeyboardShortcut",keycode:a}})};Browser.addKeyboardHandlers(b)}}function setPossibleClipTypes(a){a.pageInfo.pdf?document.body.classList.add("pdf"):a.pageInfo.gmailThread?document.body.classList.add("email"):a.pageInfo.documentIsFrameset?document.body.classList.add("frameset"):a.pageInfo.custom?(document.body.classList.add("custom"),custom.textContent=Browser.i18n.getMessage(a.pageInfo.custom)):document.body.classList.add("html"),a.pageInfo.selection&&document.body.classList.add("selection"),setHeight()}function skitchSurfaceReady(){document.body.classList.add("skitchReady"),handleSkitchToolClick.call(shapesTool,{noOpenSubtools:!0}),Browser.sendToExtension({name:"bounce",message:{name:"skitch_useColor",color:colorsTool.getAttribute("data-tool")}}),setHeight()}function startingNotebookAllowed(a){return!(document.body.classList.contains("email")&&a.hasAttribute("visibleToOthers"))}function updateUser(a){a.ssoRequired?document.body.classList.add("ssoRequired"):document.body.classList.remove("ssoRequired"),receivedPersonalNotebooks=!1,receivedSharedNotebooks=!1,receivedSmartFilingInfo=!1,userSelectedNotebook=!1,notebookSelector.markStatus(!1),notebookSelector.reset(),tagSelector.reset(),Browser.sendToExtension({name:"getNotebooks"}),Browser.sendToExtension({name:"getTags"})}function useClipType(a){if(!document.body.classList.contains("skitchReady")){var b=new RegExp("(?:"+document.body.className.replace(/\s+/,"|")+")");b.test(window[a.clipType].className)&&handleClipperToolClick.call(window[a.clipType])}}function useSkitchTool(a){document.body.classList.contains("skitchReady")&&(handleSkitchToolClick.call(document.getElementById(a.tool),{charCode:a.charCode,loc:a.loc,noOpenSubtools:!0}),a.subtool&&handleSubtoolClick.call(document.getElementById(a.subtool)))}var SHAPE_NAMES=["arrow","rectangle","roundedRectangle","ellipse","line"],STAMP_NAMES=["stampAccept","stampReject","stampExclaim","stampQuestion","stampPerfect"],COLOR_NAMES=["red","orange","yellow","black","green","blue","pink","white"],receivedPersonalNotebooks=!1,receivedBusinessNotebooks=!1,receivedSharedNotebooks=!1,receivedSmartFilingInfo=!1,userSelectedNotebook=!1,shortcutsEnabled=!0,main,closeSidebar,title,saveButton,cancelScreenshotButton,article,clearly,custom,fullPage,selection,pdf,email,url,screenshot,activeClipType,notebook,notebookSelector,tags,tagSelector,comments,shapesTool,shapesSubtools,stampsTool,stampsSubtools,colorsTool,colorsSubtools,settings,sso,recentNotebook,alwaysStartInNotebook,smartFilingNotebook,smartFilingNotebookGuid,shortcutHandlers={};window.addEventListener("DOMContentLoaded",function(){main=document.getElementById("main"),closeSidebar=document.getElementById("closeSidebar"),title=document.getElementById("title"),saveButton=document.getElementById("saveButton"),cancelScreenshotButton=document.getElementById("cancelScreenshot"),article=document.getElementById("article"),clearly=document.getElementById("clearly"),custom=document.getElementById("custom"),fullPage=document.getElementById("fullPage"),selection=document.getElementById("selection"),pdf=document.getElementById("pdf"),email=document.getElementById("email"),url=document.getElementById("url"),screenshot=document.getElementById("screenshot"),activeClipType=null,notebook=document.getElementById("notebook"),tags=document.getElementById("tags"),comments=document.getElementById("comments"),shapesTool=document.getElementById("shapes"),stampsTool=document.getElementById("stamps"),colorsTool=document.getElementById("colors"),shapesSubtools=document.getElementById("shapesSubtools"),stampsSubtools=document.getElementById("stampsSubtools"),colorsSubtools=document.getElementById("colorsSubtools"),settings=document.getElementById("settings"),sso=document.getElementById("sso"),GlobalUtils.localize(document.body),title.placeholder=Browser.i18n.getMessage("quickNote_untitledNote"),comments.placeholder=Browser.i18n.getMessage("quickNote_addComment");for(var a=document.querySelectorAll("#clip h2"),b=0;b<a.length;b++)a.item(b).addEventListener("click",handleClipperToolClick);title.addEventListener("input",function(){title.value=title.value.replace(/[\n\r]/g,""),title.rows="1",title.scrollHeight>title.clientHeight&&(title.rows="2"),setHeight()}),title.addEventListener("blur",function(){title.scrollTop=0}),title.maxLength=EDAM_NOTE_TITLE_LEN_MAX,notebookSelector=new NotebookSelector(notebook,function(a){a.notebookType&&tagSelector.setActiveTrie(a.notebookType),a.userSelected&&(userSelectedNotebook=!0)},setHeight),notebookSelector.markStatus(!1),Browser.sendToExtension({name:"getNotebooks"}),tagSelector=new TagSelector(tags,setHeight,setHeight),Browser.sendToExtension({name:"getTags"}),comments.addEventListener("input",function(){comments.rows="1",comments.scrollHeight>comments.clientHeight&&(comments.rows="2"),setHeight()}),comments.addEventListener("blur",function(){comments.scrollTop=0});for(var c=document.getElementsByClassName("skitchTool"),b=0;b<c.length;b++)c[b].addEventListener("click",handleSkitchToolClick),"highlighter"==c[b].id?c[b].title=Browser.i18n.getMessage("imageHighlighter"):"shapes"==c[b].id?c[b].title=Browser.i18n.getMessage("shapeTool"):"marker"==c[b].id?c[b].title=Browser.i18n.getMessage("markerTool"):"crop"==c[b].id?c[b].title=Browser.i18n.getMessage("crop"):"zoomout"==c[b].id?c[b].title=Browser.i18n.getMessage("zoomout"):"stamps"==c[b].id?c[b].title=Browser.i18n.getMessage("stampTool"):"text"==c[b].id?c[b].title=Browser.i18n.getMessage("typeTool"):"pixelate"==c[b].id?c[b].title=Browser.i18n.getMessage("pixelatorTool"):"colors"==c[b].id?c[b].title=Browser.i18n.getMessage("colors"):"zoomin"==c[b].id&&(c[b].title=Browser.i18n.getMessage("zoomin"));for(var d=document.getElementsByClassName("subtool"),b=0;b<d.length;b++)d[b].addEventListener("click",handleSubtoolClick);cancelScreenshotButton.addEventListener("click",function(){document.body.classList.remove("skitchWaiting","skitchReady");var a=new RegExp("(?:"+document.body.className.replace(/\s+/,"|")+")");a.test(article.className)?handleClipperToolClick.call(article):a.test(clearly.className)?handleClipperToolClick.call(clearly):a.test(fullPage.className)?handleClipperToolClick.call(fullPage):a.test(pdf.className)?handleClipperToolClick.call(pdf):a.test(email.className)?handleClipperToolClick.call(email):a.test(selection.className)?handleClipperToolClick.call(selection):a.test(url.className)&&handleClipperToolClick.call(url),setHeight()}),Browser.sendToExtension({name:"getPersistentValue",key:"lastSkitchColor"}),Browser.sendToExtension({name:"getPersistentValue",key:"lastSkitchStamp"}),closeSidebar.addEventListener("click",function(){Browser.sendToExtension({name:"bounce",message:{name:"closeClipper",notClipping:!0}})}),saveButton.addEventListener("click",save),settings.addEventListener("click",function(){Browser.sendToExtension({name:"bounce",message:{name:"showOptions"}})}),sso.addEventListener("click",function(){Browser.sendToExtension({name:"openSSOPage"}),Browser.sendToExtension({name:"bounce",message:{name:"showSSOProgressTooltip"}})}),window.addEventListener("keydown",function(a){9===a.keyCode&&notebookSelector.contains(document.activeElement)&&notebookSelector.close()}),setHeight()}),Browser.addMessageHandlers({gt_handleEscape:handleEscape,gt_initialize:initialize,gt_openNotebook:openNotebook,gt_openTags:openTags,gt_reactivateClipperTool:reactivateClipperTool,gt_save:save,gt_setKeyboardHandlers:setKeyboardHandlers,gt_setPossibleClipTypes:setPossibleClipTypes,gt_updateUser:updateUser,gt_useClipType:useClipType,gt_useSkitchTool:useSkitchTool,receiveAlwaysTags:receiveAlwaysTags,receiveBusinessNotebooks:receiveBusinessNotebooks,receiveBusinessTags:receiveBusinessTags,receiveOption:receiveOption,receivePersistentValue:receivePersistentValue,receivePersonalNotebooks:receivePersonalNotebooks,receivePersonalTags:receivePersonalTags,receiveSharedNotebooks:receiveSharedNotebooks,receiveSmartFilingInfo:receiveSmartFilingInfo,skitchSurfaceReady:skitchSurfaceReady});