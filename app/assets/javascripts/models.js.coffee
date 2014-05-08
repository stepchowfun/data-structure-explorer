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
      root: null,
      nodes: { },
      index: 0
    }
  ),
  api: {
    set_root: ((root) ->
      old_root = current_state.root
      step = {
        repr: 'set_root(' + JSON.stringify(root) + ')',
        up: ((state) ->
          state.root = root
        ),
        down: ((state) ->
          state.root = old_root
        ),
      }
      step.up(current_state)
      command_steps.push(step)
      undefined
    ),
    get_root: (() ->
      return current_state.root
    ),
    make_node: ((data) ->
      node = { }
      for field in current_state.fields
        node[field] = null
      if data?
        for key, value of data
          if key not in current_state.fields
            throw Error('Unknown field: ' + key + '.')
          node[key] = value
      name = 'n' + current_state.index.toString()
      step = {
        repr: 'make_node(' + JSON.stringify(data) + ')',
        up: ((state) ->
          state.index += 1
          state.nodes[name] = node
        ),
        down: ((state) ->
          state.nodes[name] = undefined
          state.index -= 1
        ),
      }
      step.up(current_state)
      command_steps.push(step)
      return name
    ),
    delete_node: ((node) ->
      if !current_state.nodes[node]?
        throw Error('Node ' + JSON.stringify(node) + ' does not exist.')
      old_node = current_state.nodes[node]
      step = {
        repr: 'delete_node(' + JSON.stringify(node) + ')',
        up: ((state) ->
          state.nodes[node] = undefined
        ),
        down: ((state) ->
          state.nodes[node] = old_node
        ),
      }
      step.up(current_state)
      command_steps.push(step)
      undefined
    ),
    set_field: ((node, field, value) ->
      if !current_state.nodes[node]?
        throw Error('Node ' + JSON.stringify(node) + ' does not exist.')
      if field not in current_state.fields
        throw Error('Field ' + JSON.stringify(field) + ' does not exist.')
      old_value = current_state.nodes[node][field]
      step = {
        repr: 'set_field(' + JSON.stringify(node) + ', ' + JSON.stringify(field) + ', ' + JSON.stringify(value) + ')',
        up: ((state) ->
          state.nodes[node][field] = value
        ),
        down: ((state) ->
          state.nodes[node][field] = old_value
        ),
      }
      step.up(current_state)
      command_steps.push(step)
      undefined
    ),
    get_field: ((node, field) ->
      if !current_state.nodes[node]?
        throw Error('Node ' + JSON.stringify(node) + ' does not exist.')
      if field not in current_state.fields
        throw Error('Field ' + JSON.stringify(field) + ' does not exist.')
      return current_state.nodes[node][field]
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
