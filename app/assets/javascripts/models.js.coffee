models = angular.module('models', ['sandbox', 'makeString', 'getField', 'graph'])

command_steps = [ ]
current_state = null
current_model_options = null
disable_rendering = false

models.factory('models', ['makeString', 'getField', 'graph', (makeString, getField, graph) ->
  get_transparent_node = (state, opaque_node) ->
    if !opaque_node? or !getField(opaque_node, 'name')?
      return null
    if !state.transparent_nodes[opaque_node.name]?
      return null
    return state.transparent_nodes[opaque_node.name]

  machines_array = [
    {
      name: 'Pointer machine',
      machine_name: 'pointer_machine',
      getInitialState: (() ->
        return {
          opaque_root: null,
          transparent_nodes: { },
          name_accumulator: 0
        }
      ),
      api: {
        global: (() ->
          global = { }
          Object.defineProperty(global, 'root', {
            enumerable: true,
            get: (() ->
              return getField(current_state, 'opaque_root')
            ),
            set: ((opaque_root) ->
              old_opaque_root = current_state.opaque_root
              if opaque_root != null and !get_transparent_node(current_state, opaque_root)
                throw Error(makeString(opaque_root) + ' is not a node.')
              step = {
                repr: 'global.root = ' + makeString(opaque_root) + '',
                up: ((state, animate, done) ->
                  current_state.opaque_root = opaque_root
                  if disable_rendering
                    if done?
                      done()
                  else
                    if opaque_root?
                      graph.set_root(opaque_root.name, animate, done)
                    else
                      graph.set_root(null, animate, done)
                ),
                down: ((state, animate, done) ->
                  current_state.opaque_root = old_opaque_root
                  if disable_rendering
                    if done?
                      done()
                  else
                    if old_opaque_root?
                      graph.set_root(old_opaque_root.name, animate, done)
                    else
                      graph.set_root(null, animate, done)
                ),
              }
              command_steps.push(step)
              step.up(current_state, false, null)
              undefined
            )
          })
          return global
        )(),
        make_node: ((data) ->
          transparent_node = { }
          for field in current_model_options.fields
            transparent_node[field] = null
          if data?
            for key, value of data
              if key not in current_model_options.fields
                throw Error('Unknown field: ' + key + '.')
              transparent_node[key] = value
          node_name = 'n' + current_state.name_accumulator.toString()
          original_graph_node_data = { }
          original_graph_link_data = [ ]
          for key, value of transparent_node
            if get_transparent_node(current_state, value)?
              original_graph_link_data.push([node_name, value.name, key])
            else
              original_graph_node_data[key] = value
          step = {
            repr: node_name + ' = make_node(' + makeString(data) + ')',
            up: ((state, animate, done) ->
              state.name_accumulator += 1
              state.transparent_nodes[node_name] = transparent_node
              if disable_rendering
                if done?
                  done()
              else
                process_graph_link_data = (remaining_graph_link_data) ->
                  if remaining_graph_link_data.length > 0
                    graph.add_edge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], remaining_graph_link_data[0][2], animate, () ->
                      process_graph_link_data(remaining_graph_link_data.slice(1))
                    )
                  else
                    if done?
                      done()
                graph.add_node(node_name, original_graph_node_data, animate, () ->
                  process_graph_link_data(original_graph_link_data)
                )
            ),
            down: ((state, animate, done) ->
              state.transparent_nodes[node_name] = undefined
              state.name_accumulator -= 1
              if disable_rendering
                if done?
                  done()
              else
                process_graph_link_data = (remaining_graph_link_data) ->
                  if remaining_graph_link_data.length > 0
                    graph.remove_edge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], animate, () ->
                      process_graph_link_data(remaining_graph_link_data.slice(1))
                    )
                  else
                    graph.remove_node(node_name, animate, () ->
                      if done?
                        done()
                    )
                process_graph_link_data(original_graph_link_data)
            )
          }
          command_steps.push(step)
          step.up(current_state, false, null)

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
                  if !get_transparent_node(current_state, opaque_node)?
                    throw Error('Node ' + node_name + ' does not exist.')
                  return current_state.transparent_nodes[node_name][field]
                ),
                set: ((value) ->
                  if !get_transparent_node(current_state, opaque_node)?
                    throw Error('Node ' + node_name + ' does not exist.')
                  old_value = transparent_node[field]
                  old_graph_node_data = { }
                  for k, v of transparent_node
                    if !get_transparent_node(current_state, v)?
                      old_graph_node_data[k] = v
                  step = {
                    repr: node_name + '.' + field + ' = ' + makeString(value),
                    up: ((state, animate, done) ->
                      transparent_node[field] = value
                      if disable_rendering
                        if done?
                          done()
                      else
                        old_target = get_transparent_node(state, old_value)
                        new_target = get_transparent_node(state, value)

                        add_new_edge = () ->
                          if new_target?
                            graph.add_edge(node_name, value.name, field, animate, done)
                          else
                            if done?
                              done()

                        update_node_data = () ->
                          if !old_target? or !new_target?
                            new_graph_node_data = { }
                            for k, v of transparent_node
                              if !get_transparent_node(state, v)?
                                new_graph_node_data[k] = v
                            graph.set_node_data(node_name, new_graph_node_data, animate, add_new_edge)
                          else
                            add_new_edge()

                        remove_old_edge = () ->
                          if old_target?
                            graph.remove_edge(node_name, old_value.name, animate, update_node_data)
                          else
                            update_node_data()

                        remove_old_edge()
                    ),
                    down: ((state, animate, done) ->
                      transparent_node[field] = old_value
                      if disable_rendering
                        if done?
                          done()
                      else
                        old_target = get_transparent_node(state, old_value)
                        new_target = get_transparent_node(state, value)

                        add_old_edge = () ->
                          if new_target?
                            graph.add_edge(node_name, old_value.name, field, animate, done)
                          else
                            if done?
                              done()

                        update_node_data = () ->
                          if !old_target? or !new_target?
                            graph.set_node_data(node_name, old_graph_node_data, animate, add_old_edge)
                          else
                            add_old_edge()

                        remove_new_edge = () ->
                          if new_target?
                            graph.remove_edge(node_name, value.name, animate, update_node_data)
                          else
                            update_node_data()

                        remove_new_edge()
                    ),
                  }
                  step.up(current_state, false, null)
                  command_steps.push(step)
                  undefined
                )
              })
          Object.defineProperty(opaque_node, 'remove', {
            enumerable: true,
            value: (() ->
              if !get_transparent_node(current_state, opaque_node)?
                throw Error('Node ' + node_name + ' does not exist.')
              for k, v of current_state.transparent_nodes
                if v != transparent_node
                  for f in current_model_options.fields
                    if getField(getField(v, f), 'name') == opaque_node.name
                      throw Error('Cannot delete node ' + opaque_node.name + ' because node ' + k + ' points to it.')
              if getField(current_state.opaque_root, 'name') == opaque_node.name
                throw Error('Cannot delete node ' + opaque_node.name + ' because global.root points to it.')
              step = {
                repr: 'delete_node(' + makeString(opaque_node) + ')',
                up: ((state, animate, done) ->
                  state.transparent_nodes[opaque_node.name] = undefined
                  if disable_rendering
                    if done?
                      done()
                  else
                    graph.remove_node(opaque_node.name, animate, done)
                ),
                down: ((state, animate, done) ->
                  state.transparent_nodes[opaque_node.name] = transparent_node
                  if disable_rendering
                    if done?
                      done()
                  else
                    graph_node_data = { }
                    for k, v of transparent_node
                      if !get_transparent_node(state, v)?
                        graph_node_data[k] = v
                    graph.add_node(opaque_node.name, graph_node_data, animate, done)
                )
              }
              command_steps.push(step)
              step.up(current_state, false, null)
              undefined
            )
          })
          Object.freeze(opaque_node)
          return opaque_node
        )
      }
    }
  ]
  machines_object = { }
  for machine in machines_array
    machines_object[machine.machine_name] = machine
  return machines_object
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
    disable_rendering = true
    sandbox([fragment], definitions)
    command_steps.reverse()
    for command in command_steps
      command.down(current_state, false, null)
    command_steps.reverse()
    disable_rendering = false
    if fragment.error?
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
