###global define, require###

requirejs(
  map  :
    '*':
      'libs/angularResource': 'libs/angular-resource'
      'libs/angularUi'      : 'libs/angular-ui'
      'libs/angularStrap'   : 'libs/angular-strap'
  paths:
    'jquery'                : 'libs/jquery/jquery-1.9.1'
    'jquery.ui'             : 'libs/jquery/jquery.ui'
    'jquery.maskedinput'    : 'libs/jquery/jquery.maskedinput'
    
    #'jquery.noty'           : 'libs/jquery/noty/jquery.noty'
    #'jquery.noty.layout'    : 'libs/jquery/noty/layouts/bottomRight'
    #'jquery.noty.theme'     : 'libs/jquery/noty/themes/default'

    'iframe-transport'      : 'libs/jquery/fileupload/jquery.iframe-transport' # The Iframe Transport is required for browsers without support for XHR file uploads.
    'jquery.fileupload'     : 'libs/jquery/fileupload/jquery.fileupload' # The basic File Upload plugin.

    'twitter-bootstrap-button'   : 'libs/twitter-bootstrap/bootstrap-button'
    'twitter-bootstrap-collapse' : 'libs/twitter-bootstrap/bootstrap-collapse'
    'twitter-bootstrap-dropdown' : 'libs/twitter-bootstrap/bootstrap-dropdown'
    'twitter-bootstrap-modal'    : 'libs/twitter-bootstrap/bootstrap-modal'
    'twitter-bootstrap-tooltip'  : 'libs/twitter-bootstrap/bootstrap-tooltip'
    'twitter-bootstrap-popover'  : 'libs/twitter-bootstrap/bootstrap-popover'

    'angular-locale': 'libs/i18n/angular-locale_de-de'
    'jquery-locale' : 'libs/i18n/jquery.ui.datepicker-de'
    'angular-strap' : 'libs/angular-strap'
  shim :
    'libs/angular'              : (deps: ['jquery'], exports: 'angular')
    'jquery'                    : (exports: 'jQuery')
    'jquery.ui'                 : (deps: ['jquery'], exports: 'jQuery.ui')
    'twitter-bootstrap-button'  : (deps: ['jquery'], exports: 'jQuery.fn.button')
    'twitter-bootstrap-collapse': (deps: ['jquery'], exports: 'jQuery.fn.collapse')
    'twitter-bootstrap-dropdown': (deps: ['jquery'], exports: 'jQuery.fn.dropdown')
    'twitter-bootstrap-modal'   : (deps: ['jquery'], exports: 'jQuery.fn.modal')
    'twitter-bootstrap-tooltip' : (deps: ['jquery'], exports: 'jQuery.fn.tooltip')
    'twitter-bootstrap-popover' : (deps: ['jquery', 'twitter-bootstrap-tooltip'], exports: 'jQuery.fn.popover')
    'jquery.fileupload'         : (deps: ['jquery','jquery.ui'])
    
    #'jquery.noty'               : (deps: ['jquery'])
    #'jquery.noty.layout'        : (deps: ['jquery','jquery.noty'])
    #'jquery.noty.theme'         : (deps: ['jquery','jquery.noty'])
    
    'jquery-locale'             : (deps: ['jquery.ui'])
    'jquery.maskedinput'        : (deps: ['jquery'])
    'libs/angular-resource'     : (deps: ['libs/angular'])
    'libs/angular-ui'           : (deps: ['libs/angular', 'jquery.maskedinput'])
    'libs/angular-strap'        : (deps: ['libs/angular'])
    'angular-locale'            : (deps: ['libs/angular'])
    
  ([
    'app'
    'bootstrap'
    'jquery.ui'
    #'jquery.noty'
    #'jquery.noty.layout'
    #'jquery.noty.theme'
    'twitter-bootstrap-button'
    'twitter-bootstrap-collapse'
    'twitter-bootstrap-dropdown'
    'twitter-bootstrap-modal'
    'twitter-bootstrap-tooltip'
    'twitter-bootstrap-popover'
    'controllers/accountController'
    'controllers/statisticController'
    'controllers/contentController'
    'directives/twFileUpload'
    #'filters/filesize'
    'responseInterceptors/dispatcher'
    'jquery.maskedinput'
    'angular-locale'
    'jquery-locale'
    'routes'
    'run'
  ]), (app) ->
  console.log 'main'
)