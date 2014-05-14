pointer_machine = angular.module('pointer_machine', ['makeString', 'getField', 'graph', 'models'])

pointer_machine.factory('pointer_machine', ['makeString', 'getField', 'graph', 'getCurrentState', 'getCommandSteps', 'getModelOptions', 'renderingDisabled', (makeString, getField, graph, getCurrentState, getCommandSteps, getModelOptions, renderingDisabled) ->
  getTransparentNode = (state, opaque_node) ->
    if !opaque_node? or !getField(opaque_node, 'name')?
      return null
    if !state.transparent_nodes[opaque_node.name]?
      return null
    return state.transparent_nodes[opaque_node.name]

  return {
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
            return getField(getCurrentState(), 'opaque_root')
          ),
          set: ((opaque_root) ->
            old_opaque_root = getCurrentState().opaque_root
            if opaque_root != null and !getTransparentNode(getCurrentState(), opaque_root)
              throw Error(makeString(opaque_root) + ' is not a node.')
            step = {
              repr: 'global.root = ' + makeString(opaque_root) + '',
              up: ((state, animate, done) ->
                getCurrentState().opaque_root = opaque_root
                if renderingDisabled()
                  if done?
                    done()
                else
                  if opaque_root?
                    graph.setRoot(opaque_root.name, animate, done)
                  else
                    graph.setRoot(null, animate, done)
              ),
              down: ((state, animate, done) ->
                getCurrentState().opaque_root = old_opaque_root
                if renderingDisabled()
                  if done?
                    done()
                else
                  if old_opaque_root?
                    graph.setRoot(old_opaque_root.name, animate, done)
                  else
                    graph.setRoot(null, animate, done)
              ),
            }
            getCommandSteps().push(step)
            step.up(getCurrentState(), false, null)
            undefined
          )
        })
        return global
      )(),
      make_node: ((data) ->
        transparent_node = { }
        for field in getModelOptions().fields
          transparent_node[field] = null
        if data?
          for key, value of data
            if key not in getModelOptions().fields
              throw Error('Unknown field: ' + key + '.')
            transparent_node[key] = value
        node_name = 'n' + getCurrentState().name_accumulator.toString()
        original_graph_node_data = { }
        original_graph_link_data = [ ]
        for key, value of transparent_node
          if getTransparentNode(getCurrentState(), value)?
            original_graph_link_data.push([node_name, value.name, key])
          else
            if value?
              original_graph_node_data[key] = value
        step = {
          repr: node_name + ' = make_node(' + makeString(data) + ')',
          up: ((state, animate, done) ->
            state.name_accumulator += 1
            state.transparent_nodes[node_name] = transparent_node
            if renderingDisabled()
              if done?
                done()
            else
              process_graph_link_data = (remaining_graph_link_data) ->
                if remaining_graph_link_data.length > 0
                  graph.addEdge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], remaining_graph_link_data[0][2], animate, () ->
                    process_graph_link_data(remaining_graph_link_data.slice(1))
                  )
                else
                  if done?
                    done()
              graph.addNode(node_name, original_graph_node_data, animate, () ->
                process_graph_link_data(original_graph_link_data)
              )
          ),
          down: ((state, animate, done) ->
            state.transparent_nodes[node_name] = undefined
            state.name_accumulator -= 1
            if renderingDisabled()
              if done?
                done()
            else
              process_graph_link_data = (remaining_graph_link_data) ->
                if remaining_graph_link_data.length > 0
                  graph.removeEdge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], remaining_graph_link_data[0][2], animate, () ->
                    process_graph_link_data(remaining_graph_link_data.slice(1))
                  )
                else
                  graph.removeNode(node_name, animate, () ->
                    if done?
                      done()
                  )
              process_graph_link_data(original_graph_link_data)
          )
        }
        getCommandSteps().push(step)
        step.up(getCurrentState(), false, null)

        opaque_node = { }
        Object.defineProperty(opaque_node, 'toString', {
          value: () -> return node_name
        })
        Object.defineProperty(opaque_node, 'name', {
          value: node_name
        })
        for field in getModelOptions().fields
          do (field) ->
            Object.defineProperty(opaque_node, field, {
              enumerable: true,
              get: (() ->
                if !getTransparentNode(getCurrentState(), opaque_node)?
                  throw Error('Node ' + node_name + ' does not exist.')
                return getCurrentState().transparent_nodes[node_name][field]
              ),
              set: ((value) ->
                if !getTransparentNode(getCurrentState(), opaque_node)?
                  throw Error('Node ' + node_name + ' does not exist.')
                old_value = transparent_node[field]
                old_graph_node_data = { }
                for k, v of transparent_node
                  if !getTransparentNode(getCurrentState(), v)?
                    if v?
                      old_graph_node_data[k] = v
                new_graph_node_data = { }
                for k, v of transparent_node
                  if k == field
                    if !getTransparentNode(getCurrentState(), value)?
                      if value?
                        new_graph_node_data[k] = value
                  else
                    if !getTransparentNode(getCurrentState(), v)?
                      if v?
                        new_graph_node_data[k] = v
                step = {
                  repr: node_name + '.' + field + ' = ' + makeString(value),
                  up: ((state, animate, done) ->
                    transparent_node[field] = value
                    if renderingDisabled()
                      if done?
                        done()
                    else
                      old_target = getTransparentNode(state, old_value)
                      new_target = getTransparentNode(state, value)

                      addNewEdge = () ->
                        if new_target?
                          graph.addEdge(node_name, value.name, field, animate, done)
                        else
                          if done?
                            done()

                      updateNodeData = () ->
                        if !old_target? or !new_target?
                          if angular.equals(old_graph_node_data, new_graph_node_data)
                            addNewEdge()
                          else
                            graph.setNodeData(node_name, new_graph_node_data, animate, addNewEdge)
                        else
                          addNewEdge()

                      removeOldEdge = () ->
                        if old_target?
                          graph.removeEdge(node_name, old_value.name, field, animate, updateNodeData)
                        else
                          updateNodeData()

                      removeOldEdge()
                  ),
                  down: ((state, animate, done) ->
                    transparent_node[field] = old_value
                    if renderingDisabled()
                      if done?
                        done()
                    else
                      old_target = getTransparentNode(state, old_value)
                      new_target = getTransparentNode(state, value)

                      addOldEdge = () ->
                        if old_target?
                          graph.addEdge(node_name, old_value.name, field, animate, done)
                        else
                          if done?
                            done()

                      updateNodeData = () ->
                        if !old_target? or !new_target?
                          if angular.equals(old_graph_node_data, new_graph_node_data)
                            addOldEdge()
                          else
                            graph.setNodeData(node_name, old_graph_node_data, animate, addOldEdge)
                        else
                          addOldEdge()

                      removeNewEdge = () ->
                        if new_target?
                          graph.removeEdge(node_name, value.name, field, animate, updateNodeData)
                        else
                          updateNodeData()

                      removeNewEdge()
                  ),
                }
                step.up(getCurrentState(), false, null)
                getCommandSteps().push(step)
                undefined
              )
            })
        Object.defineProperty(opaque_node, 'remove', {
          enumerable: true,
          value: (() ->
            if !getTransparentNode(getCurrentState(), opaque_node)?
              throw Error('Node ' + node_name + ' does not exist.')
            for k, v of getCurrentState().transparent_nodes
              if v != transparent_node
                for f in getModelOptions().fields
                  if getField(getField(v, f), 'name') == node_name
                    throw Error('Cannot delete node ' + node_name + ' because node ' + k + ' points to it.')
            if getField(getCurrentState().opaque_root, 'name') == node_name
              throw Error('Cannot delete node ' + node_name + ' because global.root points to it.')
            old_graph_node_data = { }
            old_graph_link_data = [ ]
            for key, value of transparent_node
              if getTransparentNode(getCurrentState(), value)?
                old_graph_link_data.push([node_name, value.name, key])
              else
                if value?
                  old_graph_node_data[key] = value
            step = {
              repr: makeString(opaque_node) + '.remove()',
              up: ((state, animate, done) ->
                state.transparent_nodes[node_name] = undefined
                if renderingDisabled()
                  if done?
                    done()
                else
                  process_graph_link_data = (remaining_graph_link_data) ->
                    if remaining_graph_link_data.length > 0
                      graph.removeEdge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], remaining_graph_link_data[0][2], animate, () ->
                        process_graph_link_data(remaining_graph_link_data.slice(1))
                      )
                    else
                      graph.removeNode(node_name, animate, done)
                  process_graph_link_data(old_graph_link_data)
              ),
              down: ((state, animate, done) ->
                state.transparent_nodes[node_name] = transparent_node
                if renderingDisabled()
                  if done?
                    done()
                else
                  process_graph_link_data = (remaining_graph_link_data) ->
                    if remaining_graph_link_data.length > 0
                      graph.addEdge(remaining_graph_link_data[0][0], remaining_graph_link_data[0][1], remaining_graph_link_data[0][2], animate, () ->
                        process_graph_link_data(remaining_graph_link_data.slice(1))
                      )
                    else
                      if done?
                        done()
                  graph.addNode(node_name, old_graph_node_data, animate, () ->
                    process_graph_link_data(old_graph_link_data)
                  )
              )
            }
            getCommandSteps().push(step)
            step.up(getCurrentState(), false, null)
            undefined
          )
        })
        Object.freeze(opaque_node)
        return opaque_node
      )
    }
  }
])
