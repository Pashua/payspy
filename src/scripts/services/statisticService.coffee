###global define###

define ['libs/angular', 'services/services', 'libs/angularResource'], (angular, services) ->
  'use strict'

  defaults =
    url: '/api/statistics'

  services.factory 'statisticService', ['$resource', '$http', '$filter', ($resource, $http, $filter) ->
    getMonths = (params) ->
      $http
        method : 'GET'
        url    : defaults.url + '/months'
        headers:
          'Accept': 'application/json'
        params: params

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
    {getMonths, getById, create, update}
  ]