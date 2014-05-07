# initialize Foundation
$ ->
  # foundationify the page
  $(document).foundation()

  # close dropdowns automatically
  $('.dropdown, .f-dropdown').click((event) ->
    Foundation.libs.dropdown.close($(event.target).closest('.dropdown, .f-dropdown'))
  )

# application module
cherries = angular.module('cherries', ['models'])

# application controller
cherries.controller('CherriesController', ['$scope', 'models', ($scope, models) ->
  ############################################################################
  # global
  ############################################################################

  # models of computation
  $scope.models = models

  # list of data structures
  $scope.data_structures = [
    {
      name: 'Binary search tree',
      fields: ['value', 'left_child', 'right_child'],
      operations: [
        {
          name: 'insert',
          code: 'function insert(bst, key, value) {\n\n}'
        },
        {
          name: 'delete',
          code: 'function delete(bst, key) {\n\n}'
        },
        {
          name: 'find',
          code: 'function find(bst, key) {\n\n}'
        },
        {
          name: 'traverse',
          code: 'function traverse(bst, callback) {\n\n}'
        }
      ],
      model: models[0]
    },
    {
      name: 'Splay tree',
      fields: [],
      operations: [
        {
          name: 'insert',
          code: 'function insert(st, key, value) {\n\n}'
        },
        {
          name: 'delete',
          code: 'function delete(st, key) {\n\n}'
        },
        {
          name: 'find',
          code: 'function find(st, key) {\n\n}'
        },
        {
          name: 'traverse',
          code: 'function traverse(st, callback) {\n\n}'
        }
      ],
      model: models[1]
    }
  ]

  # other global application state
  $scope.active_page = 1
  $scope.active_data_structure = $scope.data_structures[0]

  # a helper to be called on click
  $scope.stopClick = (event) ->
    event.preventDefault()
    event.stopPropagation()

  ############################################################################
  # editor
  ############################################################################

  get_arguments = (code, function_name) ->
    regex = new RegExp('function(\\s)+' + function_name + '(\\s)*\\(', 'g')
    result = regex.exec(code)
    if !result?
      return null
    if result.index > 0 and /[\$_a-zA-Z0-9]/g.test(code[result.index - 1])
      return null
    args_pos = result.index + result[0].length
    args = []
    code = code.slice(args_pos)
    while true
      arg_regex = /^(\s)*[\$_a-zA-Z][\$_a-zA-Z0-9]*(\s)*(,|\))/g
      result = arg_regex.exec(code)
      if !result?
        break
      arg = result[0].slice(0, result[0].length - 1).replace(/^\s+|\s+$/g, '')
      args.push(arg)
      code = code.slice(result[0].length)
      if result[0][result[0].length - 1] == ')'
        break
    return args

  initialize_data_structure = (data_structure) ->
    for operation in data_structure.operations
      operation.arguments = get_arguments(operation.code, operation.name)

  window.data_structures = $scope.data_structures
  for data_structure in data_structures
    initialize_data_structure(data_structure)

  $scope.$watch('data_structures', (() ->
    for data_structure in data_structures
      for operation in data_structure.operations
        operation.arguments = get_arguments(operation.code, operation.name)
  ), true)

  # data structures

  $scope.newDataStructure = () ->
    data_structure = {
      name: '',
      fields: [],
      operations: [],
      model: models[0]
    }
    initialize_data_structure(data_structure)
    $scope.data_structures.push(data_structure)
    $scope.editDataStructure(data_structure)

  $scope.deleteDataStructure = (data_structure) ->
    index = null
    for ds, i in data_structures
      if ds == data_structure
        index = i
        break
    if index?
      if active_data_structure == data_structure
        active_data_structure = null
      data_structures.splice(index, 1)
      if data_structures.length == 0
        $scope.editDataStructure(null)
      else
        $scope.editDataStructure(data_structures[0])
      setTimeout((() -> $(document).foundation()), 1)

  $scope.editDataStructure = (data_structure) ->
    $scope.active_page = 0
    $scope.active_data_structure = data_structure

  $scope.exploreDataStructure = (data_structure) ->
    $scope.active_page = 1
    $scope.active_data_structure = data_structure

  # fields

  $scope.new_field_name = null
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = (data_structure) ->
    if !$scope.new_field_name? || $scope.new_field_name == ''
      $scope.new_field_error = 'Please enter a name.'
      return
    if $scope.new_field_name in data_structure.fields
      $scope.new_field_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_field_name))
      $scope.new_field_error = 'Invalid name.'
      return
    data_structure.fields.push($scope.new_field_name)
    $scope.new_field_name = ''
    $scope.clearAddFieldError()
    setTimeout((() -> $(document).foundation()), 1)

  $scope.moveFieldUp = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? && index > 0
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index - 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)

  $scope.moveFieldDown = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? && index < data_structure.fields.length - 1
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index + 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)

  $scope.deleteField = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index?
      data_structure.fields.splice(index, 1)
      setTimeout((() -> $(document).foundation()), 1)

  # operations

  $scope.new_operation_name = null
  $scope.new_operation_error = null

  $scope.clearAddOperationError = () ->
    $scope.new_operation_error = null

  $scope.addOperation = (data_structure) ->
    if !$scope.new_operation_name? || $scope.new_operation_name == ''
      $scope.new_operation_error = 'Please enter a name.'
      return
    if $scope.new_operation_name in (operation.name for operation in data_structure.operations)
      $scope.new_operation_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_operation_name))
      $scope.new_operation_error = 'Invalid name.'
      return
    data_structure.operations.push({
      name: $scope.new_operation_name,
      code: '',
    })
    $scope.new_operation_name = ''
    $scope.clearAddOperationError()
    setTimeout((() -> $(document).foundation()), 1)

  $scope.moveOperationUp = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? && index > 0
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index - 1, 0, operation)
      setTimeout((() -> $(document).foundation()), 1)

  $scope.moveOperationDown = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? && index < data_structure.operations.length - 1
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index + 1, 0, operation)
      setTimeout((() -> $(document).foundation()), 1)

  $scope.deleteOperation = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index?
      data_structure.operations.splice(index, 1)
      setTimeout((() -> $(document).foundation()), 1)

  ############################################################################
  # explorer
  ############################################################################

  $scope.new_command_str = null
  $scope.new_command_error = null
  $scope.command_history = []
  $scope.computationState = null
  if $scope.active_data_structure?
    $scope.computationState = $scope.active_data_structure.model.getInitialState()

  $scope.clearNewCommandError = () ->
    $scope.new_command_error = null

  $scope.newCommand = () ->
    if !$scope.new_command_str? || $scope.new_command_str == ''
      $scope.new_command_error = 'Please enter a command.'
      return
    $scope.command_history.push({
      str: $scope.new_command_str,
      steps: $scope.active_data_structure.model.getCommandSteps($scope.computationState, $scope.new_command_str)
    })
    $scope.new_command_str = ''
    $scope.clearNewCommandError()
    setTimeout((() ->
      $('#command-history').scrollTop($('#command-history').prop('scrollHeight'))
    ), 1)

])
