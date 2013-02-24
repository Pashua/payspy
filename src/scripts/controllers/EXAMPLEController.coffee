###global define###

define ['controllers/controllers', 'services/statisticService'], (controllers) ->
  'use strict'

  CONTENT_ID = 'connections'

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

  QUERY_TYPES =
    LIST_CONTACTS  : 'listContacts'
    LIST_TEAMS     : 'listTeams'
    LIST_INCOMINGS : 'listIncomings'
    LIST_OUTGOINGS : 'listOutgoings'
    SHOW_TEAM      : 'showTeam'

  ADDRESSES_SPLIT_REGEXP= /(?:,| )+/
  ADDRESSES_JOIN_STRING=', '

  controllers.controller 'statisticController', ['$scope', '$location', 'statisticService', '$timeout', ($scope, $location, statisticService, $timeout) ->

    ctrlElement = $('section.hlx-connections')

    $scope.state = STATES.INIT
    
    $scope.newTeam   = {}
    $scope.updTeam   = {}
    $scope.origTeam  = {}
    
    $scope.newInvitation = {}
    
    $scope.team = state : STATES.ACTIVE, data : {}
    $scope.teamMembers = state : STATES.ACTIVE, data  : {}
    
    # TODO move to directive?!
    $scope.imageUpload = []
    
    # lists
    $scope.contacts = state : STATES.ACTIVE, data : []
    $scope.teams    = state : STATES.ACTIVE, data : []

    $scope.contactsIncoming = state : STATES.ACTIVE, data : []
    $scope.contactsOutgoing = state : STATES.ACTIVE, data : []

    $scope.teamsIncomingByUser = state : STATES.ACTIVE, data : []
    $scope.teamsOutgoingByUser = state : STATES.ACTIVE, data : []
    $scope.teamsIncomingByTeam = state : STATES.ACTIVE, data : []
    $scope.teamsOutgoingByTeam = state : STATES.ACTIVE, data : []

    $scope.userSearchResults = state : STATES.ACTIVE, data : {}, searchTerm : ''
    $scope.teamSearchResults = state : STATES.ACTIVE, data : {}, searchTerm : ''

    $scope.queryType = QUERY_TYPES.LIST_CONTACTS

    $scope.lastRequest =
      params: {}
      hash:   {}

    $scope.lastResponse =
      params:
        never: true
      paging:
        limit: -1

    $scope.sorterList =
      title       : $.i18n.prop 'ui.common.list.sorter.title'
      requestParam: 'sortBy'
      items : [{
        requestValue : 'deadline'
        title : $.i18n.prop 'ui.common.list.sorter.items.name'
      },{
        requestValue : 'priority'
        title : $.i18n.prop 'ui.common.list.sorter.items.email'
      }]

    ###
      Internals
    ###

    initialize = (history) ->
      console.log 'called init contactController'
      
      $scope.state = STATES.ACTIVE
      
      $scope.lastRequest =
        params : history.search
        hash   : history.hash

    # Internal: Refresh the controller / view.
    refresh = ->
      return unless $scope.state is STATES.ACTIVE

      params = $scope.lastRequest.params

      $scope.state = STATES.RUNNING

      loadTeams params

    loadContent  = (params, section) ->
      request = null

      $scope.queryType = params.queryType or QUERY_TYPES.LIST_CONTACTS

      # set page title
      # TODO $scope.setPageTitle key: 'ui.common.page.contacts.title'

      switch $scope.queryType
        when QUERY_TYPES.LIST_CONTACTS
          loadContacts params
        when QUERY_TYPES.LIST_TEAMS
          loadTeams params
        when QUERY_TYPES.LIST_INCOMINGS
          loadIncomings params
        when QUERY_TYPES.LIST_OUTGOINGS
          loadOutgoings params
        when QUERY_TYPES.SHOW_TEAM
          loadTeam params.id

    loadContacts = (params) ->
      $scope.contacts.state = STATES.RUNNING
      request = contactService.getAll angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.contacts.data  = data.contacts
        $scope.contacts.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on contacts fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    loadTeams = (params) ->
      $scope.teams.state = STATES.RUNNING
      request = teamService.getAll angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teams.data  = data.teams
        $scope.teams.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on teams fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    loadTeam = (id) ->
      $scope.team.state = STATES.RUNNING
      request = teamService.getById(id)
      request.success (data, status, headers, config) ->
        $scope.team.data  = data
        $scope.team.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on team fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    # TODO separate lists? The wireframes shows ONE list for incomings
    loadIncomings  = (params) ->
      $scope.contactsIncoming.state = STATES.RUNNING
      request = contactService.getIncomings angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.contactsIncoming.data  = data.contacts
        $scope.contactsIncoming.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on contactsIncoming fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

      $scope.teamsIncomingByUser.state = STATES.RUNNING
      request = teamMemberService.getAllIncomingsByUser angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teamsIncomingByUser.data  = data.members
        $scope.teamsIncomingByUser.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on teamsIncomingByUser fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

      $scope.teamsIncomingByTeam.state = STATES.RUNNING
      request = teamMemberService.getAllIncomingsByTeam angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teamsIncomingByTeam.data  = data.members
        $scope.teamsIncomingByTeam.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on teamsIncomingByTeam fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    # TODO separate lists? The wireframes shows ONE list for outgoings
    loadOutgoings  = (params) ->
      $scope.contactsOutgoing.state = STATES.RUNNING
      request = contactService.getOutgoings angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.contactsOutgoing.data  = data.contacts
        $scope.contactsOutgoing.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on contactsOutgoing fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

      $scope.teamsOutgoingByUser.state = STATES.RUNNING
      request = teamMemberService.getAllOutgoingsByUser angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teamsOutgoingByUser.data  = data.members
        $scope.teamsOutgoingByUser.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on teamsOutgoingByUser fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg
      
      $scope.teamsOutgoingByTeam.state = STATES.RUNNING
      request = teamMemberService.getAllOutgoingsByTeam angular.extend params, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teamsOutgoingByTeam.data  = data.members
        $scope.teamsOutgoingByTeam.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on teamsOutgoingByTeam fetch. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    modifyUriParams = (event, searchParams = event) ->
      params = $location.search()
      angular.extend params, searchParams
      for own key, val of searchParams
        delete params[key] if val is null
      $location.search params

    substractObjectFromArray = (minuend, subtrahend, field) ->
      for m in subtrahend
        idx = minuend.indexOf m[field]
        continue if idx is -1
        minuend.splice idx, 1

    releaseTeam = () ->
      $scope.newTeam  = {}
      $scope.updTeam  = {}
      $scope.origTeam = {}

    ######

    $scope.showModal = (type) ->
      console.log 'show modal - TEAM:' + type
      $("##{type}").modal()
      # here is the chance to prefill some input fields

    $scope.onContactAction = (type, id) ->
      console.log 'prepare for contact action:' + type
      switch type
        when 'confirm'
          q = contactService.confirm id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.contactsIncoming.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.confirmed', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on confirming contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'delete'
          q = contactService.destroy id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.contacts.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.deleted', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on deleting contact. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'sendRequest'
          q = contactService.sendRequest id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.userSearchResults.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.created', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on sending contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'reject'
          q = contactService.reject id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.contactsIncoming.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.rejected', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on rejecting contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'revoke'
          q = contactService.revoke id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.contactsOutgoing.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.revoked', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on revoking contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'revokeInvite'
          q = contactService.revokeInvite id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.contactsOutgoing.data, 'user.emailAddress':id
            appUtils.notyInfo $.i18n.prop 'ui.connections.contact.message.revoked', removedItem.user.emailAddress
          q.error (response, status) ->
            msg = "Error #{status} on revoking contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg

    $scope.onTeamAction = (type, id) ->
      console.log 'prepare for team action:' + type
      liveTeamOfTeams = (item for item in $scope.teams.data when item.id is id)[0] # TODO utilize
      switch type
        when 'edit'
          console.log 'getting team preparing action:' + type
          q = teamService.getById id
          q.success (team) ->
            $scope.origTeam = angular.copy team
            $scope.updTeam = angular.copy team
            $scope.showModal "#{type}Team"
          q.error ->
            msg = 'error getting team for action dialog'
            console.info msg
            appUtils.notyError msg
        when 'delete'
          q = teamService.destroy id
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teams.data, id:id
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.deleted', removedItem.name
          q.error (response, status) ->
            msg = "Error #{status} on deleting team. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg

    $scope.onTeamMemberAction = (type, teamId, memberId) ->
      console.log 'prepare for teamMember action:' + type
      switch type
        when 'delete'
          q = teamMemberService.destroy teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamMembers.data, id:memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.member.message.deleted', removedItem.display
          q.error (response, status) ->
            msg = "Error #{status} on deleting team. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'leave'
          q = teamMemberService.destroy teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teams.data, id:teamId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.leaved', removedItem.name
          q.error (response, status) ->
            msg = "Error #{status} on leaving team. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'confirmRequestByUser'
          q = teamMemberService.confirmByUser teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsIncomingByUser.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byUser.confirmed', removedItem.team.name
          q.error (response, status) ->
            msg = "Error #{status} on confirming contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'rejectRequestByUser'
          q = teamMemberService.rejectByUser teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsIncomingByUser.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byUser.rejected', removedItem.team.name
          q.error (response, status) ->
            msg = "Error #{status} on rejecting contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'revokeRequestByUser'
          q = teamMemberService.revokeByUser teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsOutgoingByUser.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byUser.revoked', removedItem.team.name
          q.error (response, status) ->
            msg = "Error #{status} on revoking contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'confirmRequestByTeam'
          q = teamMemberService.confirmByTeam teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsIncomingByTeam.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byTeam.confirmed', removedItem.user.display, removedItem.team.name
          q.error (response, status) ->
            msg = "Error #{status} on confirming contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'rejectRequestByTeam'
          q = teamMemberService.rejectByTeam teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsIncomingByTeam.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byTeam.rejected', removedItem.user.display, removedItem.team.name
          q.error (response, status) ->
            msg = "Error #{status} on rejecting contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg
        when 'revokeRequestByTeam'
          q = teamMemberService.revokeByTeam teamId, memberId
          q.success (response, status) ->
            removedItem = controllerUtils.removeListItem $scope.teamsOutgoingByTeam.data, 'team.id':teamId,'user.id':memberId
            appUtils.notyInfo $.i18n.prop 'ui.connections.team.message.request.byTeam.revoked', removedItem.team.name, removedItem.user.display
          q.error (response, status) ->
            msg = "Error #{status} on revoking contact request. Server-Message: '#{response.message}'"
            console.error msg
            appUtils.notyError msg

    ###
      ACTIONS
    ###

    $scope.createTeam = () ->
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

    $scope.updateTeam = () ->
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

    $scope.searchUsers = () ->
      $scope.userSearchResults.state = STATES.RUNNING
      request = userService.search @userSearchResults.searchTerm, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.userSearchResults.data  = data.users
        $scope.userSearchResults.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on searching users. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    $scope.searchTeams = () ->
      $scope.teamSearchResults.state = STATES.RUNNING
      request = teamService.search @teamSearchResults.searchTerm, paging : (limit: 100, offset: 0)
      request.success (data, status, headers, config) ->
        $scope.teamSearchResults.data  = data.teams
        $scope.teamSearchResults.state = STATES.READY
      request.error (response, status) ->
        msg = "Error #{status} on searching teams. Server-Message: '#{response.message}'"
        console.error msg
        appUtils.notyError msg

    $scope.invite = (dialog) ->
      invitation = angular.copy $scope.newInvitation
      addresses = invitation.addresses.split(ADDRESSES_SPLIT_REGEXP)
      invitation.addresses = addresses

      contactService.invite(invitation)
        .error ->
          console.error "An error occured.", arguments
        .success (data) ->
          $scope.newInvitation.message = {}
          successfulAddresses = substractObjectFromArray(addresses, data.invitations, 'emailAddress')
          successfulAddressesString = successfulAddresses.join(ADDRESSES_JOIN_STRING)

          if addresses.length <= 0
            controllerUtils.hideModalDialog $('#' + dialog.modalId)
            $scope.newInvitation = {}
            msg = $.i18n.prop 'ui.contacts.invitation.success.addresses', successfulAddressesString
            appUtils.notyInfo msg
          else
            addressesString = addresses.join(ADDRESSES_JOIN_STRING)
            $scope.newInvitation.addresses = addressesString
            $scope.newInvitation.message.error = $.i18n.prop 'ui.contacts.invitation.error.addresses', addressesString
            if successfulAddressesString.length > 0
              msg = $.i18n.prop 'ui.contacts.invitation.success.addresses', successfulAddressesString
              appUtils.notyInfo msg

    ######

    ###
      EVENTS
    ###

    $scope.$watch 'history', (history) ->
      historyCopy = angular.copy history
      initialize(historyCopy)
      if historyCopy.pathChanged
        refresh()
        loadContent historyCopy.search, historyCopy.hash
      else if historyCopy.searchChanged
        loadContent historyCopy.search, historyCopy.hash
    , true

    $scope.$on 'filterSelected', modifyUriParams
    $scope.$on 'sorterSelected', modifyUriParams

    $scope.$on 'reloadData', (event, arg) ->
      loadContent $scope.lastRequest.params

    console.info 'contactController ready.'
  ]