models = angular.module('models', [ ])

command_steps = [ ]
current_state = null

pointer_machine = {
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
    global: (() ->
      global = { }
      Object.defineProperty(global, 'root', {
        enumerable: true,
        get: (() ->
          if current_state?
            return current_state.root
        ),
        set: ((root) ->
          old_root = current_state.root
          step = {
            repr: 'global.root = ' + JSON.stringify(root) + '',
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
        )
      })
      return global
    )(),
    make_node: ((data) ->
      node = { }
      for field in current_state.fields
        node[field] = null
      if data?
        for key, value of data
          if key not in current_state.fields
            throw Error('Unknown field: ' + key + '.')
          node[key] = value
      node_name = 'n' + current_state.index.toString()
      step = {
        repr: 'make_node(' + JSON.stringify(data) + ')',
        up: ((state) ->
          state.index += 1
          state.nodes[node_name] = node
        ),
        down: ((state) ->
          state.nodes[node_name] = undefined
          state.index -= 1
        ),
      }
      step.up(current_state)
      command_steps.push(step)

      opaque_node = { }
      Object.defineProperty(opaque_node, 'toJSON', {
        value: () -> return node_name
      })
      Object.defineProperty(opaque_node, 'name', {
        value: node_name
      })
      for field in current_state.fields
        do (field) ->
          Object.defineProperty(opaque_node, field, {
            enumerable: true,
            get: (() ->
              if !current_state.nodes[node_name]?
                throw Error('Node ' + node_name + ' does not exist.')
              return current_state.nodes[node_name][field]
            ),
            set: ((value) ->
              if !current_state.nodes[node_name]?
                throw Error('Node ' + node_name + ' does not exist.')
              old_value = current_state.nodes[node_name][field]
              step = {
                repr: node_name + '.' + field + ' = ' + JSON.stringify(value),
                up: ((state) ->
                  state.nodes[node_name][field] = value
                ),
                down: ((state) ->
                  state.nodes[node_name][field] = old_value
                ),
              }
              step.up(current_state)
              command_steps.push(step)
              undefined
            )
          })
      return opaque_node
    ),
    delete_node: ((node) ->
      if !current_state.nodes[node.name]?
        throw Error('Node ' + JSON.stringify(node) + ' does not exist.')
      for n in current_state.nodes
        for f in current_state.fields
          if n[f] == node and n != node
            throw Error('Cannot delete node ' + JSON.stringify(node) + ' because node ' + JSON.stringify(n) + ' points to it.')
      if current_state.root == node
        throw Error('Cannot delete node ' + JSON.stringify(node) + ' because global.root points to it.')
      old_node = current_state.nodes[node.name]
      step = {
        repr: 'delete_node(' + JSON.stringify(node) + ')',
        up: ((state) ->
          state.nodes[node.name] = undefined
        ),
        down: ((state) ->
          state.nodes[node.name] = old_node
        ),
      }
      step.up(current_state)
      command_steps.push(step)
      undefined
    )
  }
}

bst = {
  constructor: (() ->),
  name: 'Binary search tree',
  getInitialState: ((options) ->
    return { }
  ),
  api: {
  }
}

runCommand = (state, command, operations) ->
  current_state = state
  command_steps = [ ]
  try
    context = { }
    for key, value of window
      context[key] = undefined
    context.command_steps = undefined
    context.current_state = undefined
    context.operations = undefined
    return_value = ((window) ->
      for api_fn_name, api_fn of pointer_machine.api
        context[api_fn_name] = api_fn
      for operation in operations
        context[operation.name] = operation.fn
      `with (context) {
        return eval(command);
      }`
      undefined
    ).call({ }, { })
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

models.value('pointer_machine', pointer_machine)
models.value('bst', bst)
models.value('models', [pointer_machine, bst])
models.value('runCommand', runCommand)
