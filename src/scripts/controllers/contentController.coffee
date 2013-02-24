###global define###

define ['controllers/controllers'], (controllers) ->
  'use strict'

  controllers.controller 'contentController', ['$scope', '$rootScope', '$location', ($scope, $rootScope, $location) ->
    $rootScope.activeSection = 'account'
    historyOld = {}
    nextHistory = null

    # before path change
    $scope.$on '$routeChangeStart', (event, next, current) ->
      unless $rootScope.history
        $rootScope.history = {}
      
      if not $rootScope.account and $location.path() isnt '/accounts'
        console.log 'No account is selected! Go to account section'
        event.preventDefault()
        $location.path '/accounts'
      else
        historyOld = angular.copy $rootScope.history

    # handle path change
    $scope.$on '$routeChangeSuccess', (current, previous) ->
      unless $rootScope.history
        $rootScope.history = {}

      $rootScope.history =
        path: angular.copy $location.path()
        search: angular.copy $location.search()
        hash: angular.copy $location.hash()
        pathChanged: true
        searchChanged: false

    # handle param changes
    $scope.$on '$routeUpdate', (route, b) ->
      historyOld = angular.copy $rootScope.history

      $rootScope.history =
        search: angular.copy $location.search()
        hash: angular.copy $location.hash()
        pathChanged: false
        searchChanged: true
  ]