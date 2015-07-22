function Shortcuts() {
  this.keys = {
    sync: 'S',
    preview: 'P',
    format_bold: 'B',
    format_italic: 'I',
    format_list: 'L'
  };

  this.load();
}

Shortcuts.defaultKeys = {
  sync: 'S',
  preview: 'P',
  format_bold: 'B',
  format_italic: 'I',
  format_list: 'L'
};

Shortcuts.prototype.load = function() {
  var self = this;

  util.local.readJSON('shortcuts', function(keys) {
  	if (keys) {
  		self.keys = keys;
      for (action in self.keys) {
        $('.shortcuts[data-action=' + action + ']').val(self.keys[action]);
      }
  	}
  });
};

Shortcuts.prototype.set = function(action, c) {
  this.keys[action] = c;
  util.local.writeJSON('shortcuts', this.keys);
};

Shortcuts.prototype.reset = function() {
	util.local.writeJSON('shortcuts', Shortcuts.defaultKeys)
	this.load();
};
