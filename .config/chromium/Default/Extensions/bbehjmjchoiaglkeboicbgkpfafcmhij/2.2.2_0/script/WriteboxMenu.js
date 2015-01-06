function MenuController() {
  this.subscribers = {};

  this.initUI();
  this.buildEventHandler();
}

MenuController.MENU_ITEMS = [
  { selector: '#new-button', menuName: 'newText' },
  { selector: '#load-button', menuName: 'loadText' },
  { selector: '#sync-button', menuName: 'syncText' },
  { selector: '#preview-markdown-button', menuName: 'previewMarkdown' },
  { selector: '#option-button', menuName: 'optionBar' },
  { selector: '#discard-button', menuName: 'discardText' },
  { selector: '#delete-local-data-button', menuName: 'deleteLocalData' },
  { selector: '#saveas-button', menuName: 'saveTextAs' },
  { selector: '#download-text-menu', menuName: 'downloadPlainText' },
  { selector: '#download-markdown-menu', menuName: 'downloadMarkdownText' },
  { selector: '#download-html-menu', menuName: 'downloadHtml' },
  { selector: '#shortcuts-setting-button', menuName: 'showShortcutsSetting' },
  { selector: '#about-button', menuName: 'showAboutInformation' },
  { selector: '#account-menu', menuName: 'showAccountInformation' }
];

MenuController.prototype.initUI = function() {  
  $(".pulldown").pulldown();
  $("[data-tooltip]").tooltip();

  $('#header').css('visibility', 'visible');
};

MenuController.prototype.buildEventHandler = function() {
  var self = this;

  for (var i = 0; i < MenuController.MENU_ITEMS.length; i++) {
    (function() {
      var item = MenuController.MENU_ITEMS[i];
      $(item.selector).click(function() {
        self.notify('menuSelected', item.menuName);
      });
    })();
  }
};

MenuController.prototype.notify = function(eventName, data) {
  if (eventName in this.subscribers) {
    for(var i = 0; i < this.subscribers[eventName].length; i++) {
      this.subscribers[eventName][i](data);
    }
  }
};

MenuController.prototype.subscribe = function(eventName, subscriber) {
  if (eventName in this.subscribers) {
    this.subscribers[eventName].push(subscriber);
  } else {
    this.subscribers[eventName] = [subscriber];
  }
};