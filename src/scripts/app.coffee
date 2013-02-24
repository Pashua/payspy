###global define###

define([
  'libs/angular'
  'controllers/controllers'
  'directives/directives'
  'filters/filters'
  'libs/angularResource'
  'responseInterceptors/responseInterceptors'
  'services/services'
  'libs/angularUi'
  'libs/angularStrap'
], (angular) ->
  'use strict'

  angular.module 'app', [
    'controllers'
    'directives'
    'filters'
    'ngResource'
    'responseInterceptors'
    'services'
    'ui'
    '$strap.directives'
  ]
)