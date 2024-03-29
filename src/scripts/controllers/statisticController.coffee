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
    LOADING   : 'loading'
    # Controller has finished, view should be active.
    READY     : 'ready'

  controllers.controller 'statisticController', ['$scope', '$rootScope', '$filter', 'statisticService', 'accountService', '$timeout', ($scope, $rootScope, $filter, statisticService, accountService, $timeout) ->

    ctrlElement = $('section.tw-statistics')

    $scope.dateSelected =
      from : null
      to : null

    $scope.months = state : STATES.ACTIVE, data : []
    
    $scope.markStatItem = {}

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

      loadStatisticsMonth()


    ######

    loadAccount = (id) ->
      console.log 'called loadAccount'
      request = accountService.getById id
      request.success (data, status, headers, config) ->
        $scope.account = angular.copy data
      request.error (response, status) ->
        msg = "Error #{status} on load account. Server-Message: '#{response.message}'"
        console.error msg

    loadStatisticsMonth = () ->
      console.log 'called loadStatisticsMonth'
      $scope.months.state = STATES.LOADING
      
      params =
        account: $scope.account.id
        dateFrom: if $scope.dateSelected.from then $filter('date')($scope.dateSelected.from, 'yyyy-MM-dd') else ''
        dateTo: if $scope.dateSelected.to then $filter('date')($scope.dateSelected.to, 'yyyy-MM-dd') else ''
      
      request = statisticService.getMonths params
      request.success (data, status, headers, config) ->
        $scope.months.data  = data
        $scope.months.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on fetching month statistic data. Server-Message: '#{response.message}'"
        console.error msg

    loadStatisticsCategories = (month, scope, onSuccess) ->
      console.log 'called loadStatisticsCategories'
      scope.categories.state = STATES.LOADING
      scope.errorMsg = ''
      
      params =
        account: $scope.account.id
        month: month
      
      request = statisticService.getCategories params
      request.success (data, status, headers, config) ->
        scope.categories.data  = data
        scope.categories.state = STATES.READY
        onSuccess()
      request.error (response, status) ->
        msg = "ERROR #{status} #{response.message}'"
        scope.errorMsg = msg
    
    loadStatisticsStickyData = (month, scope, onSuccess) ->
      console.log 'called loadStatisticsStickyData'
      scope.stickyData.state = STATES.LOADING
      scope.errorMsg = ''
      
      params =
        account: $scope.account.id
        month: month
      
      request = statisticService.getStickyRawdata params
      request.success (data, status, headers, config) ->
        scope.stickyData.data  = data
        scope.stickyData.state = STATES.READY
        onSuccess()
      request.error (response, status) ->
        msg = "ERROR #{status} #{response.message}'"
        scope.errorMsg = msg
    
    loadStatisticsRawdata = (month, category, scope, onSuccess) ->
      console.log 'called loadStatisticsRawdata'
      scope.rawdata.state = STATES.LOADING
      scope.errorMsg = ''
      
      params =
        account: $scope.account.id
        month: month
        category: category
      
      request = statisticService.getRawdata params
      request.success (data, status, headers, config) ->
        scope.rawdata.data  = data
        scope.rawdata.state = STATES.READY
        onSuccess()
      request.error (response, status) ->
        msg = "ERROR #{status} #{response.message}'"
        scope.errorMsg = msg

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

    $scope.markStatisticItem = (rawData) ->
      console.log "mark statistic item... id:#{rawData.id}"
      stickyList = @stickyData.data
      reqParams = angular.copy @markStatItem
      rawData.notes = reqParams.notes
      q = statisticService.markItem rawData.id, reqParams.notes
      q.success (data) ->
        stickyList.push rawData
      q.error (response) ->
        console.log 'ERROR while adding sticky annotation!'

    $scope.onLoadMonths = (month) ->
      # initialize the new object
      @months = state : STATES.LOADING, data : []
      # load content
      $timeout () ->
        onSuccess = () -> $scope.showElement "#catData#{month}"
        loadStatisticsMonth()
      , 1

    $scope.onLoadCategories = (month) ->
      scope = this
      @dataIsOpen = if @dataIsOpen is undefined then true else !@dataIsOpen
      
      if not @dataIsOpen
        $scope.hideElement "#catData#{month}"
      else
        # initialize the new categories-object
        @categories = state : STATES.LOADING, data : []
        # initialize the new sticky-data-object
        @stickyData = state : STATES.LOADING, data : []
        
        # load categories
        $timeout () ->
          onSuccess = () -> $scope.showElement "#catData#{month}"
          loadStatisticsCategories(month, scope, onSuccess)
        , 1
        # load sticky-data
        $timeout () ->
          onSuccess = () -> $scope.showElement "#stickyData#{month}"
          loadStatisticsStickyData(month, scope, onSuccess)
        , 1
    
    $scope.onLoadRawData = (month, catId) ->
      scope = this
      @dataIsOpen = if @dataIsOpen is undefined then true else !@dataIsOpen
      
      if not @dataIsOpen
        $scope.hideElement "#rawData#{month}-#{catId}"
      else
        # initialize the new object
        @rawdata = state : STATES.LOADING, data : []
        # load content
        $timeout () ->
          onSuccess = () -> $scope.showElement "#rawData#{month}-#{catId}"
          loadStatisticsRawdata(month, catId, scope, onSuccess)
        , 1
    
    # set in scope or not?!
    $scope.showElement = (elemSel) ->
      return unless $(elemSel).length
      $timeout () ->
        $(elemSel).show('blind')
      , 1
    
    # set in scope or not?!
    $scope.hideElement = (elemSel) ->
      return unless $(elemSel).length
      $(elemSel).hide('blind')

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