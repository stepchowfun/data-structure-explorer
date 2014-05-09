# initialize the DOM

loaded = false
codemirrors = [ ]

$ ->
  loaded = true
  $('[data-toggle=tooltip]').tooltip()
  $('.replace-with-codemirror').each((index, element) ->
    textarea = $(element).parent().find('textarea')
    editor = CodeMirror(((e) ->
      $(element).replaceWith(e)
    ), {
      tabSize: 2,
      lineNumbers: true,
      value: $(textarea).val()
    })
    editor.on('change', (args) ->
      $(textarea).val(editor.getValue())
      $(textarea).change().trigger("input")
    )
    codemirrors.push(editor)
  )

# application module
cherries = angular.module('cherries', ['models', 'examples', 'debounce', 'makeString', 'sandbox'])

# application controller
cherries.controller('CherriesController', ['$scope', 'models', 'runCommand', 'examples', 'debounce', 'makeString', 'sandbox', ($scope, models, runCommand, examples, debounce, makeString, sandbox) ->
  ############################################################################
  # global
  ############################################################################

  # models of computation
  $scope.models = models

  # list of data structures
  $scope.data_structures = examples

  # other global application state
  $scope.active_page = 1
  $scope.active_data_structure = $scope.data_structures[2]

  # switch to the editor
  $scope.editDataStructure = (data_structure) ->
    $scope.active_page = 0
    $scope.active_data_structure = data_structure

  # switch to the explorer
  $scope.exploreDataStructure = (data_structure) ->
    $scope.active_page = 1
    $scope.active_data_structure = data_structure

  # a helper to be called on click
  $scope.stopClick = (event) ->
    event.preventDefault()
    event.stopPropagation()

  # a helper that makes a string out of anything
  $scope.makeString = makeString

  # this updates a few DOM-related things
  $scope.$watch(debounce((() ->
    if loaded
      $('[data-toggle=tooltip]').tooltip('destroy').tooltip()
      $('.replace-with-codemirror').each((index, element) ->
        textarea = $(element).parent().find('textarea')
        editor = CodeMirror(((e) ->
          $(element).replaceWith(e)
        ), {
          tabSize: 2,
          lineNumbers: true,
          value: $(textarea).val()
        })
        editor.on('change', (args) ->
          $(textarea).val(editor.getValue())
          $(textarea).change().trigger("input")
        )
        codemirrors.push(editor)
      )
      codemirrors = codemirrors.filter((e) -> jQuery.contains(document, e.getWrapperElement()))
      for codemirror in codemirrors
        codemirror.refresh()
  ), 50), null, false)

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
    args = [ ]
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

  initializeDataStructure = (data_structure) ->
    if !data_structure.model_options?
      data_structure.model_options = { }
    switch data_structure.model.name
      when models[0]
        if !data_structure.model_options.fields?
          data_structure.model_options.fields = [ ]
      when models[1]
        undefined
    for operation in data_structure.operations
      operation.arguments = get_arguments(operation.code, operation.name)
    data_structure.startUpdate = debounce () ->
      $scope.$apply ($scope) ->
        sandbox(data_structure.operations, data_structure.model.api)
        for operation in data_structure.operations
          operation.arguments = get_arguments(operation.code, operation.name)

  for data_structure in $scope.data_structures
    initializeDataStructure(data_structure)

  unregisterList = []
  watchDataStructures = () ->
    if unregisterList.length > $scope.data_structures.length
      i = $scope.data_structures.length
      while i < unregisterList.length
        unregisterList[i]()
        i += 1
      unregisterList.splice($scope.data_structures.length, unregisterList.length - $scope.data_structures.length)
    if unregisterList.length < $scope.data_structures.length
      i = unregisterList.length
      while i < $scope.data_structures.length
        do (i) ->
          unregisterList.push($scope.$watch((($scope) ->
            return [
              $scope.data_structures[i].model,
              [
                op.name,
                op.code
              ] for op in $scope.data_structures[i].operations
            ]
          ), (() ->
            $scope.data_structures[i].startUpdate()
          ), true))
        i += 1
  watchDataStructures()

  # data structures

  $scope.newDataStructure = () ->
    data_structure = {
      name: '',
      operations: [ ],
      model: models[0],
      model_options: { }
    }
    initializeDataStructure(data_structure)
    $scope.data_structures.push(data_structure)
    $scope.editDataStructure(data_structure)
    watchDataStructures()

  $scope.deleteDataStructure = (data_structure) ->
    index = null
    for ds, i in $scope.data_structures
      if ds == data_structure
        index = i
        break
    if index?
      if active_data_structure == data_structure
        active_data_structure = null
      $scope.data_structures.splice(index, 1)
      if $scope.data_structures.length == 0
        $scope.editDataStructure(null)
      else
        $scope.editDataStructure($scope.data_structures[0])
      watchDataStructures()

  # fields

  $scope.new_field_name = null
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = (data_structure) ->
    if !$scope.new_field_name? or $scope.new_field_name == ''
      $scope.new_field_error = 'Please enter a name.'
      return
    if $scope.new_field_name in data_structure.model_options.fields
      $scope.new_field_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_field_name))
      $scope.new_field_error = 'Invalid name.'
      return
    data_structure.model_options.fields.push($scope.new_field_name)
    $scope.new_field_name = ''
    $scope.clearAddFieldError()

  $scope.moveFieldUp = (data_structure, field) ->
    index = null
    for name, i in data_structure.model_options.fields
      if name == field
        index = i
        break
    if index? and index > 0
      data_structure.model_options.fields.splice(index, 1)
      data_structure.model_options.fields.splice(index - 1, 0, field)

  $scope.moveFieldDown = (data_structure, field) ->
    index = null
    for name, i in data_structure.model_options.fields
      if name == field
        index = i
        break
    if index? and index < data_structure.model_options.fields.length - 1
      data_structure.model_options.fields.splice(index, 1)
      data_structure.model_options.fields.splice(index + 1, 0, field)

  $scope.deleteField = (data_structure, field) ->
    index = null
    for name, i in data_structure.model_options.fields
      if name == field
        index = i
        break
    if index?
      data_structure.model_options.fields.splice(index, 1)

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
  history_cursor = null

  $scope.resetState = () ->
    if $scope.active_data_structure?
      $scope.computationState = $scope.active_data_structure.model.getInitialState($scope.active_data_structure.model_options)
      $scope.computationModel = $scope.active_data_structure.model
      $scope.command_history = [ ]
    else
      $scope.computationState = null
      $scope.command_history = null
      $scope.computationModel = null
    $scope.command_history_cursor = null
    $scope.command_history_step_cursor = null
    history_cursor = null

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

    for operation in $scope.active_data_structure.operations
      if operation.error?
        $scope.new_command_error = operation.error.name + ' (' + operation.name + '): ' + operation.error.message
        return

    if $scope.haveCommandHistory() and $scope.computationModel != $scope.active_data_structure.model
      $scope.new_command_error = 'Reset the state or set the model of computation back to: ' + $scope.computationModel.name + '.'
      return
    if !$scope.haveCommandHistory()
      $scope.resetState()

    $scope.fastForward(true)
    result = runCommand($scope.computationState, $scope.new_command_str, $scope.active_data_structure.operations, $scope.active_data_structure.model.api)
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
    history_cursor = null
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

  $scope.commandKeyDown = (event) ->
    # up
    if event.keyCode == 38
      if $scope.haveCommandHistory()
        if history_cursor == null
          history_cursor = $scope.command_history.length
        if history_cursor > 0
          history_cursor -= 1
          $scope.new_command_str = $scope.command_history[history_cursor].str
          setTimeout((() ->
              $('#command')[0].setSelectionRange($scope.new_command_str.length, $scope.new_command_str.length)
            ), 1)
          event.preventDefault()
      else
        history_cursor = null

    # down
    if event.keyCode == 40
      if $scope.haveCommandHistory()
        if history_cursor == null
          history_cursor = $scope.command_history.length
        if history_cursor < $scope.command_history.length
          history_cursor += 1
          if history_cursor < $scope.command_history.length
            $scope.new_command_str = $scope.command_history[history_cursor].str
            setTimeout((() ->
                $('#command')[0].setSelectionRange($scope.new_command_str.length, $scope.new_command_str.length)
              ), 1)
            event.preventDefault()
          else
            $scope.new_command_str = ''
      else
        history_cursor = null

])
