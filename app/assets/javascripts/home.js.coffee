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
    editor.on('blur', (args) ->
      editor.setSelection({ line: 0, ch: 0 }, { line: 0, ch: 0 }, { scroll: false })
    )
    codemirrors.push(editor)
  )

# application module
cherries = angular.module('cherries', ['ngSanitize', 'models', 'examples', 'debounce', 'makeString', 'sandbox'])

# application controller
cherries.controller('CherriesController', ['$scope', 'models', 'runCommand', 'examples', 'debounce', 'makeString', 'sandbox', ($scope, models, runCommand, examples, debounce, makeString, sandbox) ->
  ############################################################################
  # global
  ############################################################################

  # reserved words in JavaScript
  JAVASCRIPT_KEYWORDS = ['break', 'case', 'catch', 'continue', 'debugger', 'default', 'delete', 'do', 'else', 'finally', 'for', 'function', 'if', 'in', 'instanceof', 'new', 'return', 'switch', 'this', 'throw', 'try', 'typeof', 'var', 'void', 'while', 'with']

  # models of computation
  $scope.models = models

  # list of data structures
  $scope.data_structures = examples

  # other global application state
  $scope.active_page = 0
  if $scope.data_structures.length > 0
    $scope.active_data_structure = $scope.data_structures[0]
  else
    $scope.active_data_structure = null
  $scope.field_to_delete = null
  $scope.operation_to_delete = null
  $scope.modal_title = null
  $scope.modal_message = null
  $scope.busy_semaphore = false

  # switch to a data structure
  $scope.activateDataStructure = (data_structure) ->
    $scope.active_data_structure = data_structure

  # focus the command prompt
  $scope.focusCommandPrompt = () ->
    setTimeout((() ->
      $('#new-command-str').focus()
    ), 1)

  # a helper to be called on click
  $scope.stopClick = (event) ->
    event.preventDefault()
    event.stopPropagation()

  # a helper that makes a string out of anything
  $scope.makeString = makeString

  # a helper for showing a message in a modal
  $scope.message = (title, message) ->
    $scope.modal_title = title
    $scope.modal_message = message
    $scope.busy_lock = true
    setTimeout((() ->
      $scope.$apply ($scope) ->
        $scope.busy_lock = false
      $('#message-modal').modal({ })
    ), 1)

  # a helper to scroll an item into view
  scrollIntoView = (container, element) ->
    original = $(container).scrollTop()
    element.scrollIntoView(false)
    bottom = $(container).scrollTop()
    $(container).scrollTop(original)
    element.scrollIntoView(true)
    top = $(container).scrollTop()
    if original < bottom
      original = bottom
    if original > top
      original = top
    $(container).scrollTop(original)

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
        editor.on('blur', (args) ->
          editor.setSelection({ line: 0, ch: 0 }, { line: 0, ch: 0 }, { scroll: false })
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

  getArguments = (code, function_name) ->
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
    switch data_structure.model
      when 'pointer_machine'
        if !data_structure.model_options.fields?
          data_structure.model_options.fields = [ ]
    for operation in data_structure.operations
      operation.arguments = getArguments(operation.code, operation.name)
    data_structure.startUpdate = debounce () ->
      $scope.$apply ($scope) ->
        sandbox(data_structure.operations, models[data_structure.model].api)
        for operation in data_structure.operations
          operation.arguments = getArguments(operation.code, operation.name)

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
              models[$scope.data_structures[i].model].name
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
      model: 'pointer_machine',
      model_options: { }
    }
    initializeDataStructure(data_structure)
    $scope.data_structures.push(data_structure)
    $scope.activateDataStructure(data_structure)
    $scope.active_page = 0
    watchDataStructures()

  $scope.deleteDataStructure = () ->
    index = null
    for ds, i in $scope.data_structures
      if ds == $scope.active_data_structure
        index = i
        break
    if index?
      $scope.active_data_structure = null
      $scope.data_structures.splice(index, 1)
      if $scope.data_structures.length == 0
        $scope.activateDataStructure(null)
      else
        $scope.activateDataStructure($scope.data_structures[0])
      watchDataStructures()

  # save to local storage
  $scope.save = () ->
    localStorage = window['localStorage']
    if localStorage?
      try
        localStorage.setItem('data_structures', JSON.stringify($scope.data_structures))
        $scope.message('Save successful', 'The data structures were saved successfully.')
      catch
        $scope.message('Uh oh', 'There was a problem saving to local storage.')
    else
      $scope.message('Uh oh', 'Your browser doesn&rsquo;t support local storage.')

  # load from local storage
  $scope.load = () ->
    if $scope.busy_lock
      $scope.message('Uh oh', 'The system is currently busy. Please try again later.')
    $scope.resetState () ->
      $scope.$apply ($scope) ->
      localStorage = window['localStorage']
      if localStorage?
        try
          ds = JSON.parse(localStorage.getItem('data_structures'))
          if !ds?
            $scope.message('Uh oh', 'There was a problem loading from local storage.')
            return
          $scope.data_structures = []
          $scope.activateDataStructure(null)
          watchDataStructures()
          $scope.busy_lock = true
          setTimeout((() ->
            $scope.$apply(($scope) ->
              $scope.busy_lock = false
              $scope.data_structures = ds
              if $scope.data_structures.length > 0
                $scope.activateDataStructure($scope.data_structures[0])
              else
                $scope.activateDataStructure(null)
              for data_structure in $scope.data_structures
                initializeDataStructure(data_structure)
              watchDataStructures()
              $scope.message('Load successful', 'The data structures were loaded successfully.')
            )
          ), 1)
        catch
          $scope.message('Uh oh', 'There was a problem loading from local storage.')
      else
        $scope.message('Uh oh', 'Your browser doesn&rsquo;t support local storage.')

  # fields

  $scope.new_field_name = null
  $scope.new_field_error = null

  $scope.clearAddFieldError = () ->
    $scope.new_field_error = null

  $scope.addField = () ->
    if !$scope.new_field_name? or $scope.new_field_name == ''
      $scope.new_field_error = Error('Please enter a name.')
      return
    if $scope.new_field_name in $scope.active_data_structure.model_options.fields
      $scope.new_field_error = Error('Already exists.')
      return
    if $scope.new_field_name in JAVASCRIPT_KEYWORDS
      $scope.new_field_error = Error('That is a JavaScript keyword.')
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_field_name))
      $scope.new_field_error = Error('Invalid name.')
      return
    $scope.active_data_structure.model_options.fields.push($scope.new_field_name)
    $scope.new_field_name = ''
    $scope.clearAddFieldError()

  $scope.moveFieldUp = (field) ->
    index = null
    for name, i in $scope.active_data_structure.model_options.fields
      if name == field
        index = i
        break
    if index? and index > 0
      $scope.active_data_structure.model_options.fields.splice(index, 1)
      $scope.active_data_structure.model_options.fields.splice(index - 1, 0, field)

  $scope.moveFieldDown = (field) ->
    index = null
    for name, i in $scope.active_data_structure.model_options.fields
      if name == field
        index = i
        break
    if index? and index < $scope.active_data_structure.model_options.fields.length - 1
      $scope.active_data_structure.model_options.fields.splice(index, 1)
      $scope.active_data_structure.model_options.fields.splice(index + 1, 0, field)

  $scope.prepareRenameField = (field) ->
    $scope.busy_lock = true
    setTimeout((() ->
      $scope.$apply ($scope) ->
        $scope.busy_lock = false
      element = $('#new-field-name-' + field)
      element.focus()
      element[0].setSelectionRange(0, element.val().length)
    ), 1)

  $scope.renameField = (field, new_field_name) ->
    if new_field_name == ''
      return
    for name, i in $scope.active_data_structure.model_options.fields
      if name == field
        $scope.active_data_structure.model_options.fields[i] = new_field_name
        break

  $scope.prepareDeleteField = (field) ->
    $scope.field_to_delete = field

  $scope.deleteField = (field) ->
    index = null
    for name, i in $scope.active_data_structure.model_options.fields
      if name == field
        index = i
        break
    if index?
      $scope.active_data_structure.model_options.fields.splice(index, 1)

  # operations

  $scope.new_operation_name = null
  $scope.new_operation_error = null

  $scope.clearAddOperationError = () ->
    $scope.new_operation_error = null

  $scope.addOperation = (data_structure) ->
    if !$scope.new_operation_name? or $scope.new_operation_name == ''
      $scope.new_operation_error = Error('Please enter a name.')
      return
    if $scope.new_operation_name in (operation.name for operation in data_structure.operations)
      $scope.new_operation_error = Error('Already exists.')
      return
    if $scope.new_operation_name in JAVASCRIPT_KEYWORDS
      $scope.new_operation_error = Error('That is a JavaScript keyword.')
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test($scope.new_operation_name))
      if '(' in $scope.new_operation_name
        $scope.new_operation_error = Error('Invalid name. Note: Do not include the argument list. It will be detected automatically.')
      else
        $scope.new_operation_error = Error('Invalid name.')
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

  $scope.prepareRenameOperation = (operation) ->
    $scope.busy_lock = true
    setTimeout((() ->
      $scope.$apply ($scope) ->
        $scope.busy_lock = false
      elements = $('.new-operation-name-' + operation.name)
      elements.focus()
      for e in elements
        e.setSelectionRange(0, $(e).val().length)
    ), 1)

  $scope.renameOperation = (operation, new_operation_name) ->
    if new_operation_name == ''
      return
    operation.name = new_operation_name

  $scope.prepareDeleteOperation = (operation) ->
    $scope.operation_to_delete = operation

  $scope.deleteOperation = (operation) ->
    index = null
    for op, i in $scope.active_data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index?
      $scope.active_data_structure.operations.splice(index, 1)

  ############################################################################
  # explorer
  ############################################################################

  $scope.new_command_str = null
  $scope.new_command_error = null
  $scope.computation_state = null
  $scope.computation_model = null
  $scope.computation_model_options = null
  $scope.command_history = [ ]
  $scope.command_history_cursor = null
  $scope.command_history_step_cursor = null
  input_history_cursor = null

  $scope.resetState = (done) ->
    if $scope.busy_lock
      throw Error('The system is busy.')
    newDone = () ->
      $scope.$apply ($scope) ->
        $scope.new_command_error = null
        if $scope.active_data_structure?
          $scope.computation_state = models[$scope.active_data_structure.model].getInitialState($scope.active_data_structure.model_options)
          $scope.computation_model = models[$scope.active_data_structure.model]
          $scope.computation_model_options = $scope.active_data_structure.model_options
          $scope.command_history = [ ]
        else
          $scope.computation_state = null
          $scope.computation_model = null
          $scope.computation_model_options = null
          $scope.command_history = [ ]
      if done?
        done()

    if $scope.command_history?
      $scope.fastBackward(false, false, newDone)
    else
      $scope.busy_lock = true
      setTimeout((() ->
        $scope.$apply ($scope) ->
          $scope.busy_lock = false
        newDone()
      ), 1)

  $scope.busy_lock = true
  setTimeout((() ->
    $scope.$apply ($scope) ->
      $scope.busy_lock = false
    $scope.resetState(null)
  ), 1)

  $scope.clearNewCommandError = () ->
    $scope.new_command_error = null

  $scope.newCommand = () ->
    if !$scope.active_data_structure?
      $scope.new_command_error = Error('Select a data structure first.')
      return

    if !$scope.new_command_str? or $scope.new_command_str == ''
      $scope.new_command_error = Error('Please enter a command.')
      return

    for operation in $scope.active_data_structure.operations
      if operation.error?
        $scope.new_command_error = operation.error
        return

    if $scope.computation_model != models[$scope.active_data_structure.model]
      if $scope.command_history.length == 0
        $scope.resetState(() ->
          $scope.$apply ($scope) ->
            $scope.newCommand()
        )
        return
      $scope.new_command_error = Error('Reset the state or set the model of computation back to: ' + $scope.computation_model.name + '.')
      return

    if !angular.equals($scope.computation_model_options, $scope.active_data_structure.model_options)
      if $scope.command_history.length == 0
        $scope.resetState(() ->
          $scope.$apply ($scope) ->
            $scope.newCommand()
        )
        return
      $scope.new_command_error = Error('The basic properties of the data structure have changed. Reset the computation to continue.')
      return

    $scope.fastForward(true, false, () ->
      $scope.$apply ($scope) ->
        result = runCommand($scope.computation_state, $scope.new_command_str, $scope.active_data_structure.operations, $scope.computation_model, $scope.computation_model_options)
        if result.error?
          $scope.new_command_error = result.error
          if $scope.new_command_error.stack_list?
            $scope.new_command_error.stack_list.pop()
          return
        command = {
          str: $scope.new_command_str,
          steps: result.steps,
          return_value: result.return_value
        }
        $scope.command_history.push(command)
        input_history_cursor = null
        $scope.new_command_str = ''
        $scope.clearNewCommandError()
        $scope.fastForward(true, true, () -> $('#new-command-str').focus())
    )

  $scope.stepBackward = (scroll, animate, done) ->
    if $scope.busy_lock
      throw Error('The system is busy.')
    if !$scope.canStepBackward()
      throw Error('Cannot step backward.')

    cursor = $scope.command_history_cursor
    step_cursor = $scope.command_history_step_cursor - 1
    while step_cursor == -1
      cursor -= 1
      if cursor == -1
        cursor = null
        step_cursor = null
        break
      step_cursor = $scope.command_history[cursor].steps.length - 1
    $scope.busy_lock = true
    $scope.command_history[$scope.command_history_cursor].steps[$scope.command_history_step_cursor].down($scope.computation_state, animate, () ->
      setTimeout((() ->
        $scope.$apply ($scope) ->
          $scope.busy_lock = false
        if scroll
          if $scope.command_history_cursor? and $scope.command_history_step_cursor?
            elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
            if elements.length > 0
              scrollIntoView($('#command-history')[0], elements[0])
          else
            scrollIntoView($('#command-history')[0], $('#empty')[0])
        if done?
          done()
      ), 1)
    )
    $scope.command_history_cursor = cursor
    $scope.command_history_step_cursor = step_cursor

  $scope.stepForward = (scroll, animate, done) ->
    if $scope.busy_lock
      throw Error('The system is busy.')
    if !$scope.canStepForward()
      throw Error('Cannot step forward.')

    if $scope.command_history_cursor?
      cursor = $scope.command_history_cursor
      step_cursor = $scope.command_history_step_cursor + 1
    else
      cursor = 0
      step_cursor = 0
    while step_cursor == $scope.command_history[cursor].steps.length
      cursor += 1
      step_cursor = 0
    $scope.command_history_cursor = cursor
    $scope.command_history_step_cursor = step_cursor
    $scope.busy_lock = true
    $scope.command_history[cursor].steps[step_cursor].up($scope.computation_state, animate, () ->
      setTimeout((() ->
        $scope.$apply ($scope) ->
          $scope.busy_lock = false
        if scroll
          elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
          scrollIntoView($('#command-history')[0], elements[0])
        if done?
          done()
      ), 1)
    )

  $scope.fastBackward = (scroll, animate, done) ->
    if $scope.busy_lock
      throw Error('The system is busy.')
    $scope.jumpTo(null, null, scroll, animate, done)

  $scope.fastForward = (scroll, animate, done) ->
    if $scope.busy_lock
      throw Error('The system is busy.')
    last_cursor = null
    last_step_cursor = null
    for command, i in $scope.command_history
      for step, j in command.steps
        last_cursor = i
        last_step_cursor = j
    $scope.jumpTo(last_cursor, last_step_cursor, false, animate, () ->
      $("#command-history").scrollTop($("#command-history")[0].scrollHeight)
      if done?
        done()
    )

  $scope.canStepBackward = () ->
    if $scope.command_history? and $scope.command_history.length > 0
      return $scope.command_history_cursor != null
    return false

  $scope.canStepForward = () ->
    if $scope.command_history? and $scope.command_history.length > 0
      last_cursor = null
      last_step_cursor = null
      for command, i in $scope.command_history
        for step, j in command.steps
          last_cursor = i
          last_step_cursor = j
      if !last_cursor?
        return false
      if !$scope.command_history_cursor?
        return true
      if $scope.command_history_cursor < last_cursor
        return true
      if $scope.command_history_cursor == last_cursor and $scope.command_history_step_cursor < last_step_cursor
        return true
    return false

  $scope.canReset = () ->
    return $scope.command_history.length > 0

  $scope.jumpTo = (cursor, step_cursor, scroll, animate, done) ->
    if $scope.command_history_cursor?
      if cursor?
        if $scope.command_history_cursor < cursor or ($scope.command_history_cursor == cursor and $scope.command_history_step_cursor < step_cursor)
          $scope.stepForward(scroll and animate, animate, () ->
            $scope.$apply ($scope) ->
              $scope.jumpTo(cursor, step_cursor, scroll, animate, done)
          )
          return
        if $scope.command_history_cursor > cursor or ($scope.command_history_cursor == cursor and $scope.command_history_step_cursor > step_cursor)
          $scope.stepBackward(scroll and animate, animate, () ->
            $scope.$apply ($scope) ->
              $scope.jumpTo(cursor, step_cursor, scroll, animate, done)
          )
          return
      else
        $scope.stepBackward(scroll and animate, animate, () ->
          $scope.$apply ($scope) ->
            $scope.jumpTo(cursor, step_cursor, scroll, animate, done)
        )
        return
    else
      if cursor?
        $scope.stepForward(scroll and animate, animate, () ->
          $scope.$apply ($scope) ->
            $scope.jumpTo(cursor, step_cursor, scroll, animate, done)
        )
        return

    $scope.busy_lock = true
    setTimeout((() ->
      $scope.$apply ($scope) ->
        $scope.busy_lock = false
      if scroll and !animate
        if $scope.command_history_cursor? and $scope.command_history_step_cursor?
          elements = $('#step-' + $scope.command_history_cursor.toString() + '-' + $scope.command_history_step_cursor.toString())
          scrollIntoView($('#command-history')[0], elements[0])
        else
          scrollIntoView($('#command-history')[0], $('#empty')[0])
      if done?
        done()
    ), 1)

  $scope.commandKeyDown = (event) ->
    if $('#new-command-str').attr('disabled')?
      return

    # up
    if event.keyCode == 38
      if $scope.command_history.length > 0
        if input_history_cursor == null
          input_history_cursor = $scope.command_history.length
        if input_history_cursor > 0
          input_history_cursor -= 1
          $scope.new_command_str = $scope.command_history[input_history_cursor].str
          $scope.busy_lock = true
          setTimeout((() ->
            $scope.$apply ($scope) ->
              $scope.busy_lock = false
            $('#new-command-str')[0].setSelectionRange($scope.new_command_str.length, $scope.new_command_str.length)
          ), 1)
          event.preventDefault()
      else
        input_history_cursor = null

    # down
    if event.keyCode == 40
      if $scope.command_history.length > 0
        if input_history_cursor == null
          input_history_cursor = $scope.command_history.length
        if input_history_cursor < $scope.command_history.length
          input_history_cursor += 1
          if input_history_cursor < $scope.command_history.length
            $scope.new_command_str = $scope.command_history[input_history_cursor].str
            $scope.busy_lock = true
            setTimeout((() ->
              $scope.$apply ($scope) ->
                $scope.busy_lock = false
              $('#new-command-str')[0].setSelectionRange($scope.new_command_str.length, $scope.new_command_str.length)
            ), 1)
            event.preventDefault()
          else
            $scope.new_command_str = ''
      else
        input_history_cursor = null
])
