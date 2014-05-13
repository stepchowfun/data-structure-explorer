graph = angular.module('graph', ['makeString'])

graph.factory('graph', ['makeString', ((makeString) ->
  return {
    set_root: (target, animate, done) ->
      console.log('set_root ' + makeString([target, animate]))
      if done?
        done()

    add_node: (id, data, animate, done) ->
      console.log('add_node ' + makeString([id, data, animate]))
      if done?
        done()

    remove_node: (id, animate, done) ->
      console.log('remove_node ' + makeString([id, animate]))
      if done?
        done()

    set_node_data: (id, data, animate, done) ->
      console.log('set_node_data ' + makeString([id, data, animate]))
      if done?
        done()

    add_edge: (source, target, label, animate, done) ->
      console.log('add_edge ' + makeString([source, target, label, animate]))
      if done?
        done()

    remove_edge: (source, target, animate, done) ->
      console.log('remove_edge ' + makeString([source, target, animate]))
      if done?
        done()
  }
)])
