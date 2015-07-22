window.addEventListener("load", function() {
	i18n.process(document)
	if (localStorage.getItem("WriteSpaceEditorWidth")) {
		document.querySelector("html").style.minWidth = localStorage.getItem("WriteSpaceEditorWidth") + "px";
		document.querySelector("p").style.width = localStorage.getItem("WriteSpaceEditorWidth") + "px";
	}
	if (localStorage.getItem("WriteSpaceVerticalPadding")) {
		document.querySelector("section").style.paddingTop = localStorage.getItem("WriteSpaceVerticalPadding") + "px";
		document.querySelector("section").style.paddingBottom = localStorage.getItem("WriteSpaceVerticalPadding") + "px";
	}
	if (localStorage.getItem("WriteSpaceBackgroundColor")) {
		document.querySelector("html").style.background = localStorage.getItem("WriteSpaceBackgroundColor");
		document.querySelector("textarea").style.background = localStorage.getItem("WriteSpaceBackgroundColor");
	}
	if (localStorage.getItem("WriteSpaceFontColor")) {
		document.querySelector("textarea").style.color = localStorage.getItem("WriteSpaceFontColor");
	}
	if (localStorage.getItem("WriteSpaceFontFamily")) {
		document.querySelector("textarea").style.fontFamily = localStorage.getItem("WriteSpaceFontFamily");
		document.querySelector("p").style.fontFamily = localStorage.getItem("WriteSpaceFontFamily");
	}
	if (localStorage.getItem("WriteSpaceFontSize")) {
		document.querySelector("textarea").style.fontSize = localStorage.getItem("WriteSpaceFontSize") + "pt";
		document.querySelector("p").style.fontSize = localStorage.getItem("WriteSpaceFontSize") * 0.89 + "pt";
	}
	if (localStorage.getItem("WriteSpaceLineHeight")) {
		document.querySelector("textarea").style.lineHeight = localStorage.getItem("WriteSpaceLineHeight") + "em";
	}
	if (localStorage.getItem("WriteSpaceDisplayFooter") == "false") {
		document.querySelector("footer").style.display = "none";
	}
	if (localStorage.getItem("WriteSpaceFooterColor")) {
		document.querySelector("footer").style.background = localStorage.getItem("WriteSpaceFooterColor");
	}
	if (localStorage.getItem("WriteSpaceFooterText")) {
		document.querySelector("p").style.color = localStorage.getItem("WriteSpaceFooterText");
	}
	if (localStorage.getItem("WriteSpaceEnableSpellcheck") == "false") {
		document.querySelector("textarea").spellcheck = false;
	} else {
		document.querySelector("textarea").spellcheck = true;
	};
	drawWindow()
	if (localStorage.getItem("WriteSpaceData")) {
		document.querySelector("textarea").value = localStorage.getItem("WriteSpaceData");
	}
	document.querySelector("textarea").focus();
	if (localStorage.getItem("WriteSpaceCaretPosition")) {
		document.querySelector("textarea").selectionStart = localStorage.getItem("WriteSpaceCaretPosition");
	}
	if (localStorage.getItem("WriteSpaceScrollPosition")) {
		document.querySelector("textarea").scrollTop = localStorage.getItem("WriteSpaceScrollPosition");
	}
	if (localStorage.getItem("WriteSpaceDisplayFooter") !== "false") {
		drawStatistics();
	}
	if (localStorage.getItem("WriteSpaceDisplayFooter") !== "false") {
		document.querySelector("textarea").addEventListener("keyup", function() {
			localStorage.setItem("WriteSpaceData", document.querySelector("textarea").value);
			localStorage.setItem("WriteSpaceCaretPosition", document.querySelector("textarea").selectionStart);
			drawStatistics();
		}, false)
	} else {
		document.querySelector("textarea").addEventListener("keyup", function() {
			localStorage.setItem("WriteSpaceData", document.querySelector("textarea").value);
			localStorage.setItem("WriteSpaceCaretPosition", document.querySelector("textarea").selectionStart);
		}, false)
	}
	document.querySelector("textarea").addEventListener("click", function() {
		localStorage.setItem("WriteSpaceCaretPosition", document.querySelector("textarea").selectionStart);
	}, false)
	document.querySelector("textarea").addEventListener("scroll", function() {
		localStorage.setItem("WriteSpaceScrollPosition", document.querySelector("textarea").scrollTop);
	}, false)
}, false)
window.addEventListener("resize", function() {
	drawWindow();
}, false);
window.addEventListener("keydown", function(e){
	if (e.which == 112) {
		e.preventDefault();
		alert("Write Space (0.60)\nCopyright © 2011, Haydn Trowell\nAll rights reserved.\n\nThis software is provided by the copyright holders and contributors “as is” and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed. In no event shall the copyright owner or contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this software, even if advised of the possibility of such damage.");
	};
	if (e.keyCode == 9) {
		e.preventDefault();
		var t = e.target;
		var ss = t.selectionStart;
		var se = t.selectionEnd;
		t.value = t.value.slice(0, ss).concat("\t").concat(t.value.slice(ss, t.value.length));
		if (ss == se) {
			t.selectionStart = t.selectionEnd = ss + 1;
		}
		else {
			t.selectionStart = ss + 1;
			t.selectionEnd = se + 1;
		};
	};
}, false);
function drawWindow() {
	document.querySelector("section").style.height = window.innerHeight - document.querySelector("footer").offsetHeight + "px";
	if (window.localStorage.getItem("WriteSpaceEditorWidth")) {
		document.querySelector("textarea").style.paddingLeft = window.innerWidth / 2 - window.localStorage.getItem("WriteSpaceEditorWidth") / 2 + "px";
		document.querySelector("textarea").style.paddingRight = window.innerWidth / 2 - window.localStorage.getItem("WriteSpaceEditorWidth") / 2 + "px";
	}
	else {
		document.querySelector("textarea").style.paddingLeft = window.innerWidth / 2 - 660 / 2 + "px";
		document.querySelector("textarea").style.paddingRight = window.innerWidth / 2 - 660 / 2 + "px";
	};
};
function drawStatistics() {
	document.querySelector("#wordcount").innerHTML = addCommas(document.querySelector("textarea").value.split(/\S+/g).length - 1);
	document.querySelector("#linecount").innerHTML = addCommas(document.querySelector("textarea").value.split(/\n/).length);
	document.querySelector("#charactercount").innerHTML = addCommas(document.querySelector("textarea").value.length);
};
function addCommas(nStr) {
	nStr += "";
	x1 = nStr.split(".");
	x2 = x1[0];
	x3 = x1.length > 1 ? "." + x1[1] : "";
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x2)) {
		x2 = x2.replace(rgx, "$1" + "," + "$2");
	};
	return x2 + x3;
};
