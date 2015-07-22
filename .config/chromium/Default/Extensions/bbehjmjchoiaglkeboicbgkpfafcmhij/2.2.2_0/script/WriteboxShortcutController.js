function WriteboxShortcutController(shortcuts) {
  this.shortcuts = shortcuts;
  $('#restore-default-shortcuts').click(this.onReset.bind(this));
}

WriteboxShortcutController.prototype.onReset = function() {
  this.shortcuts.reset();
};

WriteboxShortcutController.prototype.showDialog = function() {
	var self = this;

  showDialog({
    dialogId: '#shortcuts-dialog',
    okay: function() {
      $('.shortcuts').each(function(i, item) {
      	var a = $(item).attr('data-action')
            c = $(item).val().toUpperCase();

        self.shortcuts.set(a, c);
      });
    },
    cancel: function() {
    	self.shortcuts.load();

    }
  });
};

