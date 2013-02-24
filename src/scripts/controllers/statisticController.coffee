###global define###

define ['controllers/controllers', 'services/statisticService', 'services/accountService'], (controllers) ->
  'use strict'

  CONTENT_ID = 'account'

  STATES =
    _         : null
    # After construction, controller and view are not active.
    INIT      : 'init'
    # Controller and view should be active.
    ACTIVE    : 'active'
    # Controller is loading data, view should be active.
    RUNNING   : 'running'
    # Controller has finished, view should be active.
    READY     : 'ready'
    # Controller and view are not active. Just like init, but after an activation life cycle
    NON_ACTIVE: 'non_active'

  controllers.controller 'statisticController', ['$scope', '$rootScope', '$location', 'statisticService', 'accountService', '$timeout', ($scope, $rootScope, $location, statisticService, accountService, $timeout) ->

    ctrlElement = $('section.tw-statistics')

    $scope.dateSelected =
      from : null
      to : null

    $scope.months = state : STATES.ACTIVE, data : []

    $scope.lastRequest =
      params: {}
      hash:   {}


    ###
      Internals
    ###

    initialize = (history) ->
      console.log 'called init statisticController'
      $scope.lastRequest =
        params : history.search

    # TODO
    getDefaultDateFrom = () ->
      from = new Date()
      from.setMonth 1
      return from

    # TODO
    getDefaultDateTo = () ->
      to = new Date()
      return to

    loadContent  = (params) ->
      console.log 'called loadContent'
      
      $scope.dateSelected.from = if params.dateFrom then params.dateFrom else getDefaultDateFrom()
      $scope.dateSelected.to = if params.dateTo then params.dateTo else getDefaultDateTo()
      
      if params.account and not $scope.account
        loadAccount(params.account)

      loadStatistics()


    ######

    loadAccount = (id) ->
      console.log 'called loadAccount'
      request = accountService.getById id
      request.success (data, status, headers, config) ->
        $scope.account = angular.copy data
      request.error (response, status) ->
        msg = "Error #{status} on load account. Server-Message: '#{response.message}'"
        console.error msg

    loadStatistics = () ->
      console.log 'called loadStatistics'
      $scope.months.state = STATES.RUNNING
      
      request = statisticService.getMonths()
      request.success (data, status, headers, config) ->
        $scope.months.data  = data
        $scope.months.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on fetching statistic data. Server-Message: '#{response.message}'"
        console.error msg

    releaseAccount = () ->
      $scope.newAccount  = data : []
      $scope.updAccount  = state : STATES.ACTIVE, data : []
      $scope.origAccount = data : []
    
    onEditAccount = (id) ->
      console.log 'called onEditAccount'
      $scope.updAccount.state = STATES.RUNNING
      request = accountService.getById id
      request.success (data, status, headers, config) ->
        $scope.origAccount.data = angular.copy data
        $scope.updAccount.data = angular.copy data
        $scope.updAccount.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on contacts fetch. Server-Message: '#{response.message}'"
        console.error msg


    ######


    ###
      ACTIONS
    ###

    $scope.addAccount = () ->
      console.log 'creating the team...'
      reqParams = angular.copy @newTeam
      q = teamService.create reqParams
      q.success (team) ->
        $scope.teams.data.push team
        releaseTeam()
        # hide and reset the modal dialog
        modalDialog = ctrlElement.find('.hlx-modal:visible')
        if modalDialog
          modalDialog.modal "hide"
      q.error (response) ->
        console.info 'error creating team'
        msg = response.message?.toLowerCase() or 'error'
        # the dialog should watch on requestError and show it
        $scope.$broadcast 'requestError', msg

    $scope.updateAccount = () ->
      console.log 'updating the team...'
      liveTeam = if $scope.team.id is $scope.updTeam.id then $scope.team
      liveTeamOfTeams = (item for item in $scope.teams.data when item.id is $scope.updTeam.id)[0] # TODO utilize
      
      reqParams = angular.copy @updTeam
      q = teamService.update reqParams, $scope.origTeam
      q.success (team) ->
        angular.extend liveTeam, team if liveTeam
        angular.extend liveTeamOfTeams, team if liveTeamOfTeams
        releaseTeam()
        # hide and reset the modal dialog
        modalDialog = ctrlElement.find('.hlx-modal:visible')
        if modalDialog
          modalDialog.modal "hide"
      q.error (response) ->
        console.info 'error updating team'
        msg = response.message?.toLowerCase() or 'error'
        # the dialog should watch on requestError and show it
        $scope.$broadcast 'requestError', msg

    ######

    ###
      EVENTS
    ###

    $scope.$watch 'account', (account) ->
      console.info "watcher for 'account'of statisticController"
      return unless $scope.account
      historyCopy = angular.copy $scope.history
      initialize(historyCopy)
      loadContent historyCopy.search
    , true

    $scope.$on 'reloadData', (event, arg) ->
      loadContent $scope.lastRequest.params

    console.info 'statisticController ready.'
  ]