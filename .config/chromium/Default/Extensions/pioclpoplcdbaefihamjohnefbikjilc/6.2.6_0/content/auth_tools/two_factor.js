var logo,closeButton,cancel,explanation,code,continueButton,help,auth,expiration,background=Browser.extension.getBackgroundPage().extension,baseUrl=background.getOption("secureProto")+background.getBootstrapInfo("serviceHost");function clearError(a){a.className=a.className.replace(/\s*error/g,"");a.nextElementSibling.removeAttribute("data-error")}
function goBackToLogin(a){window.location.href=Browser.extension.getURL("content/auth_tools/login.html"+("string"==typeof a?"?globalError="+encodeURIComponent(a):""))}
function msgHandlerTwoStepResponse(a,c,b){"INVALID_TWO_STEP_CODE"==a.error?setError(code,Browser.i18n.getMessage("incorrectCode")):"EXPIRED_AUTHENTICATION_TOKEN"==a.error?goBackToLogin(Browser.i18n.getMessage("expiredTwoStepCode")):a.error?log.error("error with two step response: ",+a.error):a.sso?(background.trackEvent({category:"Account",action:"sign_in",label:"sso_needed",data:background.generateUserCustomDimensions()}),window.location.href="content/auth_tools/sso.html?bizName="+encodeURIComponent(a.bizName)):
(background.trackEvent({category:"Account",action:"sign_in",label:"completed",data:background.generateUserCustomDimensions()}),Browser.getCurrentTab(function(a){background.toggleClipper(null,{tab:a});closePopup()}))}function setError(a,c){a.className+=" error";a.nextElementSibling.setAttribute("data-error",c)}
function setupTFa(){explanation.innerText=Browser.i18n.getMessage("gaMessage");for(var a=window.location.search.substr(1).split("&"),c=0;c<a.length;c++){var b=a[c].split("=");b[1]=decodeURIComponent(b[1]);switch(b[0]){case "auth":auth=b[1];help.addEventListener("click",function(){new Date>expiration?goBackToLogin(Browser.i18n.getMessage("expiredTwoStepCode")):(background.msgHandlerOpenTab({url:baseUrl+"/TwoStepHelp.action?auth="+encodeURIComponent(auth)}),closePopup())});break;case "expiration":expiration=
b[1];break;case "sms":explanation.innerText=Browser.i18n.getMessage("smsMessage",[b[1]])}}/china/i.test(background.getBootstrapInfo("name"))?logo.className+=" china":logo.className=logo.className.replace(/\s*china/g,"")}
function submitCode(){var a=code.value.replace(/-/g,"");new Date>expiration?goBackToLogin(Browser.i18n.getMessage("expiredTwoStepCode")):/^(\d{6}|\d{16})$/.test(a)?background.msgHandlerSubmitTwoStepCode({auth:auth,code:a},null,msgHandlerTwoStepResponse):setError(code,Browser.i18n.getMessage("incorrectCode"))}
window.addEventListener("DOMContentLoaded",function(){logo=document.querySelector("#logo");closeButton=document.querySelector("#close");cancel=document.querySelector("#cancel");explanation=document.querySelector("#explanation");code=document.querySelector("#code");continueButton=document.querySelector("#continue");help=document.querySelector("#help");GlobalUtils.localize(document.body);code.placeholder=Browser.i18n.getMessage("sixDigitCode");logo.addEventListener("click",function(){background.msgHandlerOpenTab({url:baseUrl+
"/Home.action"})});closeButton.addEventListener("click",closePopup);closeButton.addEventListener("keypress",function(a){13==a.keyCode&&closePopup()});cancel.addEventListener("click",goBackToLogin);cancel.addEventListener("keypress",function(a){13==a.keyCode&&goBackToLogin()});code.addEventListener("keypress",function(a){13==a.keyCode&&submitCode()});code.addEventListener("input",function(){clearError(code)});continueButton.addEventListener("click",submitCode);continueButton.addEventListener("keypress",
function(a){13==a.keyCode&&submitCode()});setupTFa()});