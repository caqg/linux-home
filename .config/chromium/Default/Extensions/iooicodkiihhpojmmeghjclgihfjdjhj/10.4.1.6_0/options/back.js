
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
        



    
    })(window.__readable_by_evernote__options__back);


//  import _js_anywhere/
//  ====================
    (function ($R) {
    
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

    })(window.__readable_by_evernote__options__back);


//  import _js_background/
//  =========================
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
                
        
        
    })(window.__readable_by_evernote__options__back);


//  ==========================================================================================================================


//  run
//  ===
    (function ($R) {

        $R.$bootstrap.initialize();
    
        $R.$remote.setting__related_notes = 'disabled';
        $R.$remote.setting__smart_filing = 'disabled';
        $R.$remote.setting__smart_filing_for_business = 'disabled';
        $R.$remote.setting__open_notes_in = 'web';
        $R.$remote.setting__clip_tag = '';
        $R.$remote.setting__clip_notebook = '';
        $R.$remote.setting__clip_notebook_guid = '';

    })(window.__readable_by_evernote__options__back);
