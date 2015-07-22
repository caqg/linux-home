function Settings() {
  this.fontSize = '13pt';
  this.fontFamily = 'Verdana';
  this.backgroundColor = '#fff';
  this.textColor = '#000';
  this.width = 800;
  this.lineHeight = 1.6;
  this.showStatistics = 'show';
  this.showScrollbar = 'show';

  this.subscribers = {};
}

Settings.ITEMS = ['fontSize', 'fontFamily', 'textColor', 'backgroundColor',
                  'width', 'lineHeight', 'showStatistics', 'showScrollbar'];

Settings.prototype.load = function() {
  var self = this;

  for (var i = 0; i < Settings.ITEMS.length; i++) {
    (function() {
      var settingName = Settings.ITEMS[i];
      self.get(settingName, function(value) {
        if (value !== undefined && value !== '') {
          if (value === 'true') value = true;    // for Checkbox
          if (value === 'false') value = false;  // for Checkbox
          self.set(settingName, value);
        }
      })
    })();
  }
};

Settings.prototype.set = function(settingName, value) {
	if (value === '' || value === undefined || value === null) {
		return;
	}

	this[settingName] = value;
	util.local.write(settingName, value);
	this.notify('settingChanged', settingName);
};

Settings.prototype.get = function(settingName, callback) {
	util.local.read(settingName, function(val) {
		callback(val);
	});
};

Settings.prototype.notify = function(eventName, data) {
  if (eventName in this.subscribers) {
    for(var i = 0; i < this.subscribers[eventName].length; i++) {
      this.subscribers[eventName][i](data);
    }
  }
};

Settings.prototype.subscribe = function(eventName, subscriber) {
  if (eventName in this.subscribers) {
    this.subscribers[eventName].push(subscriber);
  } else {
    this.subscribers[eventName] = [subscriber];
  }
};

