###global define###

define ['libs/angular', 'services/services', 'libs/angularResource'], (angular, services) ->
  'use strict'

  defaults =
    url: '/api/accounts'

  services.factory 'accountService', ['$resource', '$http', '$filter', ($resource, $http, $filter) ->
    getAll = (params) ->
      $http
        method : 'GET'
        url    : defaults.url
        headers:
          'Accept': 'application/json'

    getById = (id) ->
      $http
        method : 'GET'
        url    : defaults.url + '/' + id
        headers:
          'Accept': 'application/json'

    create = (params) ->
      $http
        method : 'POST'
        url    : defaults.url
        data : params

    update = (params, original) ->
      dataDiff = $filter 'diffEntity'
      data = dataDiff params, original, modelAttributes
      $http
        method : 'PUT'
        url    : defaults.url + '/' + params.id
        data : data

    # API
    {getAll, getById, create, update}
  ]