// Content Script for Cisco WebEx Meeting Extension
// Scott Xu (scottx@cisco.com), 2014.2
// 		2014.4.30, support host updateing, Scott Xu

var ContentScript = (function(self) {
	var kHostNotInstalled = 'HostNotInstalled';
	var kExtensionNotInstalled = 'ExtensionNotInstalled';
	var inFrame = true;
	self.id = chrome.runtime.id;
	self.port = null;
	self.token_ = '';

	self.handleStateChanged = function(result) {
		console.log('[ContentScript] handleStateChanged: result=', result);
		var stateMsg = {
			'timestamp': (new Date()).toUTCString(),
			'token': ContentScript.token_,
			'message_type': 'state_changed',
			'message': {
				'ExtState': {
					'result': result,
					'reason': (result ? 'ok' : kExtensionNotInstalled)
				},
				'HostState': {
					'result': false,
					'reason': kHostNotInstalled
				}
			}
		};
		
		self.handleNativeMessage(stateMsg);
	};
	
	self.handleNativeMessage = function(message) {
		console.log('[ContentScript] handleNativeMessage: message=', message);
		var event = new CustomEvent('native_message', {
			detail: message
		});
		if (inFrame) {
			window.parent.document.dispatchEvent(event);
		} else {
			document.dispatchEvent(event);
		}
	};
	
	self.handleNativeDisconnect = function(port) {
		//console.log('[ContentScript] port.onDisconnect: port=', port);
		console.log('[ContentScript] port.onDisconnect: self.port=', self.port);	// self.port == port
		//console.log('[ContentScript] port.onDisconnect: isConnected=', isConnected);
		var msg = {
			'timestamp': (new Date()).toUTCString(),
			'token': self.token_,
			'message_type': 'disconnect',
			'message': 'disconnect'
		};
		self.port = null;
		self.handleNativeMessage(msg);
	};
	
	// sendMessage: send message to background
	self.sendMessage = function(message, responseCallback) {
		console.log('[ContentScript] sendMessage: self.port=', self.port);
		console.log('[ContentScript] sendMessage: message=', message);
		try {
			//chrome.runtime.sendMessage(message, responseCallback);
			if (self.port != null) {
				self.port.postMessage(message);
			} else {
			}
		} catch(err) {
			console.log('[ContentScript] sendMessage: err=', err);
			var errorMsg = {
				'timestamp': (new Date()).toUTCString(),
				'token': self.token_,
				'message_type': 'error',
				'message': {
					'error_no': -1,
					'error_message': err.toString()
				}
			};
			self.handleNativeMessage(errorMsg);
			console.log(err.toString());
		}
	};
	
	self.connectPort = function(extId) {
		console.log('[ContentScript] connectPort: extId=', extId, 'self.port=', self.port);
		if (self.port == null) {
			try {
				self.port = chrome.runtime.connect(extId, { 'name': self.token_ });
				console.log('[ContentScript] connectPort: self.port=', self.port);
				
				if (self.port != null) {
					self.port.onMessage.addListener(self.handleNativeMessage);
					self.port.onDisconnect.addListener(self.handleNativeDisconnect);
				}
			} catch (err) {
				console.log('[ContentScript] connectPort: err=', err);
				ContentScript.handleStateChanged(false);
			}
		}
	};
	
	self.init = function() {
		console.log('[ContentScript] init: chrome.runtime.id=', chrome.runtime.id);
		
		document.addEventListener('connect', function(e) {
			//self.connectPort('jlhmfgmfgeifomenelglieieghnjghma');
			console.log('[ContentScript] connect: e=', e);
			self.token_ = e.detail.token;
			self.connectPort('');
		});

		document.addEventListener('message', function(e) {
			//console.log('[ContentScript] message: e=', e);
			self.sendMessage(e.detail, self.handleNativeMessage);
		});
		
		/*
		chrome.runtime.onConnect.addListener(function(port) {
			console.log('chrome.runtime.onConnect, port=', port);
		});
		chrome.extension.onConnect.addListener(function(port) {
			console.log('chrome.extension.onConnect, port=', port);
		});
		*/
	};
	
	return self;

})(ContentScript || {});

ContentScript.init();

window.onload = function() {
	//ContentScript.token_ = $('#wbx-extension-iframe', window.parent.document).attr('token');
	ContentScript.handleStateChanged(true);
};