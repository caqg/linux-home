// Background for Cisco WebEx Meeting Extension
// Scott Xu (scottx@cisco.com), 2014.2

//var chromeVersion = parseInt(window.navigator.appVersion.match(/Chrome\/(\d+)\./)[1], 10);

var Background = (function(self) {
	// native ports, map port name with port object
	var nativePorts = {};
	// client ports, map port name with port object
	var clientPorts = {};
	
	var hostName_ = "com.webex.meeting";

	// post message to page via client port
	self.postMessageToPage = function(name, message) {
		var clientPort = clientPorts[name];
		console.log('[Background] postMessageToPage: name=', name);
		console.log('[Background] postMessageToPage: clientPort=', clientPort);
		if (clientPort != null) {
			try {
				console.log('[Background] postMessageToPage: message=', message);
				clientPort.postMessage(message);
			} catch(e) {
				console.log('[Background] postMessageToPage: err=', e.toString());
			}
		} else {
		}
	};

	// post message to native via native port
	self.postMessageToNative = function(name, message) {
		var nativePort = nativePorts[name];
		console.log('[Background] postMessageToNative: name=', name);
		console.log('[Background] postMessageToNative: nativePort=', nativePort);
		if (nativePort != null) {
			try {
				console.log('[Background] postMessageToNative: message=', message);
				nativePort.postMessage(message);
			} catch(e) {
				var errorMsg = {
					'timestamp': (new Date()).toUTCString(),
					'token': name,
					'message_type': 'error',
					'message': {
						'error_no': -1,
						'error_message': e.toString()
					}
				};
				self.postMessageToPage(nativePort.name, errorMsg);
				console.log('[Background] postMessageToNative: err=', e.toString());
			}
		} else {
		}
	};

	self.handleClientMessage = function(message, clientPort) {
		console.log('[Background] handleClientMessage: message=', message);
		console.log('[Background] handleClientMessage: clientPort=', clientPort);
		self.postMessageToNative(clientPort.name, message);
	};

	self.handleNativeMessage = function(message, nativePort) {
		console.log('[Background] handleNativeMessage: nativePort=', nativePort);
		console.log('[Background] handleNativeMessage: message=', message);
		self.postMessageToPage(nativePort.name, message);
	};

	self.handleNativeDisconnect = function(nativePort) {
		console.log('[Background] handleNativeDisconnect: nativePort=', nativePort);
		console.log('[Background] handleNativeDisconnect: lastError=', chrome.runtime.lastError.message);

		if (nativePorts[nativePort.name]) {
			delete nativePorts[nativePort.name];
		}
		console.log('[Background] handleNativeDisconnect: nativePorts=', nativePorts);
		
		var clientPort = clientPorts[nativePort.name];
		console.log('[Background] handleNativeDisconnect: clientPort=', clientPort);
		if (clientPort != null) {
			// send DISCONNECT message to PAGE
			var msg = {
				'timestamp': (new Date()).toUTCString(),
				'token': clientPort.name,
				'message_type': 'disconnect',
				'message': chrome.runtime.lastError.message
			};

			clientPort.postMessage(msg);
			clientPort.disconnect();
			if (clientPorts[clientPort.name]) {
				delete clientPorts[clientPort.name];
			}
			console.log('[Background] handleNativeDisconnect: clientPorts=', clientPorts);
		}
	};
	
	self.handleClientDisconnect = function(clientPort) {
		console.log('[Background] handleClientDisconnect: clientPort=', clientPort);
		if (clientPorts[clientPort.name]) {
			delete clientPorts[clientPort.name];
		}
		console.log('[Background] handleClientDisconnect: clientPorts=', clientPorts);
		
		var nativePort = nativePorts[clientPort.name];
		if (nativePort != null) {
			// send DISCONNECT message to NATIVE
			var msg = {
					'timestamp': (new Date()).toUTCString(),
					'token': nativePort.name,
					'message_type': 'disconnect',
					'message': 'disconnect'
			};
			self.postMessageToNative(nativePort.name, msg);
			if (nativePorts[nativePort.name]) {
				delete nativePorts[nativePort.name];
			}
		}
	};
	
	self.connectNative = function(name) {
		var nativePort = nativePorts[name];
		console.log('[Background] connectNative: name=', name);
		console.log('[Background] connectNative: nativePort=', nativePort);
		if (typeof nativePort == undefined || nativePort == null) {
			try {
				nativePort = chrome.runtime.connectNative(hostName_);
				nativePort.name = name;
				nativePort.onMessage.addListener(self.handleNativeMessage);
				nativePort.onDisconnect.addListener(self.handleNativeDisconnect);
				console.log('[Background] connectNative: nativePort=', nativePort);
				nativePorts[nativePort.name] = nativePort;
			} catch (e) {
				console.log('[Background] connectNative: Failed connecting to native port,', e.toString());
				return null;
			}
		}
		return nativePort;
	};
	
	//self.handleClientDestroy = function(args) {
	//	console.log('[Background] self.handleClientDestroy: args=', args);
	//};
	
	self.handleClientConnect = function(clientPort) {
		console.log('[Background] chrome.runtime.onConnect, clientPort=', clientPort);
		//var portSenderId = clientPort.sender.id;
		
		//NOTE: CLIENT port and NATIVE port are one to one relationship
		
		clientPort.onMessage.addListener(self.handleClientMessage);
		clientPort.onDisconnect.addListener(self.handleClientDisconnect);
		//clientPort.onDestroy_ = self.handleClientDestroy;
		
		clientPorts[clientPort.name] = clientPort;
		//console.log('[Background] chrome.runtime.onConnect, clientPorts=', clientPorts);
		
		var nativePort = self.connectNative(clientPort.name);
		if (nativePort != null) {
			// send a HELLO message to NATIVE
			var helloMsg = {
				'timestamp': (new Date()).toUTCString(),
				'token': clientPort.name,
				'message_type': 'hello',
				'message': 'hello'
			};
			self.postMessageToNative(clientPort.name, helloMsg);
		}
	};
	
	self.init = function() {
		//console.log('[Background] init: chromeVersion=', chromeVersion);
		console.log('[Background] init: hostName_=', hostName_);
		
		chrome.runtime.onConnect.addListener(self.handleClientConnect);
		if (chrome.runtime.onUpdateAvailable) {
			chrome.runtime.onUpdateAvailable.addListener(function(details) {
				console.log('chrome.runtime.onUpdateAvailable, details=', details);
			});
		}
		//chrome.runtime.onConnectExternal(function(port) {
		//});
		//chrome.runtime.onRequest.addListener(function(request, sender, sendResponse) {
		//});
	};
	return self;

}(Background || {}));

window.addEventListener('load', function() {
	Background.init();
}, false);