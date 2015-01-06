
//  import target-specific stuff
//  ============================
    (function ($R) {
    
        
        //  storage
        //  =======
        
            $R.storage__get = function (_key)
            {
                return localStorage[_key];
            };
        
            $R.storage__set = function (_key, _value)
            {
                localStorage[_key] = _value;
            };
        
            $R.storage__set_more = function (_o)
            {
                for (var _x in _o) {
                    localStorage[_x] = _o[_x];
                }
            };
        
        
        //  get
        //  ===
            $R.credentials__get = function ()
            {
                //  get
                var _got_user = $R.storage__get('storedEvernoteUsername'),
                    _got_pass = $R.storage__get('storedEvernotexAuthToken'),
                    _got_srvr = $R.storage__get('storedEvernoteServer');
                    
                //  fail
                if ((_got_user > '') && (_got_pass > '')) {}else { return false; }
                    
                //  result
                var _r = {};
                    _r.username = _got_user;
                    _r.server = (((_got_srvr == 'main') || (_got_srvr == 'china')) ? _got_srvr : 'none');
                    _r.xAuthToken = $R.xor.decrypt(_got_pass, _got_user);
        
                return _r;
            };
        
        
        //  set
        //  ===
            $R.credentials__set = function (_o)
            {
                //  fail
                if ((_o['username'] > '') && (_o['xAuthToken'] > '')) {}else { return false; }
        
                //  set
                $R.storage__set('storedEvernoteServer', $R.$bootstrap.server);
                $R.storage__set('storedEvernoteUsername', _o.username);
                $R.storage__set('storedEvernotexAuthToken', $R.xor.encrypt(_o['xAuthToken'], _o['username']));
                $R.storage__set('storedEvernotePassword', '');
        
                return true;
            };
        
        
        //  forget
        //  ======
            $R.credentials__forget = function ()
            {
                $R.storage__set_more({
                    'storedEvernoteUsername': '',
                    'storedEvernotexAuthToken': '',
                    'storedEvernoteServer': '',
                    'storedEvernoteLogoutOnNextAction' : 'yes'
                });
            };
        
        
        //  translation
        //  =========== 
            $R.translation__get_item = function (_key)
            {
                var _t = chrome.i18n.getMessage('inside__'+_key);
                return $R.encode(_t > '' ? _t : '');
            };
        
        
        //  open url
        //  ========
            $R.open_url_in_new_tab = function (_url)
            {
                chrome.tabs.create({ 'url': _url, 'selected': true });
            };
        
    
    })(window.__readable_by_evernote);


//  ==========================================================================================================================


//  import _js_anywhere/
//  ====================
    (function ($R) {
    
        (function () {
            
            //  valid url
            //  =========
                var _valid_url = function (_url)
                {
                    //  not string
                    if (_url.indexOf) {}else { return false; }
                    
                    //  look at protocol
                    switch (true)
                    {
                        case (_url.indexOf('http://') === 0):
                        case (_url.indexOf('https://') === 0):
                        case (_url.indexOf('ftp://') === 0):
                        case (_url.indexOf('file://') === 0):
                            return true;
                            break;
                        
                        default:
                            return false;
                            break;
                    }
            
                    return false;
                };
            
            /* =============== */
            $R.valid_url = _valid_url;
        })();

        (function () {
            
            //  escape html
            //  ===========
                var _escape_html = function (_string)
                {
                    var _replace = { "&": "amp", '"': "quot", "<": "lt", ">": "gt" };
                    return _string.replace(/[&"<>]/g, function (_match) { var _r = _replace[_match]; return (_r ? ("&" + _r + ";") : _match); });
                };
                
            
            //  escape html
            //  ===========
                var _unescape_html = function (_string)
                {
                    var _replace = { "amp": "&", "quot": '"', "lt": "<", "gt": ">" };
                    return _string.replace(/[&](amp|quot|lt|gt)[;]/g, function (_match, _match_key) { var _r = _replace[_match_key]; return (_r ? _r : _match); });
                };
            
            
            //  encode
            //  ======
                var _encode = function (_string)
                {
                    if (_string == '') { return 'none'; }
                    var _replace = { "!": "%21", "'": "%27", "(": "%28", ")": "%29", "*": "%2A" };
                    return _string.replace(/[!'()*]/g, function (_match) { return _replace[_match]; });
                };
            
                
            //  decode
            //  ======
                var _decode = function (_string)
                {
                    if (_string == 'none') { return ''; }
                    return decodeURIComponent(_string);
                };
            
            /* =============== */
            $R.escape_html =    _escape_html;
            $R.unescape_html =  _unescape_html;
            $R.encode =         _encode;
            $R.decode =         _decode;
        })();

        (function () {
            
            //  options
            //  =======
                var _default_options = {
                    'text_font':            '"PT Serif"',
                    'text_font_header':     '"PT Serif"',
                    'text_font_monospace':  'Inconsolata',
                    'text_size':            '16px',
                    'text_line_height':     '1.5em',
                    'box_width':            '36em',
                    'color_background':     '#F3F2EE',
                    'color_text':           '#1F0909',
                    'color_links':          '#065588',
                    'text_align':           'normal',
                    'base':                 'theme-1',
                    'footnote_links':       'on_print',
                    'large_graphics':       'do_nothing',
                    'custom_css':           ''
                };
            
            
            //  vars
            //  ====
                var _default_vars = {
                    'theme':                        'theme-1',                          /* theme-1, theme-2, theme-3, custom */
                
                    'keys_activation':              'Control + Alt + Right Arrow',
                    'keys_clip':                    'Control + Alt + Up Arrow',
                    'keys_highlight':               'Control + Alt + H',
            
                    'clip_tag':                     '',
                    'clip_notebook':                '',
                    'clip_notebook_guid':           '',
                
                    'related_notes':                'enabled',                          /* enabled, just_at_bottom, disabled */
                    'smart_filing':                 'enabled',                          /* enabled, just_notebooks, just_tags, disabled */
                    'smart_filing_for_business':    'disabled',                         /* enabled, disabled */
            
                    'open_notes_in':                'web',                              /* web, desktop */
                
                    'custom_theme_options':         ''                                  /* the custom theme options get serialized into this */
                };
            
                //  mac-specific keyboard shortcuts
                if ((window) && (window.navigator) && (window.navigator.userAgent) && (window.navigator.userAgent.indexOf) && (window.navigator.userAgent.indexOf('Mac OS') > -1))
                {
                    _default_vars['keys_activation'] = 'Control + Command + Right Arrow';
                    _default_vars['keys_clip'] =       'Control + Command + Up Arrow';
                    _default_vars['keys_highlight'] =  'Control + Command + H';
                }
            
            
            //  sizes
            //  =====
                var _the_sizes = {
                    'small':    { 'theme-1': '12px',  'theme-2': '12px',  'theme-3': '12px',  'custom':  '12px' },
                    'medium':   { 'theme-1': '16px',  'theme-2': '16px',  'theme-3': '16px',  'custom':  '16px' },
                    'large':    { 'theme-1': '20px',  'theme-2': '20px',  'theme-3': '20px',  'custom':  '20px' }
                };
            
            
            //  themes
            //  ======
                var _the_themes = {
                    'theme-1': {
                        'text_font':              '"PT Serif"',
                        'text_font_header':       '"PT Serif"',
                        'text_font_monospace':    'Inconsolata',
                        'text_size':              '16px',
                        'text_line_height':       '1.5em',
                        'box_width':              '36em',
                        'color_background':       '#F3F2EE',
                        'color_text':             '#1F0909',
                        'color_links':            '#065588',
                        'text_align':             'normal',
                        'base':                   'theme-1',
                        'footnote_links':         'on_print',
                        'large_graphics':         'do_nothing',
                        'custom_css':             ''
                    },
                    
                    'theme-2': {
                        'text_font':              'Helvetica, Arial',
                        'text_font_header':       'Helvetica, Arial',
                        'text_font_monospace':    '"Droid Sans Mono"',
                        'text_size':              '14px',
                        'text_line_height':       '1.5em',
                        'box_width':              '42em',
                        'color_background':       '#FFFFFF',
                        'color_text':             '#333333',
                        'color_links':            '#009900',
                        'text_align':             'normal',
                        'base':                   'theme-2',
                        'footnote_links':         'on_print',
                        'large_graphics':         'do_nothing',
                        'custom_css':             ''
                    },
                    
                    'theme-3': {
                        'text_font':              '"PT Serif"',
                        'text_font_header':       '"PT Serif"',
                        'text_font_monospace':    'Inconsolata',
                        'text_size':              '16px',
                        'text_line_height':       '1.5em',
                        'box_width':              '36em',
                        'color_background':       '#2D2D2D',
                        'color_text':             '#E3E3E3',
                        'color_links':            '#E3E3E3',
                        'text_align':             'normal',
                        'base':                   'theme-3',
                        'footnote_links':         'on_print',
                        'large_graphics':         'do_nothing',
                        'custom_css':             ''
                    }
                };
            
            /* =============== */
            $R.default_options =        _default_options;
            $R.default_vars =           _default_vars;
            $R.the_sizes =              _the_sizes;
            $R.the_themes =             _the_themes;
        })();

        (function () {
            
            //  Used to show/not-show the dialog box telling people about new stuff in Clearly.
            //  Options:
            //      "the curent version number"
            //      "nope" -- usually this is what this var's value should be.
            
            var _first_show_identifier = '1417113830';
                _first_show_identifier = 'nope';
            
            /* =============== */
            $R.first_show_identifier =  _first_show_identifier;
        })();
        
        (function () {
            
            //  get browser
            //  ===========
                var _from_user_agent__get_browser = function (_user_agent)
                {
                    /*  possible values:
                        ================   
                        desktop:    firefox, safari, chrome, internet_explorer, opera
                        ios:        iphone, ipad
                        mobile:     android, dolphin, firefox_mobile, chrome_mobile, windows_phone
                        other:      unknown
                    */    
            
            
                    //  normalize
                    //  =========
                        _user_agent = _user_agent.toLowerCase();
            
            
                    //  partial detection -- old jQuery code
                    //  =================
                        var _jb = (function ()
                        {
                            var ua = _user_agent,
                                rwebkit = /(webkit)[ \/]([\w.]+)/,
                                ropera = /(opera)(?:.*version)?[ \/]([\w.]+)/,
                                rmsie = /(msie) ([\w.]+)/,
                                rmozilla = /(mozilla)(?:.*? rv:([\w.]+))?/,
                                match = rwebkit.exec( ua ) ||
                                        ropera.exec( ua ) ||
                                        rmsie.exec( ua ) ||
                                        ua.indexOf("compatible") < 0 && rmozilla.exec( ua ) ||
                                        [];
            
                            return { 
                                'browser': match[1] || "", 
                                'version': match[2] || "0" 
                            };            
                        })();
                        
            
                    //  full detection
                    //  ==============
                        var _the_browser = (function ()
                        {
                            var _ua = _user_agent;
                
                            if ((_ua.indexOf('windows phone') > -1))                            { return 'windows_phone'; }
            
                            if ((_ua.indexOf('chrome') > -1) && (_ua.indexOf('android') > -1))  { return 'chrome_mobile'; }
                            if ((_ua.indexOf('firefox') > -1) && (_ua.indexOf('fennec') > -1))  { return 'firefox_mobile'; }
                            if ((_ua.indexOf('dolfin') > -1) || (_ua.indexOf('dolphin') > -1))  { return 'dolphin'; }
                            if ((_ua.indexOf('android') > -1))                                  { return 'android'; }
            
                            if ((_ua.indexOf('ipad') > -1))                                     { return 'ipad'; }
                            if ((_ua.indexOf('iphone') > -1))                                   { return 'iphone'; }
                
                            if ((_jb.browser.opera))                                            { return 'opera'; }
                            if ((_jb.browser.msie))                                             { return 'internet_explorer'; }
                            if ((_jb.browser.webkit) && (_ua.indexOf('chrome') > -1))           { return 'chrome'; }
                            if ((_jb.browser.webkit) && (_ua.indexOf('safari') > -1))           { return 'safari'; }
                            if ((_jb.browser.mozilla))                                          { return 'firefox'; }
                    
                            return 'unknown';
                        })();
                        
                
                    //  return
                    //  ======
                        return _the_browser;       
                };
            
            
            //  get os -- nicely formatted
            //  ======
                var _from_user_agent__get_os = function (_user_agent)
                {
                    var ua = _user_agent.toLowerCase();
                    switch (true)
                    {
                        case (/linux/i.test(ua)):
                            return 'Linux';
                    
                        case (/macintosh/i.test(ua)):
                            var _m = ua.match(/(Mac OS [^\)]+?)\)/i);
                            // if (_m && _m[1]) { return _m[1].replace(/_/g, '.'); }
                            return 'Mac OS';
                        
                        case (/windows/i.test(ua)):
                            var _m = ua.match(/Windows NT ([0-9.]+)/i);
                            var _windows_variants = { 
                                "3.1":  "Windows NT 3.1",
                                "3.5":  "Windows NT 3.5",
                                "3.51": "Windows NT 3.51",
                                "4.0":  "Windows NT 4.0",
                                "5.0":  "Windows 2000",
                                "5.1":  "Windows XP",
                                "5.2":  "Windows XP",
                                "6.0":  "Windows Vista",
                                "6.1":  "Windows 7",
                                "6.2":  "Windows 8"
                            };
                            
                            //  versioned
                            if (_m && _m[1] && _windows_variants[_m[1]]) { return _windows_variants[_m[1]]; }
                            
                            //  default
                            return 'Windows';
                    }
                
                    return 'Unknown OS';
                };
            
            /* =============== */
            $R.from_user_agent__get_browser = _from_user_agent__get_browser;
            $R.from_user_agent__get_os = _from_user_agent__get_os;
        })();
        
        (function () {
            
            //  translations
            //  ============
                var _translations__page = {
                
                    'menu__close__tooltip':                 'Hide the overlay.',
                    'menu__clip_to_evernote__tooltip':      'Clip to Evernote.',
                    'menu__highlight_to_evernote__tooltip': 'Highlight.',
                    'menu__print__tooltip':                 'Print.',
                    'menu__settings__tooltip':              'Show Themes.',
                    'menu__fitts__tooltip':                 'Hide the overlay.',
                    
                    /* === */
                    
                    'rtl__main__label':                     'Text direction?',
                    'rtl__ltr__label':                      'Left-to-right',
                    'rtl__rtl__label':                      'Right-to-left',
            
                    /* === */
                    
                    'related_notes__title':                 'Related Notes',
                    'related_notes__disable_short':         'Disable?',
                    'related_notes__disable_long':          'Do you want to disable Related Notes?',
            
                    /* === */
            
                    'filing_info__title_normal':            'Filed in:',
                    'filing_info__title_smart':             'Smart Filed in:',
                    'filing_info__default_notebook':        'Default',
                    'filing_info__view':                    'View',
                    'filing_info__edit':                    'Edit',
                    'filing_info__sentence':                'Clipped into the [=notebook] notebook, and tagged with [=tags].',
                    'filing_info__sentence_no_tags':        'Clipped into the [=notebook] notebook.',
                    'filing_info__sentence_and':            'and',
                    'filing_info__sentence_other_tags':     'other tags',
            
                    /* === */
            
                    'settings__theme__1__not_translated':   'Newsprint',
                    'settings__theme__2__not_translated':   'Notable',
                    'settings__theme__3__not_translated':   'Night Owl',
                    
                    'settings__theme__1':                   'Newsprint',
                    'settings__theme__2':                   'Notable',
                    'settings__theme__3':                   'Night Owl',
                    'settings__theme__custom':              'Custom',
                    
                    'settings__fontSize__small':            'small',
                    'settings__fontSize__medium':           'medium',
                    'settings__fontSize__large':            'large',
            
                    'settings__more_options':               'More options',
            
                    /* === */
                    
                    'footer__text':                         'Get a free Evernote account to save this article and view it later on any device.',
                    'footer__button':                       'Create account',
            
                    /* === */        
                    
                    'misc__clipping__doing':                'Clipping...',
                    'misc__clipping__failed':               'Clipping failed.',
                    'misc__login_request':                  'To sign in to Evernote, please click the Clearly icon in Chrome\'s toolbar.',
                    
                    'misc__page':                           'Page [=page]',
                    'misc__links':                          'Links'
                
                };    
            
            /* =============== */
            $R.translation__items = _translations__page;

            
            //  translations
            //  ============
                var _translations__features = {
                
                    'features__title__new':                 'You have a new version of Evernote Clearly!',
                    'features__title__all':                 'Welcome to the new Evernote Clearly',
                    
                    'features__clipping__title':            'Clip to Evernote',
                    'features__clipping__text':             'Save what you\'re reading to your Evernote account with one click. Access clips from any device, anytime in Evernote.',
            
                    'features__highlighting__title':        'Highlighting',
                    'features__highlighting__text':         'Highlight text you want to remember & quickly find it in your Evernote account. Highlighting changes you make in Clearly will be updated in your Evernote account automatically.',
            
                    'features__related_notes__title':       'Related Notes',
                    'features__related_notes__text':        'Magically rediscover notes from your Evernote account that are related to the page you are viewing. Related Notes are displayed at the bottom of the article or on the right side if space permits.',
            
                    'features__smart_filing__title':        'Smart Filing',
                    'features__smart_filing__text':         'Automatically assigns tags to your Web clips and saves them to the appropriate notebook, so you don\'t have to.',
                    
                    'features__eula_notice':                'By using Clearly, you agree to our [=eula].',
                    'features__eula':                       'End User License Agreement',
                    'features__close2':                     'Close'
            
                };    
            
            /* =============== */
            for (var _k in _translations__features) { $R.translation__items[_k] = _translations__features[_k]; }

            
            //  translations
            //  ============
                var _translations__popup = {
                
                    'login__heading':                      'Sign in to Evernote',
                    'login__spinner':                      'Signing in to Evernote',
                    'login__create_account':               'Create an account',
                    'login__button_do__label':             'Sign in',
                    'login__button_cancel__label':         'Cancel',
                    
                    'login__email__label':                 'Email address',
                    'login__password__label':              'Password',
                    'login__rememberMe__label':            'Remember me',
            
                    'login__email__error__required':       'Email is required.',
                    'login__email__error__length':         'Email must be between 1 and 64 characters long.',
                    'login__email__error__format':         'Email contains bad characters.',
                    'login__email__error__invalid':        'Not a valid, active user.',
                    
                    'login__password__error__required':    'Password is required.',
                    'login__password__error__length':      'Password must be between 6 and 64 characters long.',
                    'login__password__error__format':      'Password contains bad characters.',
                    'login__password__error__invalid':     'Email and password do not match existing user.',
                    'login__password__error__timeout':     'Login session timed-out. Please try again.',
            
                    'login__password__error__reset':       'Your password has expired. Please reset it now.',
                    'login__general__error':               'Authentication failed.',
            
                    /* === */
            
                    'two_factor__message__sms':            'We sent a text message with a verification code to',
                    'two_factor__message__google':         'Enter the verification code displayed in your Google Authenticator app.',
            
                    'two_factor__code__label':             'Verification code',
                    'two_factor__code__error__required':   'Verification code is required.',
                    'two_factor__code__error__length':     'Verification code should be at least 6 characters long.',
                    'two_factor__code__error__format':     'Verification code should be only numbers.',
                    'two_factor__code__error__invalid':    'Verification code is incorrect.',
                    
                    'two_factor__button_do__label':        'Verify',
                    'two_factor__button_help__label':      'I need help getting a verification code'
                
                };    
            
            /* =============== */
            for (var _k in _translations__popup) { $R.translation__items[_k] = _translations__popup[_k]; }

            
            //  translations
            //  ============
                var _translations__reminder = {
                
                    'reminder__heading': 'Get more from online reading, with Clearly',
                    'reminder__text':    'With just one click, strip any article of all distractions. With one more click, save any article in Evernote, forever. Try it now!',
                    'reminder__button':  'Read with Clearly'
                
                };    
            
            /* =============== */
            for (var _k in _translations__reminder) { $R.translation__items[_k] = _translations__reminder[_k]; }
        })();
        
    })(window.__readable_by_evernote);


//  import _js_background/
//  ======================
    (function ($R) {

        
        //  get options
        //  ===========
            $R.saved__get_options = function ()
            {
                var _return = {};
                for (var _x in $R.default_options) {
                    _return[_x] = $R.storage__get(_x);
                }
                return _return;
            };
        
                
        //  get vars    
        //  ========
            $R.saved__get_vars = function ()
            {
                var _return = {};
                for (var _x in $R.default_vars) {
                    _return[_x] = $R.storage__get(_x);
                }
                return _return;
            };
        
        
        //  device id
        //  =========
            $R.saved__get_device_id = function ()
            {
                var _curr = $R.storage__get('storedEvernoteDeviceId');
                if (_curr) {}else
                {
                    _curr = Math.floor((Math.random() * 1000 * 1000 * 1000)+1);
                    $R.storage__set('storedEvernoteDeviceId', _curr);
                }
                
                return _curr;
            };
            
            
        //  selects
        //  =======    
        
            $R.saved__select__theme = function (_theme_id)
            {
                //  var
                var _to_save = {};
                
                //  custom/general
                if (_theme_id == 'custom')
                {
                    _to_save = { 'theme': 'custom' };
                    var _vars = $R.saved__get_vars();
                    $R.decode(_vars['custom_theme_options']).replace(
                        /\[\[=(.*?)\]\[=(.*?)\]\]/gi,
                        function (_match, _name, _value) {
                            _to_save[_name] = _value;
                        });
                        
                    //  values are already encoded
                }
                else
                {
                    _to_save = $R.the_themes[_theme_id];
                    _to_save['theme'] = _theme_id;
                    
                    //  encode
                    for (var _key in _to_save) { _to_save[_key] = $R.encode(_to_save[_key]); }
                }
        
                //  save        
                $R.storage__set_more(_to_save);
            };
            
            $R.saved__select__size = function (_size)
            {
                var _current_vars = $R.saved__get_vars();
                $R.storage__set('text_size', $R.encode($R.the_sizes[_size][_current_vars['theme']]));
            };
            
            $R.saved__select__related_notes = function (_setting)
            {
                $R.storage__set('related_notes', $R.encode(_setting));
            };
            
            
        //  last used
        //  =========
        
            $R.saved__setLastUsed = function (_key, _val)
            {
                var _now = (new Date()).getTime();
                $R.storage__set('lastUsed_'+_key, (_val ? _val : _now));
            };
            
            $R.saved__getLastUsed = function (_key)
            {
                return $R.storage__get('lastUsed_'+_key);
            };
            
        
        //  do logout?
        //  ==========
            $R.credentials__get_logout_on_next_action = function ()
            {
                //  get
                var _got_value = $R.storage__get('storedEvernoteLogoutOnNextAction');
            
                //  fail
                if (_got_value == 'yes') {}else { return false; }
                
                //  reset
                $R.storage__set('storedEvernoteLogoutOnNextAction', '');
                
                return true;
            };
            
        
        //  set logout!
        //  ===========
            $R.credentials__set_logout_on_next_action = function ()
            {
                $R.storage__set('storedEvernoteLogoutOnNextAction', 'yes');
            };
            
            
        //  get userInfoCache
        //  =================
            $R.credentials__getUserInfoCache = function ()
            {
                var _json = $R.storage__get('storedEvernoteUserInfo');
                if (_json > '') {}else { return false; }
                
                var _info = JSON.parse(_json);
                var _keys = ['user__id', 'user__shard_id', 'user__privilege', 'user__name', 'user__username', 'user__email', 'user__business_id', 'user__last_updated'];
                for (var _i=0, _ii=_keys.length; _i<_ii; _i++) { if (_info[_keys[_i]]) {}else { return false; } }
                
                return _info;
            };
        
            
        //  set userInfoCache
        //  =================
            $R.credentials__setUserInfoCache = function (_userInfo)
            {
                var _json = JSON.stringify(_userInfo);
                $R.storage__set('storedEvernoteUserInfo', _json);
            };
        
        
        //  delete userInfoCache
        //  ====================
            $R.credentials__deleteUserInfoCache = function ()
            {
                $R.storage__set('storedEvernoteUserInfo', '');
            };
        
        
        //  get translations
        //  ================
            $R.translation__get_items = function ()
            {
                for (var x in $R.translation__items)
                {
                    var _t = $R.translation__get_item(x);
                    if (_t > '') {}else { continue; }
                
                    $R.translation__items[x] = _t;
                }
            };
        
    
        
        //  namespace
        //  =========
            $R.$bootstrap =
            {
                /* predefined */
                'servers':                  false,
                'server_main':              '',     /* ends in slash */
                'server_china':             '',     /* ends in slash */
                
                /* set on load */
                'saved_server':             false,  /* main | china */
                'client_locale':            false,
                'has_chinese_locale':       false,
                'simulate_chinese_locale':  false,
                
                /* set on bootstrap() */
                'rpc__userStore':           false,
                'profiles':                 false,
                'profiles_as_string':       false,
                'profiles_as_string2':      false,
                'server':                   false,
                'remote_domain':            false,  /* ends in slash */
                'remote_domain_marketing':  false,  /* ends in slash */
                'connected':                false
            };
        
            
        //  servers
        //  =======
            $R.$bootstrap.servers = {
                'live':     { 'main': 'https://www.evernote.com/',      'china': 'https://app.yinxiang.com/' },
                'stage':    { 'main': 'https://stage.evernote.com/',    'china': 'https://stage-china.evernote.com/' }
            };
            //  /* alternate stage => 'https://stage-dev.corp.etonreve.com/' */
            //  $R.$bootstrap.servers['live'] = $R.$bootstrap.servers['stage'];
                
                
        //  include
        //  =======
                
            //  bootstrap
            //  =========
                $R.$bootstrap.bootstrap = function (_onSuccess, _onFailure)
                {
                    //  already connected
                    //  =================
                        if ($R.$bootstrap.connected) { _onSuccess(); return; }
                
                    //  figure out order
                    //  ================
                        var _order = [];
                        switch (true)
                        {
                            case ($R.$bootstrap.saved_server == 'main'):    _order = ['main', 'china']; break;
                            case ($R.$bootstrap.saved_server == 'china'):   _order = ['china', 'main']; break;
                            case ($R.$bootstrap.has_chinese_locale):        _order = ['china', 'main']; break;
                            case ($R.$bootstrap.simulate_chinese_locale):   _order = ['china', 'main']; break;
                            default:                                        _order = ['main', 'china']; break;
                        }
            
                    //  try connect to one
                    //  ==================
                        var _try_connect_to_one = function (_order_number)
                        {
                            //  invalid number; failed
                            //  ======================
                                if (_order[_order_number]) {}else { _onFailure('connection / invalid'); return; };
            
                            //  try current number
                            //  ==================
                                var _rpcBootstrapClient = new $R.JSONRpcClient(
                                    function ()
                                    { 
                                        //  error / timeout
                                        //  ===============
                                            if (this.UserStore) {}else { _try_connect_to_one(_order_number + 1); return; }
            
                                        //  set conected
                                        //  ============
                                            $R.$bootstrap.connected = true;
                                            $R.$bootstrap.rpc__userStore = this;
            
                                        //  get profiles
                                        //  ============
                                            $R.$bootstrap.rpc__userStore.UserStore.getBootstrapInfo(
                                                function (_rpc_result, _rpc_exception)
                                                {
                                                    var _bootstrapInfoResult = _rpc_result, _bootstrapInfoError = _rpc_exception;
                                                    
                                                    //  error
                                                    //  =====
                                                        if (_bootstrapInfoError)
                                                        {
                                                            _bootstrapInfoResult = {
                                                                'profiles': {
                                                                   'list': [ {
                                                                        'name':         'Evernote',
                                                                        'setName':      true,
                                                                        'setSettings':  true,
                                                                        'settings': {
                                                                            'marketingUrl': 'http://evernote.com',
                                                                            'serviceHost':  'www.evernote.com',
                                                                            'supportUrl':   'https://evernote.com/contact/support/'
                                                                        }
                                                                    } ] 
                                                                }
                                                            };
                                                        }
                                                    
                                                    //  result
                                                    //  ======
                                                    
                                                        //  set profiles
                                                        //  ============
                                                            $R.$bootstrap.profiles = _bootstrapInfoResult.profiles.list;
                                                        
                                                        //  profiles as string
                                                        //  ==================
                                                            $R.$bootstrap.profiles_as_string = '';
                                                            for (var zz=0,_zz=$R.$bootstrap.profiles.length; zz<_zz; zz++)
                                                                { $R.$bootstrap.profiles_as_string += '_' + $R.$bootstrap.getProfileName__short($R.$bootstrap.profiles[zz]); }
                                                            $R.$bootstrap.profiles_as_string = $R.$bootstrap.profiles_as_string.substr(1);
                                                            $R.$bootstrap.profiles_as_string2 = $R.$bootstrap.profiles_as_string.replace(/_/g, '-');
                                                        
                                                        //  select first
                                                        //  ============
                                                            $R.$bootstrap.server = $R.$bootstrap.getProfileName__long($R.$bootstrap.profiles[0]);
                                                            $R.$bootstrap.remote_domain = $R.$bootstrap['server_' + $R.$bootstrap.server];
                                                            $R.$bootstrap.remote_domain_marketing = $R.$bootstrap.profiles[0].settings.marketingUrl + '/';
                                                        
                                                        //  first different than saved -- switch
                                                        //  ==========================
                                                            if (true && ($R.$bootstrap.profiles_as_string == 'in_cn') && ($R.$bootstrap.server == 'main') && ($R.$bootstrap.saved_server == 'china'))
                                                            {
                                                                $R.$bootstrap.server = 'china';
                                                                $R.$bootstrap.remote_domain = $R.$bootstrap['server_' + 'china'];
                                                                $R.$bootstrap.remote_domain_marketing = $R.$bootstrap.profiles[1].settings.marketingUrl + '/';
                                                                $R.$bootstrap.profiles_as_string == 'cn_in';
                                                            }
                                                            else if (true && ($R.$bootstrap.profiles_as_string == 'cn_in') && ($R.$bootstrap.server == 'china') && ($R.$bootstrap.saved_server == 'main'))
                                                            {
                                                                $R.$bootstrap.server = 'main';
                                                                $R.$bootstrap.remote_domain = $R.$bootstrap['server_' + 'main'];
                                                                $R.$bootstrap.remote_domain_marketing = $R.$bootstrap.profiles[1].settings.marketingUrl + '/';
                                                                $R.$bootstrap.profiles_as_string == 'in_cn';
                                                            }
                                                        
                                                        //  run sucess
                                                        //  ==========
                                                            _onSuccess();
                                                },
                                                ($R.$bootstrap.simulate_chinese_locale ? 'zh_cn' : $R.$bootstrap.client_locale));
                                    }, 
                                    $R.$bootstrap['server_' + _order[_order_number]] + 'json');
                        };
            
                    //  try first
                    //  =========
                        _try_connect_to_one(0);
                };
            
            
            //  profiles
            //  ========
            
                $R.$bootstrap.getProfileName__short = function (_profile)
                {
                    switch (_profile.name.toLowerCase())
                    {
                        case 'evernote':            return 'in';
                        case 'evernote-china':      return 'cn';
                    //  case 'stage':               return 'in';
                    //  case 'stagedev':            return 'in';
                    //  case 'stage-china':         return 'cn';
                    }
                    return '';
                };
                
                $R.$bootstrap.getProfileName__long = function (_profile)
                {
                    switch (_profile.name.toLowerCase())
                    {
                        case 'evernote':            return 'main';
                        case 'evernote-china':      return 'china';
                    //  case 'stage':               return 'main';
                    //  case 'stagedev':            return 'main';
                    //  case 'stage-china':         return 'cn';
                    }
                    return '';
                };
            
            
            //  set locale
            //  ==========    
                $R.$bootstrap.setLocale = function (_browser_locale)
                {
                    //  which
                    var _locale = _browser_locale;
                        _locale = _locale.replace(/[-]/gi, '_');
                        _locale = _locale.replace(/\s+/gi, '');
                        _locale = _locale.toLowerCase();
                    
                    //   set
                    $R.$bootstrap.client_locale = _locale;
                    
                    //  chinese?
                    $R.$bootstrap.has_chinese_locale = ('|zh|zh_cn|zh_hans|zh_hans_cn|'.indexOf('|'+_locale+'|') > -1);
                };
            
            
            //  disconnect
            //  ==========
                $R.$bootstrap.disconnect = function ()
                {
                    $R.$bootstrap['connected'] =      false;
                    $R.$bootstrap['profiles'] =       false;
                    $R.$bootstrap['server'] =         false;
                    $R.$bootstrap['remote_domain'] =  false;
                    $R.$bootstrap['rpc__userStore'] = false;
                };
            
            
            //  initialize
            //  ==========
                $R.$bootstrap.initialize = function ()
                {
                    //  set to live
                    $R.$bootstrap.set_servers_to_live();
                
                    //  set locale
                    $R.$bootstrap.setLocale(window.navigator.language);
            
                    //  saved server
                    if ($R.credentials__get && $R.credentials__get())
                    {
                        var _credentials = $R.credentials__get();
                        if (_credentials && _credentials.server) { $R.$bootstrap.saved_server = _credentials.server; }
                    }
                };
            
            
            //  QA
            //  ==
            
                $R.$bootstrap.set_servers_to_stage = function ()
                {
                    $R.$bootstrap['server_main'] = $R.$bootstrap.servers['stage']['main'];
                    $R.$bootstrap['server_china'] = $R.$bootstrap.servers['stage']['china'];
                };
                
                $R.$bootstrap.set_servers_to_live = function ()
                {
                    $R.$bootstrap['server_main'] = $R.$bootstrap.servers['live']['main'];
                    $R.$bootstrap['server_china'] = $R.$bootstrap.servers['live']['china'];
                };
            
                $R.$bootstrap.set_simulate_chinese_locale = function () { $R.$bootstrap.simulate_chinese_locale = true; };
                $R.$bootstrap.set_do_not_simulate_chinese_locale = function () { $R.$bootstrap.simulate_chinese_locale = false; };
                
        
        
        //  namespace
        //  =========
            $R.$remote =
            {
                /* predefined */
                /* ========== */
                    'api__key':                             'en-clearly-xauth-new',
                    'api__secret':                          '38f4e71b0172afbb',
        
                /* set on init */
                /* =========== */
                    'setting__related_notes':               '',
                    'setting__smart_filing':                '',
                    'setting__smart_filing_for_business':   '',
                    'setting__clip_tag':                    '',
                    'setting__clip_notebook':               '',
                    'setting__clip_notebook_guid':          '',
                    'setting__open_notes_in':               '',
                
                /* stores */
                /* ====== */
                    'store__id_to_guid':                    {},
                    'store__id_to_info':                    {},
                    'store__id_to_recommendation':          {},
        
                /* set on login */
                /* ============ */
                    'rpc__userStore':                       false,
                    'rpc__noteStore':                       false,
                    'user__authToken':                      false,
                    'user__expires':                        false,
                    'user__id':                             false,
                    'user__shardId':                        false,
                    'user__privilege':                      false,
                    'user__username':                       false,
                    'user__email':                          false,
                    'is__connected':                        false,
                    'is__loggedIn':                         false,
                    'twoFactor__authToken':                 false,
                    'twoFactor__deliveryHint':              false,
        
                /* business */
                /* ======== */
                    'is__business':                         false,
                    'business__authToken':                  false,
                    'business__expires':                    false,
                    'business__shardId':                    false,
                    'business__noteStore':                  false
            };
            
            
        //  include
        //  =======
        
            
            //  connect
            //  =======
                $R.$remote.connect = function (_onSuccess, _onFailure)
                {
                    //  bootstrap first
                    //  ===============
                        $R.$bootstrap.bootstrap(
                            function ()
                            {
                                //  bootstrap succesfull
                                //  ====================
                                try
                                {
                                    var _rpcUserStoreClient = new $R.JSONRpcClient(
                                        function ()
                                        {
                                            //  error / timeout
                                            //  ===============
                                                if (this.UserStore) {}else { _onFailure('connection / invalid'); return; }
                                        
                                            //  set conected
                                            //  ============
                                                $R.$remote.is__connected = true;
                                                $R.$remote.rpc__userStore = this;
                                            
                                            //  run success
                                            //  ===========
                                                _onSuccess();
                                        }, 
                                        $R.$bootstrap.remote_domain + 'json');
                                }
                                catch (_error) { _onFailure('connection / invalid'); return; }
                            },
                            function () { _onFailure('connection / invalid'); });
                };
            
            
            //  refresh
            //  =======
                $R.$remote.refresh_settings = function ()
                {
                    //  shortcuts
                    //  =========
                        var _s = $R.saved__get_vars(),
                            _r = $R.$remote,
                            _d = $R.decode;
            
                    //  update
                    //  ======
                        $R.$remote.setting__related_notes =             _d(_s['related_notes']);
                        $R.$remote.setting__smart_filing =              _d(_s['smart_filing']);
                        $R.$remote.setting__smart_filing_for_business = _d(_s['smart_filing_for_business']);
                        $R.$remote.setting__open_notes_in =             _d(_s['open_notes_in']);
                        $R.$remote.setting__clip_tag =                  _d(_s['clip_tag']);
                        $R.$remote.setting__clip_notebook =             _d(_s['clip_notebook']);
                        $R.$remote.setting__clip_notebook_guid =        _d(_s['clip_notebook_guid']);
                };
            
        
            
            //  not expired
            //  ===========
                $R.$remote.is__notExpired = function ()
                {
                    //  invalid
                    switch (true)
                    {
                        case (!$R.$remote.is__connected):
                        case (!$R.$remote.is__loggedIn):
                        case (!$R.$remote.user__expires):
                            return false;
                    }
                    
                    //  now
                    var _now = (new Date()).getTime();
            
                    //  not within 3 minutes of expiration
                    if (_now > ($R.$remote.user__expires - (3 * 60 * 1000))) { return false; }
                    
                    //  check business too
                    if ($R.$remote.is__business)
                    {
                        //  not within 3 minutes of expiration
                        if (_now > ($R.$remote.business__expires - (3 * 60 * 1000))) { return false; }
                        
                        //  business too, is not expired
                        return true;
                    }
                    else
                    {
                        //  not business, and user not expired
                        return true;
                    }
                    
                    return false;
                };
            
                
            //  login
            //  =====
                $R.$remote.loginLongSession = function (_user, _pass, _device_id, _device_description, _onSuccess, _onFailure)
                {
                    //  login function
                    //  ===============
                        var _loginFunction = function ()
                        {
                            //  login
                            //  =====
                                $R.$remote.rpc__userStore.UserStore.authenticateLongSession(
                                    function (_rpc_result, _rpc_exception)
                                    {
                                        var _loginResult = _rpc_result, _loginError = _rpc_exception;
                                        //console.log(_loginResult);
                                        
                                        //  error
                                        //  =====
                                        
                                            if (_loginError)
                                            {
                                                //  unknown error
                                                //  =============
                                                    switch (true)
                                                    {
                                                        case (!(_loginError.trace)):
                                                        case (!(_loginError.trace.indexOf)):
                                                        case (!(_loginError.trace.indexOf(')') > -1)):
                                                            _onFailure('login / exception / no trace');
                                                            return;
                                                    }
                                                
                                                //  figure out error
                                                //  ================
                                                    var _trace = _loginError.trace.substr(0, _loginError.trace.indexOf(')')+1);
                                                    switch (_trace)
                                                    {
                                                        case 'EDAMUserException(errorCode:INVALID_AUTH, parameter:username)':
                                                            _onFailure('email');
                                                            return;
            
                                                        case 'EDAMUserException(errorCode:INVALID_AUTH, parameter:password)':
                                                            _onFailure('password');
                                                            return;
            
                                                        case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:password)':
                                                            _onFailure('password-reset');
                                                            return;
                                                    }
            
                                                //  could not figure out error
                                                //  ==========================
                                                    _onFailure('login / exception / unknown');
                                                    return;
                                            }
                                            
                                        
                                        //  result
                                        //  ======
                                         
                                            //  two factor
                                            //  ==========
                                            
                                                if (_loginResult.secondFactorRequired)
                                                {
                                                    //  set
                                                    $R.$remote.twoFactor__authToken = _loginResult.authenticationToken;
                                                    $R.$remote.twoFactor__deliveryHint = (_loginResult.secondFactorDeliveryHint ? _loginResult.secondFactorDeliveryHint : '');
                                                    $R.$remote.twoFactor__username = _user;
                                                
                                                    //  trigger
                                                    _onFailure('two-factor');
                                                    
                                                    //  return
                                                    return;
                                                }
                                         
                                            
                                            //  check
                                            //  =====
                                                switch (true)
                                                {
                                                    case (!(_loginResult.authenticationToken)):
                                                    case (!(_loginResult.user)):
                                                    case (!(_loginResult.user.id)):
                                                    case (!(_loginResult.user.shardId)):
                                                        _onFailure('login / invalid result');
                                                        return;
                                                }
            
                                                
                                            //  loginWithAuthToken
                                            //  ==================
                                                $R.credentials__deleteUserInfoCache();
                                                $R.$remote.loginWithAuthToken(
                                                    _loginResult.authenticationToken,
                                                    _onSuccess,
                                                    _onFailure);
                                                return;
                                    },
                                    _user,
                                    _pass,
                                    $R.$remote.api__key,
                                    $R.$remote.api__secret,
                                    _device_id,
                                    _device_description,
                                    true);
                        };
            
                        
                    //  already connected, connect, or error
                    //  =====================================
                        if ($R.$remote.is__connected)
                        {
                            //  do
                            _loginFunction();
                        }
                        else
                        {
                            //  connect
                            $R.$remote.connect(
                                function () { _loginFunction(); },
                                function () { _onFailure('connection / invalid'); });
                        }
                };
            
            
            //  login :: second factor
            //  ======================
                $R.$remote.loginLongSessionSecondFactor = function (_temp_auth, _code, _device_id, _device_description, _onSuccess, _onFailure)
                {
                    //  login function
                    //  ===============
                        var _loginFunction = function ()
                        {
                            //  login
                            //  =====
                                $R.$remote.rpc__userStore.UserStore.completeTwoFactorAuthentication(
                                    function (_rpc_result, _rpc_exception)
                                    {
                                        var _loginResult = _rpc_result, _loginError = _rpc_exception;
                                    
                                        // console.log(_loginResult);
                                        // console.log(_loginError);
                                    
                                        //  error
                                        //  =====
                                        
                                            if (_loginError)
                                            {
                                                //  unknown error
                                                //  =============
                                                    switch (true)
                                                    {
                                                        case (!(_loginError.trace)):
                                                        case (!(_loginError.trace.indexOf)):
                                                        case (!(_loginError.trace.indexOf(')') > -1)):
                                                            _onFailure('login / exception / no trace');
                                                            return;
                                                    }
                                                
                                                //  figure out error
                                                //  ================
                                                    var _trace = _loginError.trace.substr(0, _loginError.trace.indexOf(')')+1);
                                                    switch (_trace)
                                                    {
                                                        case 'EDAMUserException(errorCode:INVALID_AUTH, parameter:oneTimeCode)':
                                                            _onFailure('code');
                                                            return;
            
                                                        case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                            _onFailure('timeout');
                                                            return;
                                                    }
            
                                                //  could not figure out error
                                                //  ==========================
                                                    _onFailure('login / exception / unknown');
                                                    return;
                                            }
                                            
                                        
                                        //  result
                                        //  ======
                                         
                                            //  check
                                            //  =====
                                                switch (true)
                                                {
                                                    case (!(_loginResult.authenticationToken)):
                                                    case (!(_loginResult.user)):
                                                    case (!(_loginResult.user.id)):
                                                    case (!(_loginResult.user.shardId)):
                                                        _onFailure('login / invalid result');
                                                        return;
                                                }
            
                                                
                                            //  loginWithAuthToken
                                            //  ==================
                                                $R.credentials__deleteUserInfoCache();
                                                $R.$remote.loginWithAuthToken(
                                                    _loginResult.authenticationToken,
                                                    _onSuccess,
                                                    _onFailure);
                                                return;
                                    },
                                    _temp_auth,
                                    _code,
                                    _device_id,
                                    _device_description);
                        };
            
                        
                    //  already connected, connect, or error
                    //  =====================================
                        if ($R.$remote.is__connected)
                        {
                            //  do
                            _loginFunction();
                        }
                        else
                        {
                            //  connect
                            $R.$remote.connect(
                                function () { _loginFunction(); },
                                function () { _onFailure('connection / invalid'); });
                        }
                };
            
            
            //  login
            //  =====
                $R.$remote.loginWithAuthToken = function (_authToken, _onSuccess, _onFailure)
                {
                    //  fail fast
                    //  =========
                        if (_authToken > '') {}else { _onFailure('getUser / exception / no token'); return; }
                
                    //  login sucess
                    //  ============
                        var _doSuccess = function () { _onSuccess(); };
                
                    //  set token
                    //  =========
                        $R.$remote.user__authToken = _authToken;
                                                
                    //  get userInfo
                    //  ============
                        $R.$remote.updateUserInfo(
                            function ()
                            {
                                //  officially logged-in
                                //  ====================
                                    $R.$remote.user__expires =      (new Date()).getTime() + (1000 * 60 * 60 * 24 * 1);     //  one day, in milliseconds
                                    $R.$remote.is__loggedIn =       true;
                            
                                //  note store -- user first; then, if needed, business
                                //  ==========
                                    var _rpcNoteStoreClient = new $R.JSONRpcClient(
                                        function ()
                                        {
                                            //  error / timeout
                                            //  ===============
                                                if (this.NoteStore) {}else { _onFailure('getUser / note store / invalid'); return; }
            
                                            //  set connected
                                            //  =============
                                                $R.$remote.rpc__noteStore = this;
            
                                            //  not business
                                            //  ============
                                                if ($R.$remote.user__businessId > 0) {}else { _doSuccess(); return; }
                        
                                            //  is business -- try login
                                            //  ========================
                                                $R.$remote.loginToBusiness(_doSuccess, _doSuccess);
                                        },
                                        $R.$bootstrap.remote_domain + 'shard/' + $R.$remote.user__shardId + '/json');
                            },
                            _onFailure);
                };
            
            
            //  login to business
            //  =================
                $R.$remote.loginToBusiness = function (_onSuccess, _onFailure)
                {
                    //  login sucess
                    //  ============
                        var _doSuccess = function () { _onSuccess(); };
            
                    //  authenticate to business
                    //  ========================
                        $R.$remote.rpc__userStore.UserStore.authenticateToBusiness(
                            function (_rpc_result, _rpc_exception)
                            {
                                var _loginResultBusiness = _rpc_result, _loginErrorBusiness = _rpc_exception;
                                
                                //  error
                                //  =====
                                    if (_loginErrorBusiness) { _doSuccess(); return; }
                                    
                                //  result
                                //  ======
                                    
                                    //  check
                                    //  =====
                                        switch (true)
                                        {
                                            case (!(_loginResultBusiness.authenticationToken)):
                                            case (!(_loginResultBusiness.user)):
                                            case (!(_loginResultBusiness.user.shardId)):
                                                _doSuccess();
                                                return;
                                        }
                                        //  console.log(_loginResultBusiness);
            
                                    //  set business info
                                    //  =================
                                        $R.$remote.business__authToken =  _loginResultBusiness.authenticationToken;
                                        $R.$remote.business__expires =    _loginResultBusiness.expiration;
            
                                        $R.$remote.business__shardId =    _loginResultBusiness.user.shardId;
                                        
                                        //  console.log(_loginResultBusiness);
                                        
                                        
                                    //  note store
                                    //  ==========
                                        var _rpcNoteStoreClientBusiness = new $R.JSONRpcClient(
                                            function ()
                                            {
                                                //  error / timeout
                                                //  ===============
                                                    if (this.NoteStore) {}else { _onFailure(); return; }
            
                                                //  set connected
                                                //  =============
                                                    $R.$remote.is__business = true;
                                                    $R.$remote.business__noteStore = this;
                                                    
                                                //  success
                                                //  =======
                                                    _doSuccess();
                                            },
                                            $R.$bootstrap.remote_domain + 'shard/' + $R.$remote.business__shardId + '/json');
                            },
                            $R.$remote.user__authToken);
                };
            
            //  token
            //  =====
                $R.$remote.logoutWithAuthToken = function (_authToken)
                {
                    try { $R.$remote.rpc__userStore.UserStore.revokeLongSession(_authToken); } catch (e) { }
                };
            
            
            //  logout
            //  ======
                $R.$remote.logout = function ()
                {
                    $R.$remote['is__connected'] =       false;
                    $R.$remote['is__loggedIn'] =        false;
                    $R.$remote['is__business'] =        false;
            
                    $R.$remote['rpc__userStore'] =      false;
                    $R.$remote['rpc__noteStore'] =      false;
            
                    $R.$remote['user__authToken'] =     false;
                    $R.$remote['user__expires'] =       false;
                    $R.$remote['user__id'] =            false;
                    $R.$remote['user__shardId'] =       false;
                    $R.$remote['user__privilege'] =     false;
                    $R.$remote['user__username'] =      false;
                    $R.$remote['user__email'] =         false;
            
                    $R.$remote['business__noteStore'] = false;
                    $R.$remote['business__authToken'] = false;
                    $R.$remote['business__expires'] =   false;
                    $R.$remote['business__shardId'] =   false;
                };
            
            
            //  QA
            //  ==
                $R.$remote.disconnect = function () { $R.$remote.logout(); };
                
            
            //  login
            //  =====
                $R.$remote.updateUserInfo__getFromServer = function (_onSuccess, _onFailure)
                {
                    $R.$remote.rpc__userStore.UserStore.getUser(
                        function (_rpc_result, _rpc_exception)
                        {
                            var _getUserResult = _rpc_result, _getUserError = _rpc_exception;
                        
                            if (_getUserError)
                            {
                                //  could not figure out error
                                //  ==========================
                                    _onFailure('getUser / exception / unknown');
                                    return;
                            }
                                
                            switch (true)
                            {
                                case (!(_getUserResult)):
                                case (!(_getUserResult.id)):
                                case (!(_getUserResult.shardId)):
                                    _onFailure('getUser / invalid result');
                                    return;
                            }
            
                            $R.$remote.user__id =           _getUserResult.id;
                            $R.$remote.user__shardId =      _getUserResult.shardId;
                            $R.$remote.user__privilege =    _getUserResult.privilege.value;
                            $R.$remote.user__name =         _getUserResult.name;
                            $R.$remote.user__username =     _getUserResult.username;
                            $R.$remote.user__email =        _getUserResult.email;
                            $R.$remote.user__businessId =   ((true && _getUserResult.accounting && _getUserResult.accounting.businessId && (_getUserResult.accounting.businessId > 0)) ? _getUserResult.accounting.businessId : 0);
                            $R.$remote.user__lastUpdated =  _getUserResult.updated;
                                
                            _onSuccess(); 
                        },
                        $R.$remote.user__authToken);
                };
            
                $R.$remote.updateUserInfo = function (_onSuccess, _onFailure)
                {
                    //  current cache
                    //  =============
                        var _currentCache = $R.credentials__getUserInfoCache();
                    
                    //  get and cache userInfo
                    //  =================
                        var _getAndCacheUserInfo = function ()
                        {
                            $R.$remote.updateUserInfo__getFromServer(
                                function ()
                                {
                                    //  the new cache
                                    var _newCache = {
                                        'user__id':           $R.$remote.user__id,
                                        'user__shard_id':     $R.$remote.user__shardId,
                                        'user__privilege':    $R.$remote.user__privilege,
                                        'user__name':         $R.$remote.user__name,
                                        'user__username':     $R.$remote.user__username,
                                        'user__email':        $R.$remote.user__email,
                                        'user__business_id':  $R.$remote.user__businessId,
                                        'user__last_updated': $R.$remote.user__lastUpdated
                                    };
                                    
                                    //  save cache
                                    $R.credentials__setUserInfoCache(_newCache);
                                    
                                    //  success
                                    _onSuccess();
                                },
                                _onFailure);
                        };
                    
                    //  get syncStateAndCompareCache
                    //  ============================
                        var _getSyncStateAndCompareCacheDate = function ()
                        {
                            var _rpcNoteStoreClient_dummy = new $R.JSONRpcClient(
                                function ()
                                {
                                    //  error / timeout
                                    //  ===============
                                        if (this.NoteStore) {}else { _onFailure('getUser / note store / invalid'); return; }
            
                                    //  getSyncState
                                    //  ============
                                        this.NoteStore.getSyncState(
                                            function (_rpc_result, _rpc_exception)
                                            {
                                                var _last__online = ((_rpc_result && _rpc_result.lastUpdated && (_rpc_result.lastUpdated > 0)) ? _rpc_result.lastUpdated : 0);
                                                var _last__cached = ((_currentCache.user__last_updated && (_currentCache.user__last_updated > 0)) ? _currentCache.user__last_updated : 0);
                                    
                                                //  get from online, or set cached
                                                if ((_last__online > _last__cached) || ((_last__online + _last__cached) == 0))
                                                {
                                                    _getAndCacheUserInfo();
                                                }
                                                else
                                                {
                                                    //  set from local cache
                                                    //  ====================
                                                        $R.$remote.user__id =           _currentCache['user__id'];
                                                        $R.$remote.user__shardId =      _currentCache['user__shard_id'];
                                                        $R.$remote.user__privilege =    _currentCache['user__privilege'];
                                                        $R.$remote.user__name =         _currentCache['user__name'];
                                                        $R.$remote.user__username =     _currentCache['user__username'];
                                                        $R.$remote.user__email =        _currentCache['user__email'];
                                                        $R.$remote.user__businessId =   _currentCache['user__business_id'];
                                                        $R.$remote.user__lastUpdated =  _currentCache['user__last_updated'];
            
                                                    //  success
                                                    //  =======
                                                        _onSuccess();
                                                }
                                            }, 
                                            __readable_by_evernote.$remote.user__authToken);
            
                                },
                                $R.$bootstrap.remote_domain + 'shard/' + _currentCache['user__shard_id'] + '/json');
                        };
            
                    //  getUserInfo
                    //  ===========
                        var _getUserInfo = function ()
                        {
                            if (_currentCache)
                            {
                                _getSyncStateAndCompareCacheDate();
                            }
                            else
                            {
                                _getAndCacheUserInfo();            
                            }
                        };
                    
                    //  already connected, connect, or error
                    //  ====================================
                        if ($R.$remote.is__connected)
                        {
                            //  do
                            _getUserInfo();
                        }
                        else
                        {
                            //  connect
                            $R.$remote.connect(
                                function () { _getUserInfo(); },
                                function () { _onFailure('connection / invalid'); });
                        }
                };
            
        
            
            //  clip
            //  ====
                $R.$remote.clip = function (_id, _url, _title, _body, _onSuccess, _onFailure)
                {
                    //  preliminary check
                    //  =================
                        switch (true)
                        {
                            case (!($R.$remote.rpc__noteStore)):
                            case (!($R.$remote.rpc__noteStore.NoteStore)):
                            case (!($R.$remote.is__connected)):
                            case (!($R.$remote.is__loggedIn)):
                            case (!($R.$remote.is__notExpired())):
                                _onFailure('login');
                                return;
                        }
            
            
                    //  fix title -- simple trim
                    //  =========
                        _title = ((_title > '') ? _title.replace(/^\s+|\s+$/gm, '') : _url);
            
                    //  fix title -- must match "^[^\p{Cc}\p{Z}]([^\p{Cc}\p{Zl}\p{Zp}]{0,253}[^\p{Cc}\p{Z}])?$"
                    //  =========
                        //  http://www.unicode.org/reports/tr18/#General_Category_Property
                        //  XRegExp Unicode categories: http://xregexp.com/addons/unicode/unicode-categories.js
                            //  Cc: "0000-001F 007F-009F"
                            //  Z : "0020 00A0 1680 180E 2000-200A 2028 2029 202F 205F 3000"
                            //  Zl: "2028"
                            //  Zp: "2029"
                        //  example: http://espn.go.com/blog/playbook/fandom/post/_/id/20240/carmelo-anthonys-other-love-boxing 
                            
                        var _regex__cc_z__start = /^([\u0000-\u001F\u007F-\u009F]|[\u0020\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000])/i,
                            _regex__cc_z__end =    /([\u0000-\u001F\u007F-\u009F]|[\u0020\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000])$/i,
                            _regex__cc_zl_zp =     /([\u0000-\u001F\u007F-\u009F]|[\u2028]|[\u2029])/gi;
                        
                        //  start: ^[^\p{Cc}\p{Z}]
                        while (_title.match(_regex__cc_z__start) != null) { _title = _title.replace(_regex__cc_z__start, ''); }
                        
                        //  end: [^\p{Cc}\p{Z}])?$
                        while (_title.match(_regex__cc_z__end) != null) { _title = _title.replace(_regex__cc_z__end, ''); }
                        
                        //  ([^\p{Cc}\p{Zl}\p{Zp}]{0,253}
                        _title = _title.replace(_regex__cc_zl_zp, '');
                        
                    //  fix title -- length
                    //  =========
                        _title = _title.substr(0, 255);
                    
            
                    //  smart filing enabled -- but the recommendation hasn't been requested yet; turn around
                    //  ====================
                        if ($R.$remote.setting__smart_filing == 'disabled') {}else
                        {
                            switch (true)
                            {
                                case ($R.$remote.setting__smart_filing == 'enabled'):
                                case ($R.$remote.setting__smart_filing == 'just_notebooks'):
                                case ($R.$remote.setting__smart_filing == 'just_tags'):
                                    if ($R.$remote.store__id_to_recommendation[_id]) {}else
                                    {
                                        //  get recommendation
                                        //  ==================
                                            $R.$remote.get_recommendation(
                                                _id,
                                                _url,
                                                _body,
                                                function ()
                                                {
                                                    //  do it again; recommendatin was added to the global store
                                                    $R.$remote.clip(_id, _url, _title, _body, _onSuccess, _onFailure);
                                                },
                                                function ()
                                                {
                                                    //  set to dummy; only try this once
                                                    $R.$remote.store__id_to_recommendation[_id] = true;
                                                    
                                                    //  do it again -- with no smart filing
                                                    $R.$remote.clip(_id, _url, _title, _body, _onSuccess, _onFailure);
                                                });
                                        
                                        //  turn around
                                        //  ===========
                                            return;
                                    }
                                    break;
                            }
                        }
                    
                        
                    //  the finling info object
                    //  =======================
                    
                        var _filingInfo = {
                            'source':                   'Clearly',
                            
                            'notebookGuid':             $R.$remote.setting__clip_notebook_guid,
                            'notebookName':             false,
                            'createNotebook':           false,
                            
                            'tagNameList':              [],
                            'tagNameObject':            {},
                            'tagNameRecommendation':    false,
                            'createTags':               true
                        };
                        
                        //  previously clipped
                        //  ==================
                            if (_id in $R.$remote.store__id_to_guid) { _filingInfo['originalNoteGuid'] = $R.$remote.store__id_to_guid[_id]; }
                        
                        //  tags from options
                        //  =================
                            var _tags_from_options = $R.$remote.setting__clip_tag.split(',');
                            for (var i=0, _i=_tags_from_options.length, _t=false; i<_i;i++)
                            {
                                _t = _tags_from_options[i].replace(/^ /, '').replace(/ $/, '');
                                if (_t > '' && !(_filingInfo.tagNameObject[_t]))
                                {
                                    _filingInfo.tagNameList.push(_t);
                                    _filingInfo.tagNameObject[_t] = true;
                                }
                            }
            
                        //  personal smart-filing
                        //  =====================
                        
                            //  notebook
                            if (true && ($R.$remote.setting__smart_filing == 'enabled' || $R.$remote.setting__smart_filing == 'just_notebooks') && $R.$remote.store__id_to_recommendation[_id] && $R.$remote.store__id_to_recommendation[_id].notebook && $R.$remote.store__id_to_recommendation[_id].notebook.guid && $R.$remote.store__id_to_recommendation[_id].notebook.name)
                            {
                                _filingInfo['notebookGuid'] = $R.$remote.store__id_to_recommendation[_id].notebook.guid;
                                _filingInfo['notebookName'] = $R.$remote.store__id_to_recommendation[_id].notebook.name;
                            }
                        
                            //  tags
                            if (true && ($R.$remote.setting__smart_filing == 'enabled' || $R.$remote.setting__smart_filing == 'just_tags') && $R.$remote.store__id_to_recommendation[_id] && $R.$remote.store__id_to_recommendation[_id].tags && $R.$remote.store__id_to_recommendation[_id].tags.list && $R.$remote.store__id_to_recommendation[_id].tags.list.length)
                            {
                                for (var i=0, _i=$R.$remote.store__id_to_recommendation[_id].tags.list.length, _t=false; i<_i;i++)
                                {
                                    _t = $R.$remote.store__id_to_recommendation[_id].tags.list[i].name;
                                    if (_t > '' && !(_filingInfo.tagNameObject[_t]))
                                    {
                                        _filingInfo.tagNameList.push(_t);
                                        _filingInfo.tagNameObject[_t] = true;
                                    }
                                }
                            }
                            
                        //  business smart-filing
                        //  =====================
                        
                            //  notebook
                            if (true && ($R.$remote.setting__smart_filing == 'enabled' || $R.$remote.setting__smart_filing == 'just_notebooks') && ($R.$remote.setting__smart_filing_for_business == 'enabled') && $R.$remote.is__business && $R.$remote.store__id_to_recommendation[_id] && $R.$remote.store__id_to_recommendation[_id].businessRecommendation && $R.$remote.store__id_to_recommendation[_id].businessRecommendation.notebook && $R.$remote.store__id_to_recommendation[_id].businessRecommendation.notebook.guid && $R.$remote.store__id_to_recommendation[_id].businessRecommendation.notebook.name)
                            {
                                _filingInfo['notebookGuid'] = $R.$remote.store__id_to_recommendation[_id].businessRecommendation.notebook.guid;
                                _filingInfo['notebookName'] = $R.$remote.store__id_to_recommendation[_id].businessRecommendation.notebook.name;
                            }
                        
                    //  try and clip
                    //  ============
            
                        //  final info
                        //  ==========
                            //console.log('filing info');
                            //console.log(_filingInfo);
                    
                        //  clip do
                        //  =======
                            var _clip_do = function (_do_filingInfo, _to_business)
                            {
                                //  which?
                                //  ======
                                    var _noteStore = (_to_business ? $R.$remote.business__noteStore : $R.$remote.rpc__noteStore),
                                        _authToken = (_to_business ? $R.$remote.business__authToken : $R.$remote.user__authToken);
                                    
                                //  filing info -- for business, ignore tags
                                //  ===========
                                
                                    //  properties
                                    var _actualFilingInfoProperties = [ 'source', 'notebookGuid', 'originalNoteGuid' ];
                                    if (_to_business) {}else
                                    {
                                        _actualFilingInfoProperties.push('tagNameList');
                                        _actualFilingInfoProperties.push('createTags');
                                    }
                                    
                                    //  copy to new filingInfo object
                                    var _actualFilingInfo = {};
                                    for (var z=0, _z=_actualFilingInfoProperties.length, _p=false; z<_z; z++)
                                    {
                                        _p = _actualFilingInfoProperties[z];
                                        if (_do_filingInfo[_p]) { _actualFilingInfo[_p] = _do_filingInfo[_p]; }
                                    }
                                    //  console.log(_actualFilingInfo);
                                    
                                //  clip
                                //  ====
                                    _noteStore.NoteStoreExtra.clipNote(
                                        function (_rpc_result, _rpc_exception)
                                        {
                                            var _clipResult = _rpc_result, _clipError = _rpc_exception;
                                        
                                            //  error
                                            //  =====
                                            
                                                if (_clipError)
                                                {
                                                    //  Firebug.Console.log(_clipError);
                                                    //  console.log(_clipError);
                                                    
                                                    //  unknown error
                                                    //  =============
                                                        switch (true)
                                                        {
                                                            case (!(_clipError.trace)):
                                                            case (!(_clipError.trace.indexOf)):
                                                            case (!(_clipError.trace.indexOf(')') > -1)):
                                                                _onFailure('clip / exception / no trace');
                                                                return;
                                                        }
                                                    
                                                    //  figure out error
                                                    //  ================
                                                        var _trace = _clipError.trace.substr(0, _clipError.trace.indexOf(')')+1);
                                                        switch (_trace)
                                                        {
                                                            case 'EDAMUserException(errorCode:BAD_DATA_FORMAT, parameter:authenticationToken)':
                                                            case 'EDAMSystemException(errorCode:INVALID_AUTH, message:authenticationToken)':
                                                            case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                                _onFailure('login');
                                                                return;
                                                        }
            
                                                    //  could not figure out error
                                                    //  ==========================
                                                        _onFailure('clip / exception / unknown');
                                                        return;
                                                }
                                                
                                            //  result
                                            //  ======
            
                                                //  check
                                                //  =====
                                                    switch (true)
                                                    {
                                                        case (!(_clipResult > '')):
                                                        case (!(_clipResult.split('-').length == 5)):
                                                            _onFailure('clip / invalid result');
                                                            return;
                                                    }
                                                    
                                                //  store this version
                                                //  ==================
                                                    
                                                    //  guid
                                                    $R.$remote.store__id_to_guid[_id] = _clipResult;
                                                    
                                                    //  other details
                                                    $R.$remote.store__id_to_info[_id] = {
                                                        'guid':             $R.$remote.store__id_to_guid[_id],
                                                        'tag_names':        (_do_filingInfo['tagNameList'] ? _do_filingInfo['tagNameList'] : []),
                                                        'notebook_name':    (_do_filingInfo['notebookName'] ? _do_filingInfo['notebookName'] : ''),
                                                        'notebook_guid':    (_do_filingInfo['notebookGuid'] ? _do_filingInfo['notebookGuid'] : '')
                                                    };
                                                    
                                                    //  urls
                                                    var _n = $R.$remote.store__id_to_info[_id], _nURL = $R.$remote.get_note_link(_to_business, _n.guid, _n.notebook_guid);
                                                    $R.$remote.store__id_to_info[_id]['url_view'] = _nURL;
                                                    $R.$remote.store__id_to_info[_id]['url_edit'] = _nURL;
                                                    
                                                //  success
                                                //  =======
                                                    _onSuccess();
                                        },
                                        _authToken,
                                        _actualFilingInfo,
                                        _title,
                                        _url,
                                        _body);
                            };
                                
                                
                        //  do the clip -- but where?
                        //  ===========
                            
                            //  the fallabck
                            //  ============
                                var _clip_to_user_default_notebook = function (_default_filingInfo)
                                {
                                    $R.$remote.rpc__noteStore.NoteStore.getDefaultNotebook(
                                        function (_rpc_result, _rpc_exception)
                                        {
                                            var _getResult = _rpc_result, _getError = _rpc_exception;
                                            if (true && !(_getError) && _getResult && _getResult.guid && _getResult.name)
                                            {
                                                //  found default notebook
                                                //  ======================
                                                    _default_filingInfo['notebookGuid'] = _getResult.guid;
                                                    _default_filingInfo['notebookName'] = _getResult.name;
                                                    _clip_do(_default_filingInfo, false);
                                            }
                                            else
                                            {
                                                //  didn't find default notebook
                                                //  ============================
                                                    _default_filingInfo['notebookName'] = '';
                                                    delete _default_filingInfo['notebookGuid'];
                                                    _clip_do(_default_filingInfo, false);
                                            }
                                        },
                                        $R.$remote.user__authToken);
                                };
                                
                                
                            //  clip to shared notebook
                            //  =======================
                                var _clip_to_shared_notebook_or_user_default_notebook = function (_filingInfo)
                                {
                                };
            
                                
                            //  straight to user's default notebook
                            //  ===================================
                                if (_filingInfo['notebookGuid'] > '') {}else { _clip_to_user_default_notebook(_filingInfo); return; }
            
                            
                            //  try one of the user's notebooks
                            //  ===============================
                                $R.$remote.rpc__noteStore.NoteStore.getNotebook(
                                    function (_rpc_result, _rpc_exception)
                                    {
                                        var _getResult = _rpc_result, _getError = _rpc_exception;
                                        if (true && !(_getError) && _getResult && _getResult.guid && _getResult.name)
                                        {
                                            //  found user's notebook
                                            //  =====================
                                                _filingInfo['notebookName'] = _getResult.name;
                                                _clip_do(_filingInfo, false);
                                        }
                                        else if ($R.$remote.is__business)
                                        {
                                            //  try one of the user's business notebooks -- selected with proper guid
                                            //  ========================================
                                                $R.$remote.business__noteStore.NoteStore.getNotebook(
                                                    function (_rpc_result, _rpc_exception)
                                                    {
                                                        var _getResult = _rpc_result, _getError = _rpc_exception;
                                                        if (true && !(_getError) && _getResult && _getResult.guid && _getResult.name)
                                                        {
                                                            //  found business notebook
                                                            //  =======================
                                                                _filingInfo['notebookName'] = _getResult.name;
                                                                _clip_do(_filingInfo, true);
                                                        }
                                                        else
                                                        {
                                                            //  user's default notebook
                                                            _clip_to_user_default_notebook(_filingInfo);
                                                        }
                                                    },
                                                    $R.$remote.business__authToken,
                                                    _filingInfo['notebookGuid']);
                                        }
                                        else
                                        {
                                            //  user's default notebook
                                            _clip_to_user_default_notebook(_filingInfo);
                                        }
                                    },
                                    $R.$remote.user__authToken,
                                    _filingInfo['notebookGuid']);
                };
            
            
            //  recommendation
            //  ==============
                $R.$remote.get_recommendation = function (_id, _url, _body, _onSuccess, _onFailure)
                {
                    //  preliminary check
                    //  =================
                        switch (true)
                        {
                            case (!($R.$remote.rpc__noteStore)):
                            case (!($R.$remote.rpc__noteStore.NoteStore)):
                            case (!($R.$remote.is__connected)):
                            case (!($R.$remote.is__loggedIn)):
                            case (!($R.$remote.is__notExpired())):
                                _onFailure('login');
                                return;
                        }
            
                    //  get scuccess
                    //  ============
                        var _doSuccess = function () { _onSuccess(); };
                    
                    
                    //  default to false
                    //  ================
                        var _defaultResultToFalse = function (_thisResult)
                        {
                            var _theResult = _thisResult;
                            
                            if (_theResult) {}else                  { _theResult = {}; }
                            if (_theResult.notebook) {}else         { _theResult.notebook = false; }
                            if (_theResult.tags) {}else             { _theResult.tags = false; }
                            if (_theResult.relatedNotes) {}else     { _theResult.relatedNotes = false; }
                            
                            return _theResult;
                        };
                    
                    //  add absolute URLs
                    //  =================
                        var _addAbsoluteURLs = function (_addToThisResult, _use_business)
                        {
                            var _theResult = _addToThisResult;
                            
                            //  check
                            if (true && _theResult.relatedNotes && _theResult.relatedNotes.list && _theResult.relatedNotes.list.length > 0) {}else { return _theResult; }
                            
                            //  loop
                            //  ====
                                for (var i=0, _i=_theResult.relatedNotes.list.length; i<_i; i++)
                                {
                                    var _n = _theResult.relatedNotes.list[i];
                                    _theResult.relatedNotes.list[i]['absoluteURL__thumbnail'] = $R.$remote.get_note_thumbnail(_use_business, _n.guid);
                                    _theResult.relatedNotes.list[i]['absoluteURL__noteView'] = $R.$remote.get_note_link(_use_business, _n.guid, _n.notebookGuid);
                                    
                                    // no thumbnail
                                    if (_theResult.relatedNotes.list[i]['largestResourceSize'] > 0) {}else { _theResult.relatedNotes.list[i]['absoluteURL__thumbnail'] = 'none'; }
                                }
                            
                            //  return
                            return _theResult;
                        };
                        
                    //  _body
                    //  =====
                        //  just text
                        _body = _body.replace(/<[^>]+?>/gi, ' ');
                        
                        //  remove spaces
                        _body = _body.replace(/\s+/gi, ' ');
                        _body = _body.replace(/^\s+/gi, '');
                        
                        //  cut off
                        _body = _body.substr(0, 5000);
                        
                    //  recommendation request
                    //  ======================
                        var _recommendationRequest = {
                            'url': _url,
                            'text': _body,
                            'relatedNotesResultSpec': {
                                'includeTitle': true,
                                'includeSnippet': true,
                                
                                'includeCreated': true,
                                
                                'includeLargestResourceMime': true,
                                'includeLargestResourceSize': true,
                                
                                'includeNotebookGuid': true,
            
                                'includeAttributes': false,
                                'includeTagNames': false
                            }
                        };
                        //  console.log('NoteStoreExtra.getFilingRecommendations Called with:');
                        //  console.log(_recommendationRequest);
                        
                        
                    //  try and get -- a FilingReccomendation object
                    //  ===========
                        $R.$remote.rpc__noteStore.NoteStoreExtra.getFilingRecommendations(
                            function (_rpc_result, _rpc_exception)
                            {
                                var _getResult = _rpc_result, _getError = _rpc_exception;
                            
                                //  error
                                //  =====
                                
                                    if (_getError)
                                    {
                                        //  Firebug.Console.log(_getError);
                                        //  console.log(_getError);
                                        
                                        //  unknown error
                                        //  =============
                                            switch (true)
                                            {
                                                case (!(_getError.trace)):
                                                case (!(_getError.trace.indexOf)):
                                                case (!(_getError.trace.indexOf(')') > -1)):
                                                    _onFailure('get_recommendation / exception / no trace');
                                                    return;
                                            }
                                        
                                        //  figure out error
                                        //  ================
                                            var _trace = _getError.trace.substr(0, _getError.trace.indexOf(')')+1);
                                            switch (_trace)
                                            {
                                                case 'EDAMUserException(errorCode:BAD_DATA_FORMAT, parameter:authenticationToken)':
                                                case 'EDAMSystemException(errorCode:INVALID_AUTH, message:authenticationToken)':
                                                case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                    _onFailure('login');
                                                    return;
                                            }
            
                                        //  could not figure out error
                                        //  ==========================
                                            _onFailure('get_recommendation / exception / unknown');
                                            return;
                                    }
                                    
                                //  result
                                //  ======
                                
                                    //  fill in to false
                                    //  ================
                                        _getResult = _defaultResultToFalse(_getResult);
                                    
                                    //  add absoluteURLs
                                    //  ================
                                        _getResult = _addAbsoluteURLs(_getResult, false);
                                        
                                    //  store result
                                    //  ============
                                        $R.$remote.store__id_to_recommendation[_id] = _getResult;
                                        
                                    //  not business; end
                                    //  =================
                                        if (true && $R.$remote.is__business && $R.$remote.business__noteStore && $R.$remote.business__noteStore.NoteStore) {}else { _doSuccess(); return; }
                                        
                                    //  is business; get second reccomendation
                                    //  ======================================
                                        $R.$remote.store__id_to_recommendation[_id]['businessRecommendation'] = false;
                                        
                                        $R.$remote.business__noteStore.NoteStoreExtra.getFilingRecommendations(
                                            function (_rpc_result, _rpc_exception)
                                            {
                                                var _getResultBusiness = _rpc_result, _getErrorBusiness = _rpc_exception;
                                                
                                                //  error
                                                //  =====
                                                    if (_getErrorBusiness) { _doSuccess(); return; }
                                                    
                                                //  result
                                                //  ======
                                                    
                                                    //  fill in to false
                                                    //  ================
                                                        _getResultBusiness = _defaultResultToFalse(_getResultBusiness);
                                                    
                                                    //  add absoluteURLs
                                                    //  ================
                                                        _getResultBusiness = _addAbsoluteURLs(_getResultBusiness, true);
                                                        
                                                    //  store result
                                                    //  ============
                                                        $R.$remote.store__id_to_recommendation[_id].businessRecommendation = _getResultBusiness;
            
                                                //  success
                                                //  =======
                                                    //  console.log($R.$remote.store__id_to_recommendation[_id]);
                                                    _doSuccess();
                                            },
                                            $R.$remote.business__authToken,
                                            _recommendationRequest);
                            },
                            $R.$remote.user__authToken,
                            _recommendationRequest);
                };
            
            
            //  get notebooks
            //  =============
                $R.$remote.get_notebooks = function (_onSuccess, _onFailure)
                {
                    //  preliminary check
                    //  =================
                        switch (true)
                        {
                            case (!($R.$remote.rpc__noteStore)):
                            case (!($R.$remote.rpc__noteStore.NoteStore)):
                            case (!($R.$remote.is__connected)):
                            case (!($R.$remote.is__loggedIn)):
                            case (!($R.$remote.is__notExpired())):
                                _onFailure('login');
                                return;
                        }
            
                    //  try and get -- a list of notebooks
                    //  ===========
                        $R.$remote.rpc__noteStore.NoteStore.listNotebooks(
                            function (_rpc_result, _rpc_exception)
                            {
                                var _getResult = _rpc_result, _getError = _rpc_exception;
                            
                                //  error
                                //  =====
                                
                                    if (_getError)
                                    {
                                        //  Firebug.Console.log(_getError);
                                        //  console.log(_getError);
                                        
                                        //  unknown error
                                        //  =============
                                            switch (true)
                                            {
                                                case (!(_getError.trace)):
                                                case (!(_getError.trace.indexOf)):
                                                case (!(_getError.trace.indexOf(')') > -1)):
                                                    _onFailure('get_notebooks / exception / no trace');
                                                    return;
                                            }
                                        
                                        //  figure out error
                                        //  ================
                                            var _trace = _getError.trace.substr(0, _getError.trace.indexOf(')')+1);
                                            switch (_trace)
                                            {
                                                case 'EDAMUserException(errorCode:BAD_DATA_FORMAT, parameter:authenticationToken)':
                                                case 'EDAMSystemException(errorCode:INVALID_AUTH, message:authenticationToken)':
                                                case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                    _onFailure('login');
                                                    return;
                                            }
            
                                        //  could not figure out error
                                        //  ==========================
                                            _onFailure('get_notebooks / exception / unknown');
                                            return;
                                    }
                                    
                                //  result
                                //  ======
                                
                                    //  check
                                    //  =====
                                    
                                        switch (true)
                                        {
                                            case (!(_getResult.list)):
                                            case (!(_getResult.list.length)):
                                                _onFailure('get_notebooks / invalid result');
                                                return;
                                        }
                                    
                                    //  success
                                    //  =======
                                    
                                        //  sort
                                        //  ====
                                            _getResult.list.sort(function (a, b)
                                            {
                                                switch (true)
                                                {
                                                    case (a.name < b.name): return -1;
                                                    case (a.name > b.name): return 1;
                                                    default: return 0;
                                                }
                                            });
                                        
                                        //  return
                                        //  ======
                                            _onSuccess(_getResult.list);
                            },
                            $R.$remote.user__authToken);
                };
            
            
            //  get business notebooks
            //  ======================
                $R.$remote.get_business_notebooks = function (_onSuccess, _onFailure)
                {
                    //  preliminary check
                    //  =================
                        switch (true)
                        {
                            case (!($R.$remote.business__noteStore)):
                            case (!($R.$remote.business__noteStore.NoteStore)):
                            case (!($R.$remote.is__business)):
                            case (!($R.$remote.is__connected)):
                            case (!($R.$remote.is__loggedIn)):
                            case (!($R.$remote.is__notExpired())):
                                _onFailure('login');
                                return;
                        }
            
                    //  try and get -- a list of notebooks
                    //  ===========
                        $R.$remote.business__noteStore.NoteStore.listNotebooks(
                            function (_rpc_result, _rpc_exception)
                            {
                                var _getResult = _rpc_result, _getError = _rpc_exception;
                            
                                //  error
                                //  =====
                                
                                    if (_getError)
                                    {
                                        //  Firebug.Console.log(_getError);
                                        //  console.log(_getError);
                                        
                                        //  unknown error
                                        //  =============
                                            switch (true)
                                            {
                                                case (!(_getError.trace)):
                                                case (!(_getError.trace.indexOf)):
                                                case (!(_getError.trace.indexOf(')') > -1)):
                                                    _onFailure('get_business_notebooks / exception / no trace');
                                                    return;
                                            }
                                        
                                        //  figure out error
                                        //  ================
                                            var _trace = _getError.trace.substr(0, _getError.trace.indexOf(')')+1);
                                            switch (_trace)
                                            {
                                                case 'EDAMUserException(errorCode:BAD_DATA_FORMAT, parameter:authenticationToken)':
                                                case 'EDAMSystemException(errorCode:INVALID_AUTH, message:authenticationToken)':
                                                case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                    _onFailure('login');
                                                    return;
                                            }
            
                                        //  could not figure out error
                                        //  ==========================
                                            _onFailure('get_business_notebooks / exception / unknown');
                                            return;
                                    }
                                    
                                //  result
                                //  ======
                                
                                    //  check
                                    //  =====
                                    
                                        switch (true)
                                        {
                                            case (!(_getResult.list)):
                                            case (!(_getResult.list.length)):
                                                _onFailure('get_business_notebooks / invalid result');
                                                return;
                                        }
                                    
                                    //  success
                                    //  =======
                                    
                                        //  sort
                                        //  ====
                                            _getResult.list.sort(function (a, b)
                                            {
                                                switch (true)
                                                {
                                                    case (a.name < b.name): return -1;
                                                    case (a.name > b.name): return 1;
                                                    default: return 0;
                                                }
                                            });
                                        
                                        //  return
                                        //  ======
                                            _onSuccess(_getResult.list);
                            },
                            $R.$remote.business__authToken);
                };
            
                
            //  get linked notebooks
            //  ====================
                $R.$remote.get_linked_notebooks = function (_onSuccess, _onFailure)
                {
                    //  preliminary check
                    //  =================
                        switch (true)
                        {
                            case (!($R.$remote.rpc__noteStore)):
                            case (!($R.$remote.rpc__noteStore.NoteStore)):
                            case (!($R.$remote.is__connected)):
                            case (!($R.$remote.is__loggedIn)):
                            case (!($R.$remote.is__notExpired())):
                                _onFailure('login');
                                return;
                        }
            
                    //  try and get -- a list of notebooks
                    //  ===========
                        $R.$remote.rpc__noteStore.NoteStore.listLinkedNotebooks(
                            function (_rpc_result, _rpc_exception)
                            {
                                var _getResult = _rpc_result, _getError = _rpc_exception;
                            
                                //  error
                                //  =====
                                
                                    if (_getError)
                                    {
                                        //  Firebug.Console.log(_getError);
                                        //  console.log(_getError);
                                        
                                        //  unknown error
                                        //  =============
                                            switch (true)
                                            {
                                                case (!(_getError.trace)):
                                                case (!(_getError.trace.indexOf)):
                                                case (!(_getError.trace.indexOf(')') > -1)):
                                                    _onFailure('get_notebooks / exception / no trace');
                                                    return;
                                            }
                                        
                                        //  figure out error
                                        //  ================
                                            var _trace = _getError.trace.substr(0, _getError.trace.indexOf(')')+1);
                                            switch (_trace)
                                            {
                                                case 'EDAMUserException(errorCode:BAD_DATA_FORMAT, parameter:authenticationToken)':
                                                case 'EDAMSystemException(errorCode:INVALID_AUTH, message:authenticationToken)':
                                                case 'EDAMUserException(errorCode:AUTH_EXPIRED, parameter:authenticationToken)':
                                                    _onFailure('login');
                                                    return;
                                            }
            
                                        //  could not figure out error
                                        //  ==========================
                                            _onFailure('get_linked_notebooks / exception / unknown');
                                            return;
                                    }
                                    
                                //  result
                                //  ======
                                
                                    //  check
                                    //  =====
                                        
                                        switch (true)
                                        {
                                            case (!(_getResult.list)):
                                            case (!(_getResult.list.length)):
                                                _onFailure('get_linked_notebooks / invalid result');
                                                return;
                                        }
                                    
                                    //  success
                                    //  =======
                                    
                                        //  sort
                                        //  ====
                                            _getResult.list.sort(function (a, b)
                                            {
                                                switch (true)
                                                {
                                                    case (a.name < b.name): return -1;
                                                    case (a.name > b.name): return 1;
                                                    default: return 0;
                                                }
                                            });
                                        
                                        //  return
                                        //  ======
                                            _onSuccess(_getResult.list);
                            },
                            $R.$remote.user__authToken);
                };
                
            
                //  get note link
                //      takes into account the setting "open_notes_in"
                //      if for business, uses business shard id, if not uses user shard id
                //      ads the authToken automatically
                
                $R.$remote.get_note_link = function (_for_business, _note_guid, _notebook_guid)
                {
                    var _authToken = (_for_business ? $R.$remote.business__authToken : $R.$remote.user__authToken),
                        _shardId = (_for_business ? $R.$remote.business__shardId : $R.$remote.user__shardId);
                    
                    switch (true)
                    {
                        case ($R.$remote.setting__open_notes_in == 'web'):
                        //  ==============================================
                        
                            switch (true)
                            {
                                case (!!_for_business):
                                    return $R.$remote.get_setAuthAndRedirect_link(''            +
                                        $R.$bootstrap.remote_domain                             +
                                        'shard/' +  _shardId + '/'                              +
                                        'business/dispatch/'                                    +
                                        'view/' + _note_guid                                    +
                                        '#st=b' + '&n=' + _note_guid + '&b=' + _notebook_guid   +
                                    '');
                                    break;
                                    
                                case (!_for_business):
                                    return $R.$remote.get_setAuthAndRedirect_link(''    +
                                        $R.$bootstrap.remote_domain                     +
                                        'shard/' +  _shardId + '/'                      +
                                        'view/' + _note_guid                            +
                                        '#st=p' + '&n=' + _note_guid                    +
                                    '');
                                    break;
                            }
                        
                            break;
                            
                        case ($R.$remote.setting__open_notes_in == 'desktop'):
                        //  ==================================================
            
                            switch (true)
                            {
                                case (!!_for_business):
                                    return ''                       +
                                        'evernote:///view/'         +
                                        $R.$remote.user__id + '/'   +
                                        _shardId + '/'              +
                                        _note_guid + '/'            +
                                        _note_guid + '/'            +
                                        _notebook_guid + '/'        +
                                        '?currentUSN=0'             +
                                    '';
                                    break;
                                    
                                case (!_for_business):
                                    return ''                       +
                                        'evernote:///view/'         +
                                        $R.$remote.user__id + '/'   +
                                        _shardId + '/'              +
                                        _note_guid + '/'            +
                                        _note_guid + '/'            +
                                        '?currentUSN=0'             +
                                    '';
                                    break;
                            }
                        
                            break;
                    }
                    
                    return '';
                };
                
                
                //  get SetAuthAndRedirect link
                //      if desktop client selected, will return the URL it was given
                //      to login on the web/client, before going to where we wnt to go
                
                $R.$remote.get_setAuthAndRedirect_link = function (_link)
                {
                    switch (true)
                    {
                        case ($R.$remote.setting__open_notes_in == 'web'):
                            return ''                                       +
                                $R.$bootstrap.remote_domain                 +
                                'SetAuthToken.action?auth=' + encodeURIComponent($R.$remote.user__authToken) +
                                '&targetUrl=' + encodeURIComponent(_link)   +
                            '';
                            break;
                            
                        case ($R.$remote.setting__open_notes_in == 'desktop'):
                            return _link;
                            break;
                    }
                    
                    return '';
                };
                
                
                //  get note thumbnail image
                //      will always get from the web
                //      will use the business auth token to get a business thumnbail
                
                $R.$remote.get_note_thumbnail = function (_for_business, _note_guid)
                {
                    var _authToken = (_for_business ? $R.$remote.business__authToken : $R.$remote.user__authToken),
                        _shardId = (_for_business ? $R.$remote.business__shardId : $R.$remote.user__shardId);
            
                    return ''                                       +
                        $R.$bootstrap.remote_domain                 +
                        'shard/' +  _shardId + '/'                  +
                        'thm/note/'                                 +
                        _note_guid                                  +
                        '?auth=' + encodeURIComponent(_authToken)   +
                        '&size=75'                                  +
                    '';
                };
                
        

        
        //  variable which holds what popup is currently open
        
            $R.$popup = {
                'which':    'string',           //  what popup is open -- currently 'login' is the only valid one
                'tab':      'integer||object',  //  what tab is the popup associated with -- tabId in Chrome, document object in Firefox
                'details':  'object'            //  popup specific details -- login has its own thing
            };
        
            //  none is the other valid variable
            $R.$popup = false;
        

        
        //  isolate
        //  =======
            (function ()
            {
                //  uage metrics
                //  ============
                    /* imported from the web-clipper */
                    /* init like this: if (!usageMetricsManager && auth) { usageMetricsManager = new UsageMetricsManager(url, isAuthenticated); } */
                    
                    // Takes a URL to make requests against, and a function that can be called to get back auth info. Currently, the spec
                    // for what should be passed to authFunction and what gets passed to authFunction's callback is exactly equivalent to
                    // Auth.isAuthenticated(), which is:
                    // Auth.isAuthenticated(callback, autoRenew)
                    //  callback: a function to call when we've decided whether a user is authenticated, this function will be passed an
                    //  object with the following properties:
                    //    username: the username used to perform the authentication (which can be an email address).
                    //    authenticationToken: the authentication token returned by a successful login on the server.
                    //    displayName: the username as it should be displayed in the UI (should not be an email address, may be the same as
                    //    username.  
                    //  NOTE: if authentication fails, NULL is passed to 'callback', not an object with null property values.
                    //
                    //  autoRenew: a boolean indicating whether the authFunction should attempt to automatically renew a stale auth token.
                    
                    function UsageMetricsManager(authFunction) {
                    
                      var usageMetrics = {};
                    
                      function recordActivity(_callback) {
                        var name = "";
                        function checkAuthCallback(auth)
                        {
                          // signed in/out
                          if (auth) {
                            name = auth.displayName;
                          }
                          else {
                            name = '__signed_out';
                          }
                          
                          // signed out
                          if (name == '__signed_out') {
                            var usage = usageMetrics[name];
                            if (!usage) {
                              usage = new UsageMetricsSignedOut();
                              usageMetrics[name] = usage;
                            }
                            usage.recordActivity(_callback);
                            return; // signed out, and done
                          }
                          
                          // signed in
                          if (name) {
                            var usage = usageMetrics[name];
                            if (!usage) {
                              usage = new UsageMetricsSignedIn(authFunction);
                              usageMetrics[name] = usage;
                            }
                            usage.recordActivity(_callback);
                          }
                        }
                        
                        authFunction(checkAuthCallback, true);
                      }
                    
                      this.recordActivity = recordActivity;
                    }
                    
                    /* imported from the web-clipper */
                    
                    // Each logged in user should get his own UsageMetrics object.
                    function UsageMetricsSignedIn(authFunction) {
                    
                      var INTERVAL_MINUTES = 15;
                    
                      // Timestamp of the 15 minute interval last sent to the server. We will not record events in this block or before.
                      var lastSent = 0;
                      var activityBlocks = {};
                    
                      // Gets the timestamp for the first second of the 15 minute block that we're currently in.
                      function getTimeBlock() {
                        var now = new Date();
                        var minutes = Math.floor(now.getMinutes() / INTERVAL_MINUTES) * INTERVAL_MINUTES;
                        now.setMinutes(minutes);
                        now.setSeconds(0);
                        now.setMilliseconds(0);
                        return Math.round(now.getTime() / 1000);
                      }
                    
                      function recordActivity(callback) {
                        var time = getTimeBlock();
                        if (lastSent >= time) {
                          if (callback) { callback(); }
                          return;
                        }
                        activityBlocks[time] = true;
                        send(callback);
                      }
                    
                      function send(callback) {
                        if (!navigator.onLine) {
                          if (callback) { callback(); }
                          return;
                        }
                        var count = 0;
                        var newLastSent = 0;
                        for (var i in activityBlocks) {
                          var num = parseInt(i, 2);
                          count++;
                          if (num > newLastSent) {
                            newLastSent = num;
                          }
                        }
                    
                        if (count > 0) {
                          sendRequest(count, newLastSent, callback);
                        }
                        else {
                          if (callback) { callback(); }
                        }
                      }
                    
                      function sendRequest(count, newLastSent, callback) {
                        function resultCallback(data, error) {
                          if (data) {
                            activityBlocks = [];
                            if (newLastSent > lastSent) {
                              lastSent = newLastSent;
                            }
                          }
                          if (callback) { callback(); }
                        }
                    
                        function sendCallback() {
                          $R.$remote.rpc__noteStore.NoteStore.getSyncStateWithMetrics(
                            resultCallback, 
                            $R.$remote.user__authToken, 
                            { 'sessions': count });
                        }
                    
                        function authCallback(_authInfo) {
                          if (_authInfo && _authInfo.authenticationToken){
                            sendCallback();
                          }
                          else {
                            //console.warn("Tried to send UsageMetrics, but not logged in.");
                            if (callback) { callback(); }
                          }
                        }
                    
                        authFunction(authCallback, true);
                      }
                      
                      function getJson() {
                        var json = {};
                        json.lastSent = lastSent;
                        json.activityBlocks = {};
                        // Deep copy.
                        for (var i in activityBlocks) {
                          json.activityBlocks[i] = activityBlocks[i];
                        }
                        return json;
                      }
                    
                      function importFromJson(json) {
                        try {
                          lastSent = json.lastSent;
                          activityBlocks = json.activityBlocks;
                        }
                        catch(e) {
                          lastSent = 0;
                          activityBlocks = {};
                          //console.warn("Failed to import saved UsageMetrics from JSON object.");
                        }
                      }
                    
                      this.recordActivity = recordActivity;
                      this.send = send;
                      this.getJson = getJson;
                      this.importFromJson = importFromJson;
                    }
                    
                    /* derived from UsageMetricsSignedIn */
                    
                    function UsageMetricsSignedOut() {
                      "use strict";
                    
                      var INTERVAL_MINUTES = 15;
                    
                      // Timestamp of the 15 minute interval last sent to the server. We will not record events in this block or before.
                      var lastSent = 0;
                      var activityBlocks = {};
                    
                      // Gets the timestamp for the first second of the 15 minute block that we're currently in.
                      function getTimeBlock() {
                        var now = new Date();
                        var minutes = Math.floor(now.getMinutes() / INTERVAL_MINUTES) * INTERVAL_MINUTES;
                        now.setMinutes(minutes);
                        now.setSeconds(0);
                        now.setMilliseconds(0);
                        return Math.round(now.getTime() / 1000);
                      }
                    
                      function recordActivity(callback) {
                        var time = getTimeBlock();
                        if (lastSent >= time) {
                          if (callback) { callback(); }
                          return;
                        }
                        activityBlocks[time] = true;
                        send(callback);
                      }
                    
                      function send(callback) {
                        if (!navigator.onLine) {
                          if (callback) { callback(); }
                          return;
                        }
                        var count = 0;
                        var newLastSent = 0;
                        for (var i in activityBlocks) {
                          var num = parseInt(i, 2);
                          count++;
                          if (num > newLastSent) {
                            newLastSent = num;
                          }
                        }
                    
                        if (count > 0) {
                          sendRequest(count, newLastSent, callback);
                        }
                        else {
                          if (callback) { callback(); }
                        }
                      }
                    
                      function sendRequest(count, newLastSent, callback) {
                        function resultCallback(data) {
                          if (data) {
                            activityBlocks = [];
                            if (newLastSent > lastSent) {
                              lastSent = newLastSent;
                            }
                          }
                          if (callback) { callback(); }
                        }
                    
                        function sendCallback()
                        {
                            //  get device id; set, if not present
                            var _device_id = $R.saved__get_device_id();
                        
                            //  create request
                            var _request = ''                           +
                                'a='  + encodeURIComponent('en-clearly-xauth-new') +
                                '&d=' + encodeURIComponent(_device_id)  +
                                '&t=' + 'sessions'                      +
                                '&c=' + encodeURIComponent(count)       +
                                '&w=' + encodeURIComponent(Math.floor((new Date()).getTime()/1000)) +
                            '';
                                
                            //  signature
                            var _signature = $R.md5(_request + '38f4e71b0172afbb');
                            
                            //  sign request
                            _request = _request + '&g=' + encodeURIComponent(_signature);
                                
                            //  send request
                            $R.xhr('get', 'https://metrics.evernote.com/r?' + _request, function() { if (this.readyState == 4 && this.status == 200 && callback) { callback(); } });
                        }
                    
                        sendCallback();
                      }
                    
                      this.recordActivity = recordActivity;
                      this.send = send;
                    }
                    
        
                //  the metrics manager
                //  ===================
                    $R.session_tracking__usageMetricsManager = false;
                
                //  the high-level track function
                //  =============================
                    $R.session_tracking__track = function ()
                    {
                        //  not instantiated yet
                        //  ====================
                            if ($R.session_tracking__usageMetricsManager) {}else
                            {
                                $R.session_tracking__init(function () { $R.session_tracking__track(); });
                                return;
                            }
                    
                        //  do now
                        //  ======
                            $R.session_tracking__usageMetricsManager.recordActivity(function () { /* console.log('ran recordActivity'); */ });
                    };
                
                //  init metrics manager
                //  ====================
                    $R.session_tracking__init = function (_onSuccess)
                    {
                        $R.session_tracking__usageMetricsManager = new UsageMetricsManager($R.session_tracking__authFunction);
                        _onSuccess();
                    };
            
            
                //  auth function
                //  =============
                    $R.session_tracking__authFunction = function (_callback, _autoRenew)
                    {
                        //  doCallback
                        //  ==========
                            var _doCallback = function (_success)
                            {
                                //  failed
                                if (!_success) { _callback(false); return; }
                    
                                //  success
                                _callback({ 
                                    'authenticationToken':  $R.$remote.user__authToken,
                                    'displayName':          $R.$remote.user__id,
                                    'username':             $R.$remote.user__id
                                }); 
                            };
                    
                        //  not logged in
                        //  =============
                            switch (true)
                            {
                                case (!($R.$remote.is__connected)):
                                case (!($R.$remote.is__loggedIn)):
                                case (!($R.$remote.is__notExpired())):
                            
                                    //  don't auto renew -- just fail
                                    if (_autoRenew) {}else { _doCallback(false); return; }
        
                                    //  get login
                                    var _storedLogin = $R.credentials__get();
                            
                                    //  do stored login
                                    $R.$remote.loginWithAuthToken(
                                        _storedLogin.xAuthToken,
        
                                        //    success | login
                                        function () { _doCallback(true); return; },
        
                                        //    failure | login
                                        function (_failReason) { _doCallback(false); return; });
                            
                                    return;
                                    break;
                            }
                                
                        //  logged in -- do callback
                        //  =========
                            _doCallback(true);
                    };
            })();
            
        
        //  google analytics -- docs: https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide
        //  ================
        
            $R.analytics__track_event = function (_category, _action, _label)
            {
                //  data to be sent
                var _data =     { 'type': 'event' };
                if (_category)  { _data['category'] = _category; }
                if (_action)    { _data['action'] = _action; }
                if (_label)     { _data['label'] = _label; }
        
                //  category and action are required        
                if (_category && _action) {}else { return false; }
        
                //  send
                $R.analytics__send(_data);
                
                //  good
                return true;
            };
        
            $R.analytics__send = function (_data)
            {
                //  add metadata
                //  ============
                
                    _data['property_id'] =  'UA-285778-79'; /* live; previous: 'UA-28770131-1'; test: 'UA-28238478-1'; */
                    _data['client_id'] =    $R.saved__get_device_id();
                
                    _data['app_name'] =     'Clearly';
                    _data['app_version'] =  '10.4.1.5';
        
                    _data['api_version'] =  '1';
        
        
                //  post
                //  ====
                
                    //  actual GA parameter names -- they're very very short
                    var _parameter_names = {
                        'api_version':  'v',
                        'property_id':  'tid',
                        'client_id':    'cid',
                
                        'app_name':     'an',
                        'app_version':  'av',
                
                        'type':         't',
                
                        'category':     'ec',
                        'action':       'ea',
                        'label':        'el'
                    };
        
                    //  data to send
                    var _data2 = {};
                    for (var _key in _data) { _data2[_parameter_names[_key]] = _data[_key]; }
        
                    //  send -- also does the encoding of _data2
                    $R.xhr('POST', 'https://ssl.google-analytics.com/collect', false, _data2);
            };
        

        
        //  first show
        //  ==========
            $R.first__show = function()
            {
                //  already done -- somehow
                //  ============
                    if ($R.firstShow) { return; }
        
                //  check if not first run
                //  ======================
                    if ($R.storage__get('notFirstRun') != 'yes') 
                    {
                        $R.firstShow = 'all-features';
                        return;
                    }
                    else
                    {
                        if ($R.storage__get('firstShowIdentifier') == $R.first_show_identifier) {}else
                        {
                            $R.firstShow = 'new-features';
                            return;
                        }
                    }
            };
        
        
        //  first run
        //  =========
            $R.first__run = function()
            {
                //  check -- maybe return
                //  =====
                    if ($R.storage__get('notFirstRun') == 'yes') { return; }
        
                //  set
                //  ===
                    $R.storage__set('notFirstRun', 'yes');
                
                //  add button -- just for firefox
                //  ==========
        
                
                //  open info url
                //  =============
                    var defaultInfoURL = 'http://www.evernote.com/clearly/guide/';
                    $R.$bootstrap.bootstrap(
                        function ()
                        {
                            var url = '';
                                url = (url > '' ? url : $R.$bootstrap.remote_domain_marketing);
                                url = (url > '' ? url + 'clearly/guide/' : defaultInfoURL);
        
                            $R.open_url_in_new_tab(url);
                        },
                        function ()
                        {
                            $R.open_url_in_new_tab(defaultInfoURL);
                        });
            };
        
        
        //  defaults -- if options/vars not set
        //  ========
            $R.assure_defaults = function ()
            {
                for (var _x in $R.default_options)
                {
                    var _valueDefault = $R.default_options[_x],
                        _valueNow = $R.storage__get(_x);
        
                    switch (true)
                    {
                        case (!(_valueNow > '')):
                        case ((_valueNow == '--def--')):
                            $R.storage__set(_x, $R.encode(_valueDefault));
                            break;
                    }
                }
                    
                for (var _x in $R.default_vars)
                {
                    var _valueDefault = $R.default_vars[_x],
                        _valueNow = $R.storage__get(_x);
        
                    switch (true)
                    {
                        case (!(_valueNow > '')):
                        case ((_valueNow == '--def--')):
                            $R.storage__set(_x, $R.encode(_valueDefault));
                            break;
                    }
                }
            };
        
        
    })(window.__readable_by_evernote);


//  ==========================================================================================================================


//  import this
//  ===========
    (function ($R) {
    
        
        //  launch
        //  ======
            $R.launch = function ()
            {
                chrome.tabs.query({ 'windowId': chrome.windows.WINDOW_ID_CURRENT, 'active': true }, function (_selected_tabs)
                {
                    //  .query details
                    //      optional parameter ('currentWindow': true)
                    //          this parameter was available starting with Chrome 19
                    //      the WINDOW_ID_CURRENT, on the other hand, has been available since Chrome 18
                
                    //  first tab only
                    var _selected_tab = _selected_tabs[0];
                    
                    //  invalid page?
                    if (_selected_tab && _selected_tab.url && $R.valid_url(_selected_tab.url)) {}else
                    {
                        //  incognito; wil not work
                        if (_selected_tab.incognito) { return; }
                    
                        //  not incognito
                        chrome.tabs.update(_selected_tab.id, {'url': 'chrome-extension://iooicodkiihhpojmmeghjclgihfjdjhj/blank/page.html'});
                        return;
                    }
                    
                    //  send message
                    chrome.tabs.sendMessage(_selected_tab.id, { '_type': 'inject' });
                });
            };
        
        
        //  close reminder
        //  ==============
            $R.closeReminder = function ()
            {
                chrome.tabs.query({ 'windowId': chrome.windows.WINDOW_ID_CURRENT, 'active': true }, function (_selected_tabs)
                {
                    //  first tab only
                    var _selected_tab = _selected_tabs[0];
                    
                    //  invalid page?
                    if (_selected_tab && _selected_tab.url && $R.valid_url(_selected_tab.url)) {}else { return; }
                    
                    //  send message
                    chrome.tabs.sendMessage(_selected_tab.id, { '_type': 'close-reminder' });
                });
            };
        

    })(window.__readable_by_evernote);


//  ==========================================================================================================================


//  run
//  ===
    (function ($R) {

        
        //  button
        //  ======
            chrome.browserAction.onClicked.addListener(function(tab) { $R.launch(); });
            
        //  context menu
        //  ============
            chrome.contextMenus.create({
                'title':     chrome.i18n.getMessage('chrome_context_menu'),
                'type':      'normal',
                'contexts':  ['all'],
                'onclick':   function () { $R.launch(); }
            });
            
        
        //  events handler
        //  ==============
            chrome.extension.onMessage.addListener(function(message, sender, sendResponse)
            {
                //  invalid
                if (message._type) {}else { sendResponse({}); }
        
                //  vars
                var _event_name = message._type;
                
                //  other
                if (_event_name.indexOf('to-chrome--') === 0) {}else { return; }
                
                //  vars
                var _short_event_name = _event_name.substr('to-chrome--'.length),
                    _stop = false;
        
                //  console.log(_event_name);
        
                //  dispatcher
                var __event_dispatch = function (_short_event_name, _arguments)
                {
                    //  default details -- for some events, this gets modified
                    var _details = { '_type': _short_event_name };
        
                    //  add more details?
                    switch (_short_event_name)
                    {
                        case 'evernote--get-recommendation--successful': 
                            _details = { 
                                '_type': _short_event_name, 
                                '_recommendation': $R.$remote.store__id_to_recommendation[_arguments['_page_id']] 
                            };
                            break;
                            
                        case 'evernote--clip--successful':
                            _details = {
                                '_type': _short_event_name,
                                '_info': $R.$remote.store__id_to_info[_arguments['_page_id']] 
                            };
                            break;
                            
                        case 'evernote--clip-highlights--successful':
                            _details = {
                                '_type': _short_event_name,
                                '_info': $R.$remote.store__id_to_info[_arguments['_page_id']] 
                            };
                            break;
                    }
        
                    //  type
                    _details._type = 'to-content--' + _details._type;
                    
                    //  send -- to sender tab, or to the tab associated with the tab
                    switch (_short_event_name)
                    {
                        case 'evernote--login--successful':
                        case 'evernote--login--now-open':
                            //  if a valid (login) popup object currently exists
                            if ($R.$popup && $R.$popup._which && $R.$popup._which == 'login') {
                                chrome.tabs.sendMessage($R.$popup._tab, _details);
                            }
                            else {
                                chrome.tabs.sendMessage(sender.tab.id, _details);
                            }
                            break;
                        
                        default:
                            chrome.tabs.sendMessage(sender.tab.id, _details);
                            break;
                    }
                    
                    //  custom action, after
                    switch (_short_event_name)
                    {
                        case 'evernote--login--show':
                        case 'evernote--login--show--in':
                        case 'evernote--login--show--in-cn':
                        case 'evernote--login--show--cn':
                        case 'evernote--login--show--cn-in':
                        
                            //  localization
                            var _localization = 'in';            
                            switch (_short_event_name)
                            {
                                case 'evernote--login--show--in':    _localization = _short_event_name.substr(-2); break;
                                case 'evernote--login--show--cn':    _localization = _short_event_name.substr(-2); break;
                                case 'evernote--login--show--in-cn': _localization = _short_event_name.substr(-5).replace(/-/g, '_').toLowerCase(); break;
                                case 'evernote--login--show--cn-in': _localization = _short_event_name.substr(-5).replace(/-/g, '_').toLowerCase(); break;
                            }
                        
                            //  set popup
                            $R.$popup = {
                                '_which':    'login',
                                '_tab':      sender.tab.id,
                                '_details':  { 
                                    '_localization': _localization,
                                    '_screen':       'credentials'
                                }
                            };
                            
                            //  set Chrome popup
                            chrome.browserAction.setPopup({ 
                                'tabId': $R.$popup._tab, 
                                'popup': 'in_popup/login/page.html' 
                            });
                            
                            break;
        
                        case 'evernote--login--successful':
                        
                            //  close popup
                            try { chrome.extension.getViews({ 'type': 'popup' })[0].close(); } catch (_e) {}
                        
                            //  unset Chrome popup
                            chrome.browserAction.setPopup({ 
                                'tabId': $R.$popup._tab, 
                                'popup': '' 
                            });
        
                            //  unset popup
                            $R.$popup = false;
                            
                            break;
                    }
                };
            
                //  dispatcher :: popup
                var __event_dispatch__popup = function (_short_event_name, _arguments)
                {
                    //  default details -- for some events, this gets modified
                    var _details = { '_type': _short_event_name };
        
                    //  add more details?
                    switch (_short_event_name)
                    {
                        case 'evernote--login--request-second-factor':
                            _details = { 
                                '_type': _short_event_name, 
                                '_deliveryHint': _arguments['_deliveryHint']
                            };
                            break;
                    }
        
                    //  type
                    _details._type = 'to-content--' + _details._type;
                    
                    //  send -- to popup
                    chrome.extension.sendMessage(_details);
                    
                    //  custom action, after
                    switch (_short_event_name)
                    {
                        case 'evernote--login--request-second-factor':
                        
                            if ($R.$popup && $R.$popup._which && $R.$popup._which == 'login') {
                                $R.$popup._details._screen = 'second-factor';
                                $R.$popup._details._deliveryHint = _details._deliveryHint;
                            }
                            
                            break;
        
                        case 'evernote--login--set--in':
                        case 'evernote--login--set--in-cn':
                        case 'evernote--login--set--cn':
                        case 'evernote--login--set--cn-in':
        
                            var _localization = '';            
                            switch (_short_event_name)
                            {
                                case 'evernote--login--set--in':    _localization = _short_event_name.substr(-2); break;
                                case 'evernote--login--set--cn':    _localization = _short_event_name.substr(-2); break;
                                case 'evernote--login--set--in-cn': _localization = _short_event_name.substr(-5).replace(/-/g, '_').toLowerCase(); break;
                                case 'evernote--login--set--cn-in': _localization = _short_event_name.substr(-5).replace(/-/g, '_').toLowerCase(); break;
                            }
                                
                            //  set?
                            if (_localization > '') {
                                if ($R.$popup && $R.$popup._which && $R.$popup._which == 'login') {
                                    $R.$popup._details._localization = _localization;
                                }
                            }
        
                            //  try to change now
                            try { chrome.extension.getViews({ 'type': 'popup' })[0].document.getElementById('login__container_which').className = _localization; } catch (_e) {}
        
                            break;
                    }
                };
            
                //  event groups
                //  ============
                    
                    //  evernote events
                    //  ===============
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'evernote--clip':
                                
                                (function () {
                                
                                    //  check login
                                    //  if not logged in, try stored log in 
                                    //      on successfull login, do clip again
                                    //      on failed login, or no stored login, show login form
                                    //    
                                    //  try clip
                                    //      on fail, because of login, try stored login
                                    //          on successfull login, try clip again
                                    //          on failed login, or no stored login, show login form
                                    //  ============================================================
                                    
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                        if ($R.credentials__get_logout_on_next_action()) { $R.$remote.logout(); }
                                        var _storedLogin = $R.credentials__get();
                                
                                            
                                    //  callbacks
                                    //  =========
                                    
                                        var _clipping_successful = function (_id)
                                        {
                                            __event_dispatch('evernote--clip--successful', { '_page_id': _id });
                                
                                            var _domain_name = '';
                                               _domain_name = message._domain;
                                        
                                
                                
                                            var _privilege = ($R.$remote['user__privilege'] ? 'privilege-'+$R.$remote['user__privilege'] : 'blank-privilege');
                                
                                            $R.session_tracking__track();
                                            $R.analytics__track_event('Clip', _domain_name, _privilege);
                                            $R.saved__setLastUsed('clip');
                                        };
                                        
                                        var _clipping_failed = function ()
                                        {
                                            __event_dispatch('evernote--clip--failed');
                                        };
                                
                                        var _request_login = function ()
                                        {
                                            $R.$bootstrap.bootstrap(
                                                
                                                //  bootstrap => success
                                                function ()
                                                {
                                                    __event_dispatch('evernote--login--show--' + ($R.$bootstrap.profiles_as_string2));
                                                
                                                    //__event_dispatch__popup('evernote--login--set--' + ($R.$bootstrap.profiles_as_string2));
                                                    //__event_dispatch__popup('evernote--login--show--in-frame');
                                                    // __event_dispatch('evernote--login--show');
                                                },
                                                
                                                //  bootstrap => failure
                                                function () { _clipping_failed(); });
                                        };
                                        
                                        
                                    //  vars
                                    //  ====
                                         var __id =      message._id,
                                            __url =     message._url, 
                                            __title =   message._title, 
                                            __body =    message._body; 
                                    
                                
                                        
                                    
                                    //  code
                                    //  ====
                                        switch (true)
                                        {
                                            case (!($R.$remote.is__connected)):
                                            case (!($R.$remote.is__loggedIn)):
                                            case (!($R.$remote.is__notExpired())):
                                        
                                                //  not connected / logged-in
                                                //      and we know this; so do connect/login
                                        
                                                //  no stored login
                                                //  ===============
                                                    if (_storedLogin == false) { _request_login(); return; }
                                        
                                                //  do stored login
                                                //  ================
                                                    $R.$remote.loginWithAuthToken(
                                
                                                        _storedLogin.xAuthToken,
                                
                                                        //  login => success
                                                        function ()
                                                        {
                                                            $R.$remote.clip(
                                
                                                                __id,
                                                                __url,
                                                                __title,
                                                                __body,
                                
                                                                //  clip => success
                                                                function () { _clipping_successful(__id); },
                                
                                                                //  clip => failure
                                                                function (_failReason) { _clipping_failed(); });
                                                        },
                                
                                                        //  login => failure
                                                        function (_failReason) { _request_login(); });
                                            
                                                break;
                                            
                                
                                            default:
                                        
                                                //  should be both connected and logged in
                                                //      in case it fails because of login, we try another stored login
                                
                                                $R.$remote.clip(
                                                
                                                    __id,
                                                    __url,
                                                    __title,
                                                    __body,
                                
                                                    //  clip => success
                                                    function () { _clipping_successful(__id); },
                                
                                                    //  clip => failuse
                                                    function (_failReason)
                                                    {
                                                        //  failure because of soemthing else
                                                        if (_failReason == 'login') {}else { _clipping_failed(); return; }
                                
                                                        //  no stored login
                                                        if (_storedLogin == false) { _request_login(); return; }
                                
                                                        //  try stored login
                                                        $R.$remote.loginWithAuthToken(
                                                        
                                                            _storedLogin.xAuthToken,
                                
                                                            //  login => success
                                                            function ()
                                                            {
                                                                $R.$remote.clip(
                                                                
                                                                    __id,
                                                                    __url,
                                                                    __title,
                                                                    __body,
                                
                                                                    //  clip => success
                                                                    function () { _clipping_successful(__id); },
                                
                                                                    //  clip => failure
                                                                    function (_failReason) { _clipping_failed(); });
                                                            },
                                
                                                            //  login => failure
                                                            function (_failReason) { _request_login(); });
                                                    });
                                
                                                break;
                                        }
                                
                                })();
                                
                                _stop = true;
                                break;
                    
                            case 'evernote--clip-highlights':
                                
                                (function () {
                                
                                    //  check login
                                    //      if not logged in, fail 
                                    //      on failed login, fail
                                    //    
                                    //  try highlight
                                    //      on fail, fail
                                    //  ============================================================
                                
                                
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                        if ($R.credentials__get_logout_on_next_action()) { $R.$remote.logout(); }
                                        var _storedLogin = $R.credentials__get();
                                
                                
                                    //  callbacks
                                    //  =========
                                            
                                        var _clipping_successful = function (_id)
                                        {
                                            __event_dispatch('evernote--clip-highlights--successful', { '_page_id': _id });
                                            $R.session_tracking__track();
                                        };
                                        
                                        var _clipping_failed = function ()
                                        {
                                            __event_dispatch('evernote--clip-highlights--failed');
                                        };
                                        
                                        var _request_login = function ()
                                        {
                                            $R.$bootstrap.bootstrap(
                                            
                                                //  bootstrap => success
                                                function ()
                                                {
                                                    __event_dispatch('evernote--login--show--' + ($R.$bootstrap.profiles_as_string2));
                                                
                                                    //__event_dispatch__popup('evernote--login--set--' + ($R.$bootstrap.profiles_as_string2));
                                                    //__event_dispatch__popup('evernote--login--show--in-frame');
                                                    // __event_dispatch('evernote--login--show');
                                                },
                                                
                                                //  bootstrap => failure
                                                function () { _clipping_failed(); });
                                        };
                                
                                
                                    //  vars
                                    //  ====
                                         var __id =      message._id,
                                            __url =     message._url, 
                                            __title =   message._title, 
                                            __body =    message._body; 
                                    
                                
                                    
                                
                                    //  code
                                    //  ====
                                        switch (true)
                                        {
                                            case (!($R.$remote.is__connected)):
                                            case (!($R.$remote.is__loggedIn)):
                                            case (!($R.$remote.is__notExpired())):
                                
                                                //  not connected / logged-in
                                                //      and we know this; so do connect/login
                                
                                                //  no stored login
                                                //  ===============
                                                    if (_storedLogin == false) { _request_login(); return; }
                                        
                                                //  do stored login
                                                //  ================
                                                    $R.$remote.loginWithAuthToken(
                                                    
                                                        _storedLogin.xAuthToken,
                                
                                                        //  login => success 
                                                        function ()
                                                        {
                                                            $R.$remote.clip(
                                                            
                                                                __id,
                                                                __url,
                                                                __title,
                                                                __body,
                                
                                                                //  clip => success 
                                                                function () { _clipping_successful(__id); },
                                
                                                                //  clip => failure
                                                                function (_failReason) { _clipping_failed(); });
                                                        },
                                
                                                        //  login => failure
                                                        function (_failReason) { _request_login(); });
                                            
                                                break;
                                
                                            default:
                                
                                                //  should be both connected and logged in
                                                //      in case it fails because of login, we try stored login
                                        
                                                $R.$remote.clip(
                                                
                                                    __id,
                                                    __url,
                                                    __title,
                                                    __body,
                                
                                                    //  clip => success
                                                    function () { _clipping_successful(__id); },
                                
                                                    //  clip => failure
                                                    function (_failReason)
                                                    {
                                                        //  failure because of soemthing else
                                                        if (_failReason == 'login') {}else { _clipping_failed(); return; }
                                
                                                        //  no stored login
                                                        if (_storedLogin == false) { _request_login(); return; }
                                
                                                        //  try stored login
                                                        $R.$remote.loginWithAuthToken(
                                                        
                                                            _storedLogin.xAuthToken,
                                
                                                            //  login => success
                                                            function ()
                                                            {
                                                                $R.$remote.clip(
                                                                
                                                                    __id,
                                                                    __url,
                                                                    __title,
                                                                    __body,
                                
                                                                    //  clip => success
                                                                    function () { _clipping_successful(message._id); },
                                
                                                                    //  clip => failure
                                                                    function (_failReason) { _clipping_failed(); });
                                                            },
                                
                                                            //  login => failure
                                                            function (_failReason) { _request_login(); });
                                                    });
                                            
                                                break;
                                        }
                                
                                })();
                                
                                _stop = true;
                                break;
                    
                    
                            case 'evernote--get-recommendation':
                                
                                (function () {
                                
                                    //  check login
                                    //      if not logged in, fail 
                                    //      on failed login, fail
                                    //    
                                    //  try get
                                    //      on fail, fail
                                    //  ============================================================
                                
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                        if ($R.credentials__get_logout_on_next_action()) { $R.$remote.logout(); }
                                        var _storedLogin = $R.credentials__get();
                                
                                            
                                    //  callbacks
                                    //  =========
                                
                                        var _get_successful = function (_id)
                                        {
                                            __event_dispatch('evernote--get-recommendation--successful', { '_page_id': _id });
                                        };
                                        
                                        var _get_failed = function ()
                                        {
                                            __event_dispatch('evernote--get-recommendation--failed');
                                        };
                                
                                
                                    //  vars
                                    //  ====
                                         var __id =      message._id,
                                            __url =     message._url, 
                                            __title =   message._title, 
                                            __body =    message._body; 
                                    
                                
                                
                                
                                    //  run code
                                    //  ========        
                                        switch (true)
                                        {
                                            case (!($R.$remote.is__connected)):
                                            case (!($R.$remote.is__loggedIn)):
                                            case (!($R.$remote.is__notExpired())):
                                        
                                                //  not connected / logged-in
                                                //      and we know this -- so do connect/login
                                                
                                                //  no stored login
                                                //  ===============
                                                    if (_storedLogin == false) { _get_failed(); return; }
                                        
                                                //  do stored login
                                                //  ================
                                                    $R.$remote.loginWithAuthToken(
                                                    
                                                        _storedLogin.xAuthToken,
                                
                                                        //  login => success
                                                        function ()
                                                        {
                                                            $R.$remote.get_recommendation(
                                                            
                                                                __id,
                                                                __url,
                                                                __body,
                                
                                                                //  get => success
                                                                function () { _get_successful(__id); },
                                
                                                                //  get => failure
                                                                function (_failReason) { _get_failed(); });
                                                        },
                                
                                                        //  login => failure
                                                        function (_failReason) { _get_failed(); });
                                            
                                                break;
                                            
                                            default:
                                
                                                //    should be both connected and logged in
                                                //        in case it fails because of login, we try another stored login
                                        
                                                $R.$remote.get_recommendation(
                                                
                                                    __id,
                                                    __url,
                                                    __body,
                                
                                                    //  get => success
                                                    function () { _get_successful(__id); },
                                
                                                    //  get => failuse
                                                    function (_failReason) { _get_failed(); });
                                                
                                                break;
                                        }
                                    
                                })();
                                
                                _stop = true;
                                break;
                    
                    
                              //  in firefox, these events --as well as open--two-factor-help-- belong 
                            //  to the secure-login iframe
                             case 'evernote--login--do':
                                
                                (function () {
                                
                                    //  do login
                                    //      store login
                                    //  ===============
                                
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                
                                
                                    //  Long-session Device identification
                                    //  ==================================
                                        var __device_id = $R.saved__get_device_id(),
                                            __os = $R.from_user_agent__get_os(window.navigator.userAgent),
                                            __device_description = '';
                                
                                __device_description = 'Google Chrome'   + ' (' + __os + ')'; 
                                
                                
                                
                                
                                    //  vars
                                    //  ====
                                         var __user = message._user,
                                            __pass = message._pass; 
                                    
                                
                                
                                
                                    //  the actual login
                                    //  ================
                                        $R.$remote.loginLongSession(
                                        
                                            __user,
                                            __pass,
                                        
                                            __device_id,
                                            __device_description,
                                    
                                            //  login => success
                                            function ()
                                            {
                                                //  save credentials
                                                //  ================
                                                    $R.credentials__set({
                                                        'username': $R.$remote.user__email,
                                                        'xAuthToken': $R.$remote.user__authToken
                                                    });
                                            
                                                //  raise event
                                                //  ===========
                                                    __event_dispatch('evernote--login--successful');
                                            },
                                        
                                            //  login => fail
                                            function (_failReason)
                                            {
                                                switch (_failReason)
                                                {
                                                    case 'two-factor':       __event_dispatch__popup('evernote--login--request-second-factor', { '_deliveryHint': $R.$remote.twoFactor__deliveryHint }); break;
                                                    case 'email':            __event_dispatch__popup('evernote--login--failed--email');            break;
                                                    case 'password':         __event_dispatch__popup('evernote--login--failed--password');         break;
                                                    case 'password-reset':   __event_dispatch__popup('evernote--login--failed--password-reset');   break;
                                                    default:                 __event_dispatch__popup('evernote--login--failed');                   break;
                                                }
                                            });
                                
                                })();
                                
                                _stop = true;
                                break;
                             case 'evernote--login--do-second-factor':
                                
                                (function () {
                                
                                    //  do login
                                    //      store login, if rememberMe
                                    //  ==============================
                                
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                
                                
                                    //  Long-session Device identification
                                    //  ==================================
                                        var __device_id = $R.saved__get_device_id(),
                                            __os = $R.from_user_agent__get_os(window.navigator.userAgent),
                                            __device_description = '';
                                
                                __device_description = 'Google Chrome'   + ' (' + __os + ')'; 
                                
                                
                                
                                
                                
                                    //  invalid
                                    //  =======
                                        if ($R.$remote.twoFactor__authToken) {}else
                                        {
                                            __event_dispatch__popup('evernote--login--failed');
                                            return;
                                        }
                                
                                
                                    //  code
                                    //  ====
                                         var __code = message._code;
                                    
                                
                                    
                                
                                    //  the actual login
                                    //  ================
                                    
                                        $R.$remote.loginLongSessionSecondFactor(
                                        
                                            $R.$remote.twoFactor__authToken,
                                            __code,
                                            __device_id,
                                            __device_description,
                                    
                                            //  login => success
                                            function ()
                                            {
                                                //  save credentials
                                                $R.credentials__set({
                                                    'username': $R.$remote.twoFactor__username,
                                                    'xAuthToken': $R.$remote.user__authToken
                                                });
                                            
                                                //  event    
                                                __event_dispatch('evernote--login--successful');
                                            },
                                        
                                            //  login => failure
                                            function (_failReason)
                                            {
                                                switch (_failReason)
                                                {
                                                    case 'code':         __event_dispatch__popup('evernote--login--failed--two-factor--code');     break;
                                                    case 'timeout':      __event_dispatch__popup('evernote--login--failed--two-factor--timeout');  break;
                                                    default:             __event_dispatch__popup('evernote--login--failed');                       break;
                                                }
                                            });
                                
                                })();
                                
                                _stop = true;
                                break;
                        
                            case 'evernote--login--switch-to-cn':
                                
                                (function () {
                                
                                    //  return
                                    if ($R.$bootstrap.profiles_as_string == 'in_cn') {}else { return; }
                                
                                    //  set
                                    $R.$bootstrap.profiles_as_string = 'cn_in';
                                    $R.$bootstrap.server = 'china';
                                    $R.$bootstrap.remote_domain = $R.$bootstrap['server_china'];
                                    
                                    var _other_profile = false;
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[1]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[0]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                    if (_other_profile && _other_profile.settings && _other_profile.settings.marketingUrl) { $R.$bootstrap.remote_domain_marketing = _other_profile.settings.marketingUrl + '/'; }
                                
                                    //  disconnect
                                    $R.$remote.disconnect();
                                
                                    //  notify
                                    __event_dispatch__popup('evernote--login--set--cn-in');
                                
                                })();
                                
                                _stop = true;
                                break;
                             case 'evernote--login--switch-to-in':
                                
                                (function () {
                                
                                    //  return
                                    if ($R.$bootstrap.profiles_as_string == 'cn_in') {}else { return; }
                                    
                                    //  set
                                    $R.$bootstrap.profiles_as_string = 'in_cn';
                                    $R.$bootstrap.server = 'main';
                                    $R.$bootstrap.remote_domain = $R.$bootstrap['server_main'];
                                
                                    var _other_profile = false;
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[0]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[1]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                    if (_other_profile && _other_profile.settings && _other_profile.settings.marketingUrl) { $R.$bootstrap.remote_domain_marketing = _other_profile.settings.marketingUrl + '/'; }
                                
                                    //  disconenct                    
                                    $R.$remote.disconnect();
                                
                                    //  notify
                                    __event_dispatch__popup('evernote--login--set--in-cn');
                                    
                                })();
                                
                                _stop = true;
                                break;
                            
                            
                            case 'evernote--login--now-open':
                                __event_dispatch('evernote--login--now-open');
                                _stop = true;
                                break;
                            
                        
                        } }
                    
                    
                    //  evernote events
                    //  ===============
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'evernote--login--do':
                                
                                (function () {
                                
                                    //  do login
                                    //      store login
                                    //  ===============
                                
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                
                                
                                    //  Long-session Device identification
                                    //  ==================================
                                        var __device_id = $R.saved__get_device_id(),
                                            __os = $R.from_user_agent__get_os(window.navigator.userAgent),
                                            __device_description = '';
                                
                                __device_description = 'Google Chrome'   + ' (' + __os + ')'; 
                                
                                
                                
                                
                                    //  vars
                                    //  ====
                                         var __user = message._user,
                                            __pass = message._pass; 
                                    
                                
                                
                                
                                    //  the actual login
                                    //  ================
                                        $R.$remote.loginLongSession(
                                        
                                            __user,
                                            __pass,
                                        
                                            __device_id,
                                            __device_description,
                                    
                                            //  login => success
                                            function ()
                                            {
                                                //  save credentials
                                                //  ================
                                                    $R.credentials__set({
                                                        'username': $R.$remote.user__email,
                                                        'xAuthToken': $R.$remote.user__authToken
                                                    });
                                            
                                                //  raise event
                                                //  ===========
                                                    __event_dispatch('evernote--login--successful');
                                            },
                                        
                                            //  login => fail
                                            function (_failReason)
                                            {
                                                switch (_failReason)
                                                {
                                                    case 'two-factor':       __event_dispatch__popup('evernote--login--request-second-factor', { '_deliveryHint': $R.$remote.twoFactor__deliveryHint }); break;
                                                    case 'email':            __event_dispatch__popup('evernote--login--failed--email');            break;
                                                    case 'password':         __event_dispatch__popup('evernote--login--failed--password');         break;
                                                    case 'password-reset':   __event_dispatch__popup('evernote--login--failed--password-reset');   break;
                                                    default:                 __event_dispatch__popup('evernote--login--failed');                   break;
                                                }
                                            });
                                
                                })();
                                
                                _stop = true;
                                break;
                    
                            case 'evernote--login--do-second-factor':
                                
                                (function () {
                                
                                    //  do login
                                    //      store login, if rememberMe
                                    //  ==============================
                                
                                    
                                    //  misc
                                    //  ====    
                                        $R.$remote.refresh_settings();
                                
                                
                                    //  Long-session Device identification
                                    //  ==================================
                                        var __device_id = $R.saved__get_device_id(),
                                            __os = $R.from_user_agent__get_os(window.navigator.userAgent),
                                            __device_description = '';
                                
                                __device_description = 'Google Chrome'   + ' (' + __os + ')'; 
                                
                                
                                
                                
                                
                                    //  invalid
                                    //  =======
                                        if ($R.$remote.twoFactor__authToken) {}else
                                        {
                                            __event_dispatch__popup('evernote--login--failed');
                                            return;
                                        }
                                
                                
                                    //  code
                                    //  ====
                                         var __code = message._code;
                                    
                                
                                    
                                
                                    //  the actual login
                                    //  ================
                                    
                                        $R.$remote.loginLongSessionSecondFactor(
                                        
                                            $R.$remote.twoFactor__authToken,
                                            __code,
                                            __device_id,
                                            __device_description,
                                    
                                            //  login => success
                                            function ()
                                            {
                                                //  save credentials
                                                $R.credentials__set({
                                                    'username': $R.$remote.twoFactor__username,
                                                    'xAuthToken': $R.$remote.user__authToken
                                                });
                                            
                                                //  event    
                                                __event_dispatch('evernote--login--successful');
                                            },
                                        
                                            //  login => failure
                                            function (_failReason)
                                            {
                                                switch (_failReason)
                                                {
                                                    case 'code':         __event_dispatch__popup('evernote--login--failed--two-factor--code');     break;
                                                    case 'timeout':      __event_dispatch__popup('evernote--login--failed--two-factor--timeout');  break;
                                                    default:             __event_dispatch__popup('evernote--login--failed');                       break;
                                                }
                                            });
                                
                                })();
                                
                                _stop = true;
                                break;
                        
                            case 'evernote--login--switch-to-cn':
                                
                                (function () {
                                
                                    //  return
                                    if ($R.$bootstrap.profiles_as_string == 'in_cn') {}else { return; }
                                
                                    //  set
                                    $R.$bootstrap.profiles_as_string = 'cn_in';
                                    $R.$bootstrap.server = 'china';
                                    $R.$bootstrap.remote_domain = $R.$bootstrap['server_china'];
                                    
                                    var _other_profile = false;
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[1]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[0]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                    if (_other_profile && _other_profile.settings && _other_profile.settings.marketingUrl) { $R.$bootstrap.remote_domain_marketing = _other_profile.settings.marketingUrl + '/'; }
                                
                                    //  disconnect
                                    $R.$remote.disconnect();
                                
                                    //  notify
                                    __event_dispatch__popup('evernote--login--set--cn-in');
                                
                                })();
                                
                                _stop = true;
                                break;
                    
                            case 'evernote--login--switch-to-in':
                                
                                (function () {
                                
                                    //  return
                                    if ($R.$bootstrap.profiles_as_string == 'cn_in') {}else { return; }
                                    
                                    //  set
                                    $R.$bootstrap.profiles_as_string = 'in_cn';
                                    $R.$bootstrap.server = 'main';
                                    $R.$bootstrap.remote_domain = $R.$bootstrap['server_main'];
                                
                                    var _other_profile = false;
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[0]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                        _other_profile = (_other_profile ? _other_profile : $R.$bootstrap.profiles[1]);
                                        _other_profile = (($R.$bootstrap.getProfileName__short(_other_profile) == 'cn') ? _other_profile : false);
                                    if (_other_profile && _other_profile.settings && _other_profile.settings.marketingUrl) { $R.$bootstrap.remote_domain_marketing = _other_profile.settings.marketingUrl + '/'; }
                                
                                    //  disconenct                    
                                    $R.$remote.disconnect();
                                
                                    //  notify
                                    __event_dispatch__popup('evernote--login--set--in-cn');
                                    
                                })();
                                
                                _stop = true;
                                break;
                    
                            /* === */            
                                
                            case 'evernote--login--now-open':
                                __event_dispatch('evernote--login--now-open');
                                _stop = true;
                                break;
                        } }
                    
                    
                    //  open events
                    //  ===========
                    
                           var _options_url = 'chrome-extension://iooicodkiihhpojmmeghjclgihfjdjhj/options/page.html';
                        var _register_url = 'chrome-extension://iooicodkiihhpojmmeghjclgihfjdjhj/register/page.html';
                    
                        
                    
                        
                        if (_stop) {}else { switch (_short_event_name)
                        {
                    
                            
                             case 'open--settings':          $R.open_url_in_new_tab(_options_url);               _stop = true; break;
                            case 'open--settings--theme':   $R.open_url_in_new_tab(_options_url+'#showCustom'); _stop = true; break;
                             case 'open--register--footer':  $R.open_url_in_new_tab(_register_url);              _stop = true; break;
                        
                    
                            /* both */
                                case 'open--premium':
                                    
                                        try
                                        {
                                            var _upgrade_url = $R.$bootstrap.remote_domain + 'Checkout.action' + '?origin=' + 'clearly-chrome',
                                                _full_url = $R.$bootstrap.remote_domain + 'SetAuthToken.action?auth=' + encodeURIComponent($R.$remote.user__authToken) + '&targetUrl=' + encodeURIComponent(_upgrade_url);
                                            
                                            $R.open_url_in_new_tab(_full_url);
                                        }
                                        catch (_e) {}
                                    
                                    _stop = true;
                                    break;
                            /* both */
                        } }
                        
                    
                    //  open events
                    //  ===========
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'open--two-factor-help':
                                
                                    var defaultLoginPath = 'https://www.evernote.com/';
                                    $R.$bootstrap.bootstrap(
                                    
                                        //  bootstrap => success
                                        function ()
                                        {
                                            var _url = '';
                                                _url = (_url > '' ? _url : $R.$bootstrap.remote_domain);
                                                _url = (_url > '' ? _url : defaultLoginPath); 
                                                _url = _url + 'TwoStepHelp.action?auth='+encodeURIComponent($R.$remote.twoFactor__authToken);
                                
                                            $R.open_url_in_new_tab(_url);
                                        },
                                        
                                        //  bootstrap => fail
                                        function ()
                                        {
                                            var _url = defaultLoginPath;
                                                _url = _url + 'TwoStepHelp.action?auth='+encodeURIComponent($R.$remote.twoFactor__authToken);
                                
                                            $R.open_url_in_new_tab(_url);
                                        });
                                
                                _stop = true;
                                break;
                    
                            case 'open--password-reset':
                                
                                    var defaultLoginPath = 'https://www.evernote.com/';
                                    $R.$bootstrap.bootstrap(
                                    
                                        //  bootstrap => success
                                        function ()
                                        {
                                            var _url = '';
                                                _url = (_url > '' ? _url : $R.$bootstrap.remote_domain);
                                                _url = (_url > '' ? _url : defaultLoginPath); 
                                                _url = _url + 'Login.action?targetUrl=%2FChangePassword.action%3Fv1%3Dtrue';
                                                
                                            $R.open_url_in_new_tab(_url);
                                        },
                                        
                                        //  bootstrap => fail
                                        function ()
                                        {
                                            var _url = defaultLoginPath;
                                                _url = _url + 'Login.action?targetUrl=%2FChangePassword.action%3Fv1%3Dtrue';
                                    
                                            $R.open_url_in_new_tab(_url);
                                        });
                                
                                _stop = true;
                                break;
                                
                            case 'open--register--popup':
                            
                                   var _register_url = 'chrome-extension://iooicodkiihhpojmmeghjclgihfjdjhj/register/page.html';
                                $R.open_url_in_new_tab(_register_url);
                            
                        
                    
                            
                                _stop = true;
                                break;
                        } }
                        
                    
                    //  select events
                    //  =============
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'select--theme--theme-1':                $R.saved__select__theme('theme-1'); _stop = true; break;
                            case 'select--theme--theme-2':                $R.saved__select__theme('theme-2'); _stop = true; break;
                            case 'select--theme--theme-3':                $R.saved__select__theme('theme-3'); _stop = true; break;
                            case 'select--theme--custom':                 $R.saved__select__theme('custom');  _stop = true; break;
                        
                            case 'select--size--small':                   $R.saved__select__size('small');  _stop = true; break;
                            case 'select--size--medium':                  $R.saved__select__size('medium'); _stop = true; break;
                            case 'select--size--large':                   $R.saved__select__size('large');  _stop = true; break;
                    
                            case 'select--related-notes--just-at-bottom': $R.saved__select__related_notes('just_at_bottom'); _stop = true; break;
                            case 'select--related-notes--disabled':       $R.saved__select__related_notes('disabled');       _stop = true; break;
                        } }
                        
                    
                    //  track events
                    //  ============
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'track--view':
                            
                                var _domain_name = '', _theme_name = '';
                                   _domain_name = message._domain;
                                _theme_name = message._theme;
                            
                    
                    
                                $R.session_tracking__track();
                                $R.analytics__track_event('View', _domain_name, _theme_name);
                                $R.saved__setLastUsed('view');
                                
                                _stop = true;
                                break;
                        
                            case 'track--theme-popup':
                                $R.session_tracking__track();
                                $R.analytics__track_event('Theme Popup', 'Theme Popup');
                                
                                _stop = true; 
                                break;
                    
                            /* === */
                    
                            case 'track--first-show--check':
                                switch (true)
                                {
                                    case (!($R.firstShow)):                                                                      break;
                                    case ($R.firstShow == 'new-features'): __event_dispatch('show--dialog-first--new-features'); break;
                                    case ($R.firstShow == 'all-features'): __event_dispatch('show--dialog-first--all-features'); break;
                                }
                                _stop = true;
                                break;
                            
                            case 'track--first-show--mark':
                    
                                //  this instance
                                $R.firstShow = true;
                    
                                //  persist
                                $R.storage__set('firstShowIdentifier', $R.first_show_identifier);
                    
                                _stop = true;
                                break;
                                
                            /* === */
                    
                            case 'track--evernote-footer--check':
                            
                                //  get login
                                var _storedLogin = $R.credentials__get();
                    
                                //  not logged in
                                if (_storedLogin) {}else { __event_dispatch('show--evernote-footer'); }
                    
                                _stop = true;
                                break;
                            
                        } }
                        
                    
                    //  track events
                    //  ============
                        if (_stop) {}else { switch (_short_event_name)
                        {
                            case 'track--reminder--shown':
                                //  no session tracking: we don't consider a user active when they close a reminder
                                //  but we do want to know how many reminders were closed
                            
                                //  last shown
                                $R.saved__setLastUsed('reminderShown');
                            
                                //$R.session_tracking__track();
                                $R.analytics__track_event('Reminder Shown', 'Reminder Shown');
                                
                                _stop = true;
                                break;
                    
                            case 'track--reminder--clicked':
                                $R.session_tracking__track();
                                $R.analytics__track_event('Reminder Clicked', 'Reminder Clicked');
                                
                                //  launch -- in current tab
                                $R.launch();
                                
                                _stop = true;
                                break;
                                
                            case 'track--reminder--closed':
                                //  no session tracking: we don't consider a user active when they see a reminder
                                //  but we do want to know how many reminders we're showning
                            
                                //$R.session_tracking__track();
                                $R.analytics__track_event('Reminder Closed', 'Reminder Closed');
                    
                                //  last closed
                                $R.saved__setLastUsed('reminderClosed');
                    
                                //  close reminder -- in current tab
                                $R.closeReminder();
                            
                                _stop = true;
                                break;
                        } }
                        
        
                //  chrome-only events
                //  ==================
                    if (_stop) {}else { switch (_short_event_name)
                    {
                        case 'load-info':
                        
                            //  get profile
                            var _profile = $R.$bootstrap.saved_server;
                                _profile = ((_profile == 'china') ? 'cn' : $R.$bootstrap.profiles_as_string);
                                _profile = ((_profile > '') ? _profile : 'none');
        
                            //  get reminder info
                            var _reminder_info = {
                                'profile':                 _profile,
                                'lastUsed_view':           $R.saved__getLastUsed('view'),
                                'lastUsed_reminderShown':  $R.saved__getLastUsed('reminderShown'),
                                'lastUsed_reminderClosed': $R.saved__getLastUsed('reminderClosed')
                            };
                                
                            //  send
                            sendResponse({
                                '_options':       $R.saved__get_options(),
                                '_vars':          $R.saved__get_vars(),
                                '_translation':   $R.translation__items,
                                
                                '_reminder_info': _reminder_info  
                            });
                            
                            //  stop
                            _stop = true;
                            break;
                    } }
                
                //  stop
                if (_stop) { sendResponse({}); }
            });
        
        
        //  events handler for independent pages -- e.g. options, registor
        //  ===================
            $R.events_handler__independent_pages = function (_event_name, _params)
            {
                //  invalid
                if (_event_name) {}else { return; }
                
                //  other
                if (_event_name.indexOf('to-extension--') === 0) {}else { return; }
                
                //  vars
                var _short_event_name = _event_name.substr('to-extension--'.length);
            
                //  event
                var _stop = false;
                
                //  track events
                //  ============
                    if (_stop) {}else { switch (_short_event_name)
                    {
                        case 'track--settings':
                            $R.session_tracking__track();
                            $R.analytics__track_event('Settings Page', 'Settings Page');
                            
                            _stop = true;
                            break;
                
                        case 'track--register--shown':
                            $R.session_tracking__track();
                            $R.analytics__track_event('Register Shown', 'Register Shown');
                            
                            _stop = true;
                            break;
                
                        case 'track--register--completed':
                            $R.session_tracking__track();
                            $R.analytics__track_event('Register Completed', 'Register Completed');
                            
                            _stop = true;
                            break;
                            
                        case 'evernote--login--do-after-register':
                
                            //  no callbacks; fire and forget
                        
                            //  shortened, simplified copy of events.include/evernote__login__do.js
                            (function () {
                
                                //  check that params exist
                                if (_params && _params['user'] && _params['pass']) {}else { return; }
                
                                //  do login
                                //      store login
                                //  ===============
                    
                                //  misc
                                $R.$remote.refresh_settings();
                
                                //  Long-session device-identification
                                var __device_id = $R.saved__get_device_id(),
                                    __os = $R.from_user_agent__get_os(window.navigator.userAgent),
                                    __device_description = '';
                __device_description = 'Google Chrome'   + ' (' + __os + ')'; 
                
                
                
                                //  vars
                                var __user = _params['user'],
                                    __pass = _params['pass']; 
                
                                //  the actual login
                                $R.$remote.loginLongSession(
                                    __user, __pass, __device_id, __device_description,
                                    function ()
                                    {
                                        //  save credentials
                                        $R.credentials__set({
                                            'username': $R.$remote.user__email,
                                            'xAuthToken': $R.$remote.user__authToken
                                        });
                                    },
                    
                                    //  login => fail
                                    function (_failReason) { });
                
                            })();
                        
                            break;
                    } }
                    
            };
        

        $R.$bootstrap.initialize();        
        $R.$remote.refresh_settings();

        $R.assure_defaults();

        $R.first__show();
        $R.first__run();
        
        $R.translation__get_items();

    })(window.__readable_by_evernote);
