###global define###

define ['controllers/controllers', 'services/accountService'], (controllers) ->
  'use strict'

  CONTENT_ID = 'account'

  STATES =
    _         : null
    # After construction, controller and view are not active.
    INIT      : 'init'
    # Controller and view should be active.
    ACTIVE    : 'active'
    # Controller is loading data, view should be active.
    LOADING   : 'loading'
    # Controller has finished, view should be active.
    READY     : 'ready'
    # Controller and view are not active. Just like init, but after an activation life cycle
    NON_ACTIVE: 'non_active'

  MODES =
    LIST      : 'list'
    EDIT      : 'edit'
    ADD       : 'add'
    START     : 'start'

  controllers.controller 'accountController', ['$scope', '$rootScope', '$location', 'accountService', '$timeout', ($scope, $rootScope, $location, accountService, $timeout) ->

    ctrlElement = $('section.tw-accounts')

    $scope.newAccount   = data : []
    $scope.updAccount   = state : STATES.ACTIVE, data : []
    $scope.origAccount  = data : []
    
    # lists
    $scope.accounts = state : STATES.ACTIVE, data : []
    
    $scope.accountId = null

    $scope.mode = MODES.LIST

    $scope.lastRequest =
      params: {}
      hash:   {}


    ###
      Internals
    ###

    initialize = (history) ->
      console.log 'called init accountController'
      $scope.lastRequest =
        params : history.search

    loadContent  = (params) ->
      console.log 'called loadContent'
      
      $scope.mode = if params.mode then params.mode else MODES.LIST
      $scope.accountId = if params.account then params.account else ''
      
      switch $scope.mode
        when MODES.LIST
          delete $rootScope.account if $rootScope.account
          # load accounts for selection
          loadAccounts()
        when MODES.EDIT
          delete $rootScope.account if $rootScope.account
          # load account for updating
          loadAccount($scope.accountId, false)
        when MODES.START
          loadAccount($scope.accountId, true)


    ######


    loadAccounts = () ->
      console.log 'called loadAccounts'
      $scope.accounts.state = STATES.LOADING
      request = accountService.getAll()
      request.success (data, status, headers, config) ->
        $scope.accounts.data  = data
        $scope.accounts.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on contacts fetch. Server-Message: '#{response.message}'"
        console.error msg

    loadAccount = (id, copyToRootScope) ->
      console.log 'called loadAccount'
      $scope.updAccount.state = STATES.LOADING
      request = accountService.getById(id)
      request.success (data, status, headers, config) ->
        $scope.origAccount.data = angular.copy data 
        $scope.updAccount.data = angular.copy data
        $scope.updAccount.state = STATES.READY
        if copyToRootScope
          $rootScope.account = angular.copy data
      request.error (response, status) ->
        msg = "Error #{status} on loading account. Server-Message: '#{response.message}'"
        console.error msg

    releaseAccount = () ->
      $scope.newAccount  = data : []
      $scope.updAccount  = state : STATES.ACTIVE, data : []
      $scope.origAccount = data : []
    
    #onEditAccount = () ->
    #  console.log 'called onEditAccount'
    #  $scope.origAccount.data = angular.copy $rootScope.account
    #  $scope.updAccount.data = angular.copy $rootScope.account

    ######

    $scope.onEditAccount = (id) ->
      console.log 'called onEditAccount'
      $location.search 'mode', MODES.EDIT
      $location.search 'account', id
   
    $scope.onCancelEdit = () ->
      console.log 'called onCancelEdit'
      $location.search 'mode', MODES.LIST
      #$location.search 'account', id

    $scope.onStartStatistic = (id) ->
      console.log 'called onStartStatistic'
      $location.search 'mode', MODES.START
      $location.search 'account', id

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

    $scope.$watch 'history', (history) ->
      console.info "watcher for 'history' of accountController | val:#{history}"
      return unless history
      historyCopy = angular.copy history
      initialize(historyCopy)
      if historyCopy.pathChanged or historyCopy.searchChanged
        loadContent historyCopy.search
    , true

    $scope.$on 'reloadData', (event, arg) ->
      loadContent $scope.lastRequest.params

    console.info 'accountController ready.'
  ]