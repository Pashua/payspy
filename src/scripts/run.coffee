'use strict'

define(['app'], (app) ->
  app.run(['$rootScope', '$location', ($rootScope, $location) ->
    console.log 'main:run'

    $rootScope.session = checked : false

    # These events are fired by responseInterceptor
    $rootScope.$on 'error:unauthorized', (event, response) ->
      console.error 'unauthorized'
      return

    $rootScope.$on 'error:forbidden', (event, response) ->
      console.error 'FORBIDDEN: Permission denied!'
      return

    # fire an event related to the current route
    $rootScope.$on '$routeChangeSuccess', (event, currentRoute, priorRoute) ->
      #console.debug 'routeChanged', currentRoute?.params?.filter, priorRoute?.params?.filter
      ctrl = currentRoute.controller or 'account'
      $rootScope.activeSection = ctrl.replace('Controller', '').toLowerCase()

    console.info 'App started!'
  ])

)