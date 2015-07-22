var PADDING_FULLSCREEN = 10;

function WriteboxUI() {
	this.settings = null;
	
}


WriteboxUI.prototype.init = function(settings) {
	var self = this;
	self.settings = settings;

  self.layout();
  $(window).resize(function() {
    self.layout();
  });

  addEventListener();
};

/**
 * layout
 */
WriteboxUI.prototype.layout = function(settingWidth) {
  settingWidth = parseInt(settingWidth) || 800;
  var winWidth = $(window).width(),
      winHeight = $(window).height();

  // EditorWindow
  var width = 0, padding = 0, previewTop;
  if (winWidth < 800) {
    if (settingWidth < winWidth) {
      width = settingWidth;
      padding = (winWidth / 2) - (width / 2) + PADDING_FULLSCREEN;
    } else {
      width = winWidth - PADDING_FULLSCREEN * 2;
      padding = PADDING_FULLSCREEN;
    }
  } else {
    width = settingWidth;
    padding = (winWidth / 2) - (width / 2);
  }
  previewTop = $('#editor').position().top;;

  $('#editor')
    .css("margin-left", padding)
    .css("padding-right", padding)
    .width(width + padding);

  if ($(window).width() < 800) {
    $('#editor-footer, #header > #menu, .slidedown-bar > .container')
      .css("margin-left", 0)
      .css("padding-right", 0)
      .width(width + padding*2);
  } else {
    $('#editor-footer, #header > #menu, .slidedown-bar > .container')
      .css("margin-left", padding)
      .css("padding-right", padding)
      .width(width + padding);        
  }

  // Preview window
  $("#markdown-preview-window")
    .css('position', 'absolute')
    .css('top', previewTop)
    .css('left', $('#editor').position().left + padding)
    .css('width', $('#editor').width() + padding)
    .css('height', winHeight - previewTop);

  $("#preview")
    .css('padding-right', padding)
    .css('overflow-x', 'hidden')
    .css('height', winHeight - previewTop);
};

WriteboxUI.prototype.addEventListener = function() {
  var self = this;

  self.settings.addEventListener('changedSetting', function(data) {
    switch (data.settingName) {
      case 'fontSize':
        self.setFontSize(data.value);
        break;
      case 'fontFamily':
        self.setFontFamily(data.value);
        break;
      case 'textColor':
        self.setTextColor(data.value);
        break;
      case 'backgroundColor':
        self.setBackgroundColor(data.value);
        break;
      case 'width':
        self.setEditorWidth(data.value);
        break;
      case 'lineHeight':
        self.setLineHeight(data.value);
        break;
      case 'showStatistics':
        self.setStatisticsVisible(data.value);
        break;
      case 'showScrollbar':
        self.setScrollbarVisible(data.value);
        break;
    }
  });
};


WriteboxUI.prototype.setFontSize = function(fontSize) {
  $('#current-font-size').text(fontSize);
  $('#editor').css('font-size',fontSize);
};

WriteboxUI.prototype.setFontFamily = function(fontFamily) {
  $('#current-font-family').text(fontFamily);
  $('#editor').css('font-family',fontFamily);
};

WriteboxUI.prototype.setEditorWidth = function(editorWidth) {
  $('#current-width').val(width);
  this.layout();
};

WriteboxUI.prototype.setLineHeight = function(lineHeight) {
  $('#current-line-height').val(lineHeight);
  $('#editor').css('lineHeight',lineHeight + 'em');
};

WriteboxUI.prototype.setTextColor = function(textColor) {
  $('#front-color-picker').css('background-color', textColor);
  $('#editor, #editor-footer').css('color', textColor);
};

WriteboxUI.prototype.setBackgroundColor= function(backgroundColor) {
  $('#bg-color-picker').css('background-color', backgroundColor);
  $('body').css('background-color', backgroundColor);
};

WriteboxUI.prototype.setStatisticsVisibility = function(statisticsVisibility) {
	if (statisticsVisibility === 'show') {
    $('#current-show-statics').attr('checked', true);
    $('#document-statistics').show();
	} else {
    $('#current-show-statics').attr('checked', false);
    $('#document-statistics').hide();
  }
};

WriteboxUI.prototype.setScrollbarVisibility = function(scrollbarVisibility) {
	if (statisticsVisibility === 'show') {
    $('#current-show-scrollbar').attr('checked', true);
    $('#editor, #preview').addClass('off-scrollbar');
	} else {
    $('#current-show-scrollbar').attr('checked', false);
    $('#editor, #preview').addClass('off-scrollbar');
  }
  this.layout();
};
