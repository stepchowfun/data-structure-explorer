# make textareas autoresize
$ ->
  $('[data-toggle=tooltip]').tooltip()
  $('textarea').autosize()

onDomChange = () ->
  $('[data-toggle=tooltip]').tooltip('destroy').tooltip()
  $('textarea').trigger('autosize.destroy').autosize()

# application module
cherries = angular.module('cherries', ['models'])

# application controller
cherries.controller('CherriesController', ['$scope', 'models', 'runCommand', ($scope, models, runCommand) ->
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
          code: 'function insert(value, subtree) {\n  if (get_root() == null) {\n    set_root(make_node({ value: value }));\n  } else {\n    if (subtree == undefined) {\n      subtree = get_root();\n    }\n    if (value < get_field(subtree, "value")) {\n      if (get_field(subtree, "left_child") == null) {\n        set_field(subtree, "left_child", make_node({ value: value }));\n      } else {\n        insert(value, get_field(subtree, "left_child"));\n      }\n    }\n    else if (value > get_field(subtree, "value")) {\n      if (get_field(subtree, "right_child") == null) {\n        set_field(subtree, "right_child", make_node({ value: value }));\n      } else {\n        insert(value, get_field(subtree, "right_child"));\n      }\n    } else {\n      throw Error("Value already exists: " + JSON.stringify(value) + ".");\n    }\n  }\n}'
        },
        {
          name: 'remove',
          code: 'function remove(bst, key) {\n\n}'
        },
        {
          name: 'contains',
          code: 'function contains(bst, key) {\n\n}'
        }
      ],
      compiledOperations: null,
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
          name: 'remove',
          code: 'function remove(st, key) {\n\n}'
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
      compiledOperations: null,
      model: models[1]
    }
    {
      name: 'Test data structure',
      fields: [],
      operations: [
        {
          name: 'foo',
          code: 'function foo() {\n  bar();\n}'
        },
        {
          name: 'bar',
          code: 'function bar() {\n  console.log(10);\n}'
        }
      ],
      compiledOperations: null,
      model: models[0]
    },
  ]

  # other global application state
  $scope.active_page = 0
  $scope.active_data_structure = $scope.data_structures[0]

  # switch to the editor
  $scope.editDataStructure = (data_structure) ->
    $scope.active_page = 0
    $scope.active_data_structure = data_structure
    setTimeout(onDomChange, 1)

  # switch to the explorer
  $scope.exploreDataStructure = (data_structure) ->
    $scope.active_page = 1
    $scope.active_data_structure = data_structure
    setTimeout(onDomChange, 1)

  # a helper to be called on click
  $scope.stopClick = (event) ->
    event.preventDefault()
    event.stopPropagation()

  # a helper that makes a string out of anything
  $scope.stringify = (value) ->
    return JSON.stringify(value)

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

  compileOperations = (operations, model) ->
    compiledOperations = []
    context = { }
    for api_fn_name, api_fn of model.api
      eval('var ' + api_fn_name + ' = api_fn;')
    for operation in operations
      eval('var ' + operation.name + ' = undefined;')
    for operation in operations
      try
        compiledOperation = {
          name: operation.name,
          fn: (() ->
            eval(operation.code)
            return eval(operation.name)
          )()
          error: null
        }
        if !compiledOperation.fn?
          throw Error(operation.name + ' is not defined.')
        else
          eval(operation.name + ' = compiledOperation.fn;')
      catch error
        if error == null or typeof error != 'object'
          error = {
            name: 'Error',
            message: 'Unexpected error: ' + JSON.stringify(error) + '.'
          }
        if !error.name?
          error.name = 'Error'
        if !error.message?
          error.message = 'Unexpected error.'
        compiledOperation = {
          name: operation.name,
          fn: null,
          error: error
        }
      compiledOperations.push(compiledOperation)
    return compiledOperations

  initialize_data_structure = (data_structure) ->
    for operation in data_structure.operations
      operation.arguments = get_arguments(operation.code, operation.name)
    data_structure.compiledOperations = compileOperations(data_structure.operations, data_structure.model)

  window.data_structures = $scope.data_structures
  for data_structure in data_structures
    initialize_data_structure(data_structure)

  $scope.$watch('data_structures', (() ->
    for data_structure in data_structures
      initialize_data_structure(data_structure)
    setTimeout(onDomChange, 1)
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

  # fields

  $scope.new_field_name = null
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = (data_structure) ->
    if !$scope.new_field_name? or $scope.new_field_name == ''
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

  $scope.moveFieldUp = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? and index > 0
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index - 1, 0, field)

  $scope.moveFieldDown = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? and index < data_structure.fields.length - 1
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index + 1, 0, field)

  $scope.deleteField = (data_structure, field) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index?
      data_structure.fields.splice(index, 1)

  # operations

  $scope.new_operation_name = null
  $scope.new_operation_error = null

  $scope.clearAddOperationError = () ->
    $scope.new_operation_error = null

  $scope.addOperation = (data_structure) ->
    if !$scope.new_operation_name? or $scope.new_operation_name == ''
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
      code: 'function ' + $scope.new_operation_name + '() {\n\n}',
    })
    $scope.new_operation_name = ''
    $scope.clearAddOperationError()

  $scope.moveOperationUp = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? and index > 0
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index - 1, 0, operation)

  $scope.moveOperationDown = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? and index < data_structure.operations.length - 1
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index + 1, 0, operation)

  $scope.deleteOperation = (data_structure, operation) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index?
      data_structure.operations.splice(index, 1)

  ############################################################################
  # explorer
  ############################################################################

  $scope.new_command_str = null
  $scope.new_command_error = null

  $scope.resetState = () ->
    if $scope.active_data_structure?
      switch $scope.active_data_structure.model
        when models[0]
          $scope.computationState = $scope.active_data_structure.model.getInitialState({ fields: $scope.active_data_structure.fields })
        when models[1]
          $scope.computationState = $scope.active_data_structure.model.getInitialState({ })
      $scope.computationModel = $scope.active_data_structure.model
      $scope.command_history = []
    else
      $scope.computationState = null
      $scope.command_history = null
      $scope.computationModel = null
    $scope.command_history_cursor = null
    $scope.command_history_step_cursor = null

  $scope.resetState()

  $scope.clearNewCommandError = () ->
    $scope.new_command_error = null

  $scope.newCommand = () ->
    if !$scope.active_data_structure?
      $scope.new_command_error = 'Select a data structure first.'
      return

    if !$scope.new_command_str? or $scope.new_command_str == ''
      $scope.new_command_error = 'Please enter a command.'
      return

    if $scope.haveCommandHistory() and $scope.computationModel != $scope.active_data_structure.model
      $scope.new_command_error = 'Reset the state or set the model of computation back to: ' + $scope.computationModel.name + '.'
      return
    $scope.computationModel = $scope.active_data_structure.model

    $scope.fastForward(true)
    result = runCommand($scope.computationState, $scope.new_command_str, $scope.active_data_structure.compiledOperations)
    if result.error?
      $scope.new_command_error = result.error.name + ': ' + result.error.message
      return
    command = {
      str: $scope.new_command_str,
      steps: result.steps,
      return_value: result.return_value
    }
    $scope.command_history.push(command)
    if command.steps.length > 0
      $scope.command_history_cursor = $scope.command_history.length - 1
      $scope.command_history_step_cursor = command.steps.length - 1
    $scope.new_command_str = ''
    $scope.clearNewCommandError()

  $scope.haveCommandHistory = () ->
    return $scope.command_history? and $scope.command_history.length > 0

  $scope.stepBackward = (scroll) ->
    if $scope.command_history? and $scope.command_history.length > 0
      if $scope.command_history_cursor == null
        return
      cursor = $scope.command_history_cursor
      step_cursor = $scope.command_history_step_cursor - 1
      while step_cursor == -1
        cursor -= 1
        if cursor == -1
          cursor = null
          step_cursor = null
          break
        step_cursor = $scope.command_history[cursor].steps.length - 1
      $scope.command_history[$scope.command_history_cursor].steps[$scope.command_history_step_cursor].down($scope.computationState)
      $scope.command_history_cursor = cursor
      $scope.command_history_step_cursor = step_cursor
      if scroll
        setTimeout((() ->
          if $scope.command_history_cursor? and $scope.command_history_step_cursor?
            elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
            if elements.length > 0
              elements[0].scrollIntoView()
        ), 1)

  $scope.stepForward = (scroll) ->
    if $scope.command_history? and $scope.command_history.length > 0
      if $scope.command_history_cursor == null
        cursor = 0
        step_cursor = 0
      else
        cursor = $scope.command_history_cursor
        step_cursor = $scope.command_history_step_cursor + 1
      while step_cursor == $scope.command_history[cursor].steps.length
        cursor += 1
        step_cursor = 0
        if cursor == $scope.command_history.length
          return
      $scope.command_history_cursor = cursor
      $scope.command_history_step_cursor = step_cursor
      $scope.command_history[cursor].steps[step_cursor].up($scope.computationState)
      if scroll
        setTimeout((() ->
          if $scope.command_history_cursor? and $scope.command_history_step_cursor?
            elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
            if elements.length > 0
              elements[0].scrollIntoView()
        ), 1)

  $scope.fastBackward = (scroll) ->
    while $scope.canStepBackward()
      $scope.stepBackward(false)
    if scroll
      setTimeout((() ->
        $('#command-history').scrollTop(0)
      ), 1)

  $scope.fastForward = (scroll) ->
    while $scope.canStepForward()
      $scope.stepForward(false)
    if scroll
      setTimeout((() ->
        if $scope.command_history_cursor? and $scope.command_history_step_cursor?
          elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
          if elements.length > 0
            elements[0].scrollIntoView()
      ), 1)

  $scope.canStepBackward = () ->
    if $scope.command_history? and $scope.command_history.length > 0
      if $scope.command_history_cursor == null
        return false
      return true
    return false

  $scope.canStepForward = () ->
    if $scope.command_history? and $scope.command_history.length > 0
      if $scope.command_history_cursor == null
        cursor = 0
        step_cursor = 0
      else
        cursor = $scope.command_history_cursor
        step_cursor = $scope.command_history_step_cursor + 1
      while step_cursor == $scope.command_history[cursor].steps.length
        cursor += 1
        step_cursor = 0
        if cursor == $scope.command_history.length
          return false
      return true
    return false

])
