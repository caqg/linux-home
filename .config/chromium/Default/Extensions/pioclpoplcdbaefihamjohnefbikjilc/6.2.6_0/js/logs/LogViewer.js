function LogViewer(){function d(){var b=document.getElementById(e).selectedIndex;-1!=b&&f.getLog(b,k)}function k(b){var a=document.createElement("pre");a.textContent=b;document.getElementById(g).innerHTML="";document.getElementById(g).appendChild(a);document.getElementById(h).checked&&scroll(0,document.body.offsetHeight)}function l(b){var a=document.createElement("a");a.href=window.webkitURL.createObjectURL(new Blob([b]));a.download="evernote_web_clipper_logs.txt";a.click()}var e="logSelector",h=
"logFollow",g="logViewer";GlobalUtils.localize(document.body);GlobalUtils.localize(document.getElementsByTagName("title")[0]);var c=0;document.getElementById(e).addEventListener("change",d);document.getElementById(h).addEventListener("change",function(){c&&(clearInterval(c),c=0);this.checked&&(c=setInterval(d,2E3))});document.getElementById("exportButton").addEventListener("click",function(){f.startExportLogs(l)});var f=new LogReader(/type=([^&$]+)/.test(location.hash)?/type=([^&$]+)/.exec(location.hash)[1]:
null,function(){for(var b=f.getLogsProperties(["name"]),a=0;a<b.length;a++){var c=document.createElement("option");c.value=b[a].name;c.textContent=b[a].name;document.getElementById(e).appendChild(c)}d()});Object.preventExtensions(this)}Object.preventExtensions(LogViewer);window.addEventListener("error",function(d){log.error(JSON.stringify(d))});var logViewer=null;document.addEventListener("DOMContentLoaded",function(){logViewer=new LogViewer});