# initialize Foundation
$ -> $(document).foundation()

# application module
cherries = angular.module('cherries', [])

cherries.controller('CherriesController', ['$scope', ($scope) ->
  $scope.active_page = 0

  $scope.fields = []
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = (event) ->
    if !$scope.new_field_name? || $scope.new_field_name == ''
      $scope.new_field_error = 'Please enter a name.'
      return
    if $scope.new_field_name in $scope.fields
      $scope.new_field_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_field_name))
      $scope.new_field_error = 'Invalid name.'
      return
    $scope.fields.push($scope.new_field_name)
    $scope.new_field_name = ''
    $scope.clearAddFieldError()
    setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()

  $scope.moveFieldUp = (field, event) ->
    index = null
    for name, i in $scope.fields
      if name == field
        index = i
        break
    if index? && index > 0
      $scope.fields.splice(index, 1)
      $scope.fields.splice(index - 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_link_' + field).click()), 1)

  $scope.moveFieldDown = (field, event) ->
    index = null
    for name, i in $scope.fields
      if name == field
        index = i
        break
    if index? && index < $scope.fields.length - 1
      $scope.fields.splice(index, 1)
      $scope.fields.splice(index + 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_link_' + field).click()), 1)

  $scope.removeField = (field, event) ->
    index = null
    for name, i in $scope.fields
      if name == field
        index = i
        break
    if index?
      $scope.fields.splice(index, 1)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
])

get_root = () ->

set_root = (node) ->

make_node = () ->

get_field = (node, field) ->

set_field = (node, field, value) ->
