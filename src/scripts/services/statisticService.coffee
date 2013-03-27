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

    getCategories = (params) ->
      month = params.month
      $http
        method : 'GET'
        url    : defaults.url + "/months/#{month}/categories"
        headers:
          'Accept': 'application/json'
        params: params

    getRawdata = (params) ->
      month = params.month
      category = params.category
      
      $http
        method : 'GET'
        url    : defaults.url + "/months/#{month}/categories/#{category}/rawdata"
        headers:
          'Accept': 'application/json'
        params: params

    getStickyRawdata = (params) ->
      month = params.month
      category = params.category
      
      $http
        method : 'GET'
        url    : defaults.url + "/months/#{month}/sticky"
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

    markItem = (id, notes) ->
      data = notes: notes
      $http
        method : 'PUT'
        url    : defaults.url + '/raw/' + id
        data : data

    # API
    {getMonths, getCategories, getRawdata, getStickyRawdata, getById, create, markItem}
  ]