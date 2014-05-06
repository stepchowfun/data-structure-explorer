# initialize Foundation
$ -> $(document).foundation()

window.CherriesController = ($scope) ->
  $scope.active_page = 0

  $scope.fields = []
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = () ->
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

  $scope.removeField = (field) ->
    index = null
    for name, i in $scope.fields
      if name == field
        index = i
        break
    if index?
      $scope.fields.splice(index, 1)

get_root = () ->

set_root = (node) ->

make_node = () ->

get_field = (node, field) ->

set_field = (node, field, value) ->
