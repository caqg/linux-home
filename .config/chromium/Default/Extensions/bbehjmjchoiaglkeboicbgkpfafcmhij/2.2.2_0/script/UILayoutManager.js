function UILayoutManager(settings) {
	this.settings = settings;

	this.settings.subscribe('settingChanged', this.onSettingChanged.bind(this));
  $(window).resize(this.onWindowResized.bind(this));
}

UILayoutManager.DEFAULT_WIDTH = 800;
UILayoutManager.PADDING_FULLSCREEN = 10;

UILayoutManager.prototype.onWindowResized = function() {
  this.setUIWidth(this.settings.width);
};

UILayoutManager.prototype.onSettingChanged = function() {
  this.setUIWidth(this.settings.width);
};

UILayoutManager.prototype.setUIWidth = function(w) {
	var l = this.getLayoutData(w);

  $('#editor')
    .css("margin-left", l.padding)
    .css("padding-right", l.padding)
    .width(l.width + l.padding);

  if ($(window).width() < util.DEFAULT_WIDTH) {
    $('#editor-footer, #header > #menu, .slidedown-bar .container')
      .css("margin-left", 0)
      .css("padding-right", 0)
      .width(l.width + l.padding*2);

  } else {
    $('#editor-footer, #header > #menu, .slidedown-bar .container')
      .css("margin-left", l.padding)
      .css("padding-right", l.padding)
      .width(l.width + l.padding);
  }

};

UILayoutManager.prototype.getLayoutData = function(w) {
	var layoutData = {}; var winWidth = $(window).width();
  w = parseInt(w) || UILayoutManager.DEFAULT_WIDTH;
  if (winWidth < UILayoutManager.DEFAULT_WIDTH) {
    if (w < winWidth) {
      layoutData.width = w;
      layoutData.padding = (winWidth / 2) - (layoutData.width / 2) + UILayoutManager.PADDING_FULLSCREEN;
    } else {
      layoutData.width = winWidth - UILayoutManager.PADDING_FULLSCREEN * 2;
      layoutData.padding = UILayoutManager.PADDING_FULLSCREEN;
    }
  } else {
    layoutData.width = w;
    layoutData.padding = (winWidth / 2) - (layoutData.width / 2);
  }

  return layoutData;
};