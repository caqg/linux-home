/*! Copyright 2009-2015 Evernote Corporation. All rights reserved. */
reqC(["topFrame!checkSimSearch!"],function(a){function b(a){if(a){var b=document.createElement("link");b.type="text/css",b.rel="stylesheet",b.href=Browser.extension.getURL("css/"+a),document.head.appendChild(b)}}function c(a){if("string"==typeof a)return document.querySelector(a);for(var b=0;b<a.length;b++){var c=document.querySelector(a[b]);if(c)return c}return null}function d(){return c(u[a].insertBefore)}function e(a){a&&a.auth&&a.auth.username?(r=a.auth,i(!0)):i(!1)}function f(b){o=b.options,p=b.bootstrapInfo,q=o.secureProto+p.serviceHost,("Google"!=a||"Google"==a&&document.getElementById("ires"))&&g()}function g(){clearTimeout(s),s=setTimeout(function(){o.useSearchHelper&&t&&Browser.sendToExtension({name:"main_isAuthenticated",type:"simSearch"})},300)}function h(){var b=u[a].queryParam,c=document.querySelector("input[name='"+b+"']");return c.value&&""!=c.value.trim()?!0:!1}function i(a){var b=document.getElementById("evernoteSimSearchResults");if((!b||b.getAttribute("extension")==Browser.i18n.getMessage("@@extension_id"))&&(n&&n.parentNode&&n.parentNode.removeChild(n),h())){n=document.createElement("iframe");var c="content/sim_search_results.html?locale="+p.name+"&baseUrl="+q;a&&(c+="&userId="+r.userId+"&shardId="+r.shardId),n.id="evernoteSimSearchResults",n.setAttribute("extension",Browser.i18n.getMessage("@@extension_id"));var e=d();e&&e.parentNode&&(e.parentNode.insertBefore(n,e),n.src=Browser.extension.getURL(c),l())}}function j(a){if(!a)return!1;var b=document.querySelector("link[href='"+Browser.extension.getURL("css/"+a)+"']");return!!b}function k(a){n.style.height=a.height+"px",0==a.height?(n.style.display="none",n.parentNode.removeChild(n)):n.style.display="block"}function l(){var a=document.getElementById("evernoteSimSearchResults"),b=document.getElementById("rhs");a&&b&&(a.style.width=Math.min(Math.max(window.innerWidth-b.offsetLeft-30,280),456)+"px")}function m(){t=!1}var n,o,p,q,r,s,t=!0,u={Baidu:{queryParam:"wd",insertBefore:[".c-container"]},Bing:{queryParam:"q",insertBefore:["#results","#b_results .b_algo"]},Daum:{css:"daumsearchhelper.css",queryParam:"q",insertBefore:["#splinkColl+div+hr+[id$='Coll']","#mArticle [id$='Coll']","#noResult"]},Google:{queryParam:"q",insertBefore:["#rhs_block"]},Naver:{queryParam:"query",insertBefore:[".section:not(.ad_power) > .section_head","#notfound p"]},Yahoo:{queryParam:"p",insertBefore:["#web"]},YahooJP:{queryParam:"p",insertBefore:["#WS2m","#WS2al p"]},Yandex:{css:"yandexrusearchhelper.css",queryParam:"text",insertBefore:[".serp-list"]}},v="searchhelper.css";b(v),b(u[a].css),setInterval(function(){j(v)||b(v),j(u[a].css)||b(u[a].css)},1e3),Browser.addMessageHandlers({simSearch_isAuthenticated:e,simSearch_sendHeight:k,temporarilyDisableSimSearch:m,config:f}),["Google","Bing","Baidu","Yandex"].indexOf(a)>-1?(document.addEventListener("webkitAnimationStart",function(a){a&&"simSearch"===a.animationName&&g()}),"Google"==a&&window.addEventListener("resize",l)):window.addEventListener("hashchange",function(){g()}),Browser.sendToExtension({name:"main_getConfig",options:{secureProto:null,useSearchHelper:null},bootstrapInfo:{serviceHost:null,name:null}})});