'use strict'

define(([
  'app'
  'libs/text!../views/main.html'
]), (app, mainTemplate) ->
  console.log 'main:routes'

  app.config(['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->

    # Use location API, fall back to hash URLs
    #$locationProvider.html5Mode(true)

    #$routeProvider.when '/accounts'
    #  controller : 'accountController'
    #  template   : accountTemplate

    $routeProvider.when '/stats'
      controller     : 'contentController'
      template       : mainTemplate
      reloadOnSearch : false

    $routeProvider.otherwise
      redirectTo : '/stats'
  ])

)