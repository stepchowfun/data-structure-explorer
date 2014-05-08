models = angular.module('models', [])

command_steps = []
current_state = null

runCommand = (state, command, operations) ->
  current_state = state
  command_steps = []
  try
    return_value = (() ->
      context = { }
      context.command_steps = undefined;
      for api_fn_name, api_fn of pointer_machine.prototype.api
        context[api_fn_name] = api_fn
      for operation in operations
        context[operation.name] = operation.fn
      `with (context) {
        return eval(command);
      }`
      undefined
    )()
    return {
      steps: command_steps,
      return_value: return_value,
      error: null
    }
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
    command_steps.reverse()
    for command in command_steps
      command.down(current_state)
    return {
      steps: null,
      return_value: null,
      error: error
    }
  undefined

models.value('runCommand', runCommand)

class pointer_machine
  constructor: (() ->),
  name: 'Pointer machine',
  getInitialState: ((options) ->
    return {
      fields: options.fields,
      root: null
    }
  ),
  api: {
    set_root: ((root) ->
      old_root = current_state.root
      current_state.root = root
      command_steps.push({
        repr: 'set_root(' + JSON.stringify(root) + ')',
        up: ((state) ->
          state.root = root
        ),
        down: ((state) ->
          state.root = old_root
        ),
      })
      undefined
    ),
    get_root: (() ->
      return current_state.root
    )
  }

class bst
  constructor: (() ->),
  name: 'Binary search tree',
  getInitialState: ((options) ->
    return { }
  ),
  api: {
  }

models.value('models', [
  new pointer_machine(),
  new bst(),
])
