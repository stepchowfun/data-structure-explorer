models = angular.module('models', [ ])

command_steps = [ ]
current_state = null
current_model_options = null

models.factory('models', ['makeString', (makeString) ->
  return [
    {
      constructor: (() ->),
      name: 'Pointer machine',
      getInitialState: (() ->
        return {
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
                repr: 'global.root = ' + makeString(root) + '',
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
          for field in current_model_options.fields
            node[field] = null
          if data?
            for key, value of data
              if key not in current_model_options.fields
                throw Error('Unknown field: ' + key + '.')
              node[key] = value
          node_name = 'n' + current_state.index.toString()
          step = {
            repr: node_name + ' = make_node(' + makeString(data) + ')',
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
          Object.defineProperty(opaque_node, 'toString', {
            value: () -> return node_name
          })
          Object.defineProperty(opaque_node, 'name', {
            value: node_name
          })
          for field in current_model_options.fields
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
                    repr: node_name + '.' + field + ' = ' + makeString(value),
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
          if !node? or !node.name?
            throw Error(makeString(node) + ' is not a node.')
          if !current_state.nodes[node.name]?
            throw Error('Node ' + makeString(node) + ' does not exist.')
          for k, v of current_state.nodes
            for f in current_model_options.fields
              if v? and v[f]? and v[f].name? and v[f].name == node.name and k != node.name
                throw Error('Cannot delete node ' + node.name + ' because node ' + k + ' points to it.')
          if current_state.root == node
            throw Error('Cannot delete node ' + node.name + ' because global.root points to it.')
          old_node = current_state.nodes[node.name]
          step = {
            repr: 'delete_node(' + makeString(node) + ')',
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
  ]
])

models.factory('runCommand', ['sandbox', (sandbox) ->
  return (state, command, operations, model, model_options) ->
    command_steps = [ ]
    current_state = state
    current_model_options = model_options
    fragment = {
      code: command
    }
    definitions = { }
    for name, fn of model.api
      definitions[name] = fn
    for operation in operations
      definitions[operation.name] = operation.compiled_value
    sandbox([fragment], definitions)
    if fragment.error?
      command_steps.reverse()
      for command in command_steps
        command.down(current_state)
      return {
        steps: null,
        return_value: null,
        error: fragment.error
      }
    return {
      steps: command_steps,
      return_value: fragment.compiled_value,
      error: null
    }
])
