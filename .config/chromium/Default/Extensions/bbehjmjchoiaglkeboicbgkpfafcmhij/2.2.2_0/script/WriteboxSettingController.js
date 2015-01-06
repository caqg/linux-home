function SettingController(settings) {
	this.settings = settings;
  this.subscribers = {};

	this.initUI();
	this.buildEventHandler();
	this.settings.subscribe('settingChanged', this.onSettingChanged.bind(this));
};

SettingController.SETTING_ITEMS = [
  { selector: '.font-size-menu', settingName: 'fontSize', type: 'label' },
  { selector: '.font-family-menu', settingName: 'fontFamily', type: 'label' },
  { selector: '#current-width', settingName: 'width', type: 'textfield' },
  { selector: '#current-line-height', settingName: 'lineHeight', type: 'textfield' },
  { selector: '#current-show-statistics', settingName: 'showStatistics', type: 'checkbox' },
  { selector: '#current-show-scrollbar', settingName: 'showScrollbar', type: 'checkbox' },
];

SettingController.prototype.initUI = function() {
  $(".font-family-menu").each(function(i, item) {
    $(this).css("font-family", $(this).text());
  });

  $(".font-size-menu").each(function(i, item) {
    $(this).css("font-size", $(this).text());
  });

  if (navigator.userAgent.indexOf('Chrome') > 0 ||
      navigator.userAgent.indexOf('Safari') > 0) {
    $('#current-show-scrollbar').parent().show();
  } else {
    $('#current-show-scrollbar').parent().hide();      
  }
};


SettingController.prototype.buildEventHandler = function() {
  var self = this;

  for (var i = 0; i < SettingController.SETTING_ITEMS.length; i++) {
    (function() {
	  	var item = SettingController.SETTING_ITEMS[i];

	    if (item.type === 'label') {
	      $(item.selector).click(function() {
	        var value = $(this).text();
	        self.settings.set(item.settingName, value);
	      });

	    } else if (item.type === 'textfield') {
	      $(item.selector).keypress(function (e) {
	        if (e.keyCode === 13) {
	          var value = $(this).val();
	          self.settings.set(item.settingName, value);
	        }
	      });

	    } else if (item.type === 'checkbox') {
	      $(item.selector).change(function (e) {
		      var status = $(this).attr('checked') || false;
		      self.settings.set(item.settingName, status);
	      });
	    }
    })();
  }

  $("#bg-color-picker").simpleColorPicker({
    onChangeColor: function(color) {
      self.settings.set('backgroundColor', color);
    }
  });

  $("#front-color-picker").simpleColorPicker({
    onChangeColor: function(color) {
      self.settings.set('textColor', color);
    }
  });
};

SettingController.prototype.onSettingChanged = function(settingName) {
	this.setCurrentValue(this.settings);
};

SettingController.prototype.setCurrentValue = function(settings) {
  $("#current-font-size").text(settings.fontSize);
  $("#current-font-family").text(settings.fontFamily);

  $("#current-width").val(settings.width);
  $("#current-line-height").val(settings.lineHeight);

  $("#current-show-statistics").attr("checked", settings.showStatistics);
  $("#current-show-scrollbar").attr("checked", settings.showScrollbar);

  $("#bg-color-picker").css("background-color", settings.backgroundColor);
  $("#front-color-picker").css("background-color", settings.textColor);
};

SettingController.prototype.showOptionBar = function(settings) {
  $('#option-bar').slideDown(150, function() {
    $('#option-bar').css({'overflow':'visible'});
    $('#option-bar .close-button').one('click', function() {
      $('#option-bar').slideUp(150);
    });
  });
};

SettingController.prototype.notify = function(eventName, data) {
  if (eventName in this.subscribers) {
    for(var i = 0; i < this.subscribers[eventName].length; i++) {
      this.subscribers[eventName][i](data);
    }
  }
};

SettingController.prototype.subscribe = function(eventName, subscriber) {
  if (eventName in this.subscribers) {
    this.subscribers[eventName].push(subscriber);
  } else {
    this.subscribers[eventName] = [subscriber];
  }
};