window.addEventListener("load", function() {
	i18n.process(document);
	if (localStorage.getItem("WriteSpaceEditorWidth")) {
		document.querySelector("#editorWidth").value = localStorage.getItem("WriteSpaceEditorWidth");
	};
	if (localStorage.getItem("WriteSpaceVerticalPadding")) {
		document.querySelector("#verticalPadding").value = localStorage.getItem("WriteSpaceVerticalPadding");
	};
	if (localStorage.getItem("WriteSpaceBackgroundColor")) {
		document.querySelector("#backgroundColor").value = localStorage.getItem("WriteSpaceBackgroundColor");
	};
	if (localStorage.getItem("WriteSpaceFontColor")) {
		document.querySelector("#fontColor").value = localStorage.getItem("WriteSpaceFontColor");
	};
	if (localStorage.getItem("WriteSpaceFontFamily")) {
		document.querySelector("#fontFamily").value = localStorage.getItem("WriteSpaceFontFamily");
	};
	if (localStorage.getItem("WriteSpaceFontSize")) {
		document.querySelector("#fontSize").value = localStorage.getItem("WriteSpaceFontSize");
	};
	if (localStorage.getItem("WriteSpaceLineHeight")) {
		document.querySelector("#lineHeight").value = localStorage.getItem("WriteSpaceLineHeight");
	};
	if (localStorage.getItem("WriteSpaceDisplayFooter") == "false") {
		document.querySelector("#displayFooter").checked = false;
	};
	if (localStorage.getItem("WriteSpaceFooterColor")) {
		document.querySelector("#footerColor").value = localStorage.getItem("WriteSpaceFooterColor");
	};
	if (localStorage.getItem("WriteSpaceFooterText")) {
		document.querySelector("#footerText").value = localStorage.getItem("WriteSpaceFooterText");
	};
	if (localStorage.getItem("WriteSpaceEnableSpellcheck") == "false") {
		document.querySelector("#enableSpellcheck").checked = false;
	};
	document.querySelector("#savebutton").disabled = true;
	document.querySelector("#section-editor").style.display = "block";
	document.querySelector("#section-editor-button").setAttribute("class", "current");
}, false);
function save() {
	localStorage.setItem("WriteSpaceEditorWidth", document.querySelector("#editorWidth").value);
	localStorage.setItem("WriteSpaceVerticalPadding", document.querySelector("#verticalPadding").value);
	localStorage.setItem("WriteSpaceBackgroundColor", document.querySelector("#backgroundColor").value);
	localStorage.setItem("WriteSpaceFontColor", document.querySelector("#fontColor").value);
	localStorage.setItem("WriteSpaceFontFamily", document.querySelector("#fontFamily").value);
	localStorage.setItem("WriteSpaceFontSize", document.querySelector("#fontSize").value);
	localStorage.setItem("WriteSpaceLineHeight", document.querySelector("#lineHeight").value);
	localStorage.setItem("WriteSpaceDisplayFooter", document.querySelector("#displayFooter").checked);
	localStorage.setItem("WriteSpaceFooterColor", document.querySelector("#footerColor").value);
	localStorage.setItem("WriteSpaceFooterText", document.querySelector("#footerText").value);
	localStorage.setItem("WriteSpaceEnableSpellcheck", document.querySelector("#enableSpellcheck").checked);
	document.querySelector("#savebutton").disabled = true;
	reload();
};
function reset() {
	localStorage.removeItem("WriteSpaceEditorWidth");
	localStorage.removeItem("WriteSpaceVerticalPadding");
	localStorage.removeItem("WriteSpaceBackgroundColor");
	localStorage.removeItem("WriteSpaceFontColor");
	localStorage.removeItem("WriteSpaceFontFamily");
	localStorage.removeItem("WriteSpaceFontSize");
	localStorage.removeItem("WriteSpaceLineHeight");
	localStorage.removeItem("WriteSpaceDisplayFooter");
	localStorage.removeItem("WriteSpaceFooterColor");
	localStorage.removeItem("WriteSpaceFooterText");
	localStorage.removeItem("WriteSpaceEnableSpellcheck");
	document.querySelector("#editorWidth").value = "660";
	document.querySelector("#verticalPadding").value = "0";
	document.querySelector("#backgroundColor").value = "#000000";
	document.querySelector("#fontColor").value = "#B9B9B9";
	document.querySelector("#fontFamily").value = "monospace";
	document.querySelector("#fontSize").value = "12";
	document.querySelector("#lineHeight").value = "1.5";
	document.querySelector("#displayFooter").checked = true;
	document.querySelector("#footerColor").value = "#171717";
	document.querySelector("#footerText").value = "#7F7F7F";
	document.querySelector("#enableSpellcheck").checked = true;
	reload();
	document.querySelector("#savebutton").disabled = true;
};
function reload() {
	var views = chrome.extension.getViews();
	for (var i in views) {
		var location = views[i].location;
		if (location.pathname == "/xhtml/application.xhtml") {
			location.reload();
		};
	};
};
function mark() {
	document.querySelector("#savebutton").disabled = false;
};
function importdata(files) {
	var r = confirm(chrome.i18n.getMessage("importwarning"));
	if (r == true) {
		for (i = 0; i < files.length; i++) {
			file = files[i];
			console.log(file);
			var reader = new FileReader();
			ret = [];
			reader.onload = function (e) {
				window.localStorage.setItem("WriteSpaceData", e.target.result);
			};
			reader.readAsText(file);
			reader.onerror = function error(evt) {
				alert(chrome.i18n.getMessage("importfail") + evt);
			};
		};
		localStorage.removeItem("WriteSpaceCaretPosition");
		localStorage.removeItem("WriteSpaceScrollPosition");
		reload();
	};
	document.querySelector("#importbutton").value="";
};
function exportdata() {
	var bb = new BlobBuilder();
	bb.append(localStorage.getItem("WriteSpaceData"));
	window.saveAs(bb.getBlob(), "untitled.txt");
};
