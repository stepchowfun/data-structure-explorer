graph = angular.module('graph', ['makeString'])

graph.factory('graph', ['makeString', ((makeString) ->
  ANIMATION_DURATION = 200

  root = null
  node_data = [ ]
  edge_data = [ ]

  getWidth = () -> $('#graph').width()

  getHeight = () -> $('#graph').height()

  layoutBFS = () ->
    for node, i in node_data
      node.x = Math.random() * getWidth()
      node.y = Math.random() * getHeight()
    undefined

  selectNodes = () ->
    return d3.select('#graph').selectAll('circle').data(node_data, (d) -> d.id)

  render = () ->
    renderNodes = (selection) ->
      selection
        .attr('cx', (d) -> d.x)
        .attr('cy', (d) -> d.y)
        .attr('r', (d) -> d.r)

    nodes = selectNodes()
    renderNodes(nodes)
    renderNodes(nodes.enter().append('circle'))
    nodes.exit().remove()

  return {
    setRoot: (target, animate, done) ->
      root = target

      layoutBFS()

      render()

      console.log('setRoot ' + makeString([target, animate]))
      if done?
        done()

    addNode: (id, data, animate, done) ->
      node_data.push({
        id: id,
        data: data,
        x: 0,
        y: 0,
        r: 50
      })

      layoutBFS()

      render()

      console.log('addNode ' + makeString([id, data, animate]))
      if done?
        done()

    removeNode: (id, animate, done) ->
      for node, i in node_data
        if node.id == id
          node_data.splice(i, 1)
          break

      layoutBFS()

      render()

      console.log('removeNode ' + makeString([id, animate]))
      if done?
        done()

    setNodeData: (id, data, animate, done) ->
      for node, i in node_data
        if node.id == id
          node_data[i].data = data
          break

      layoutBFS()

      render()

      console.log('setNodeData ' + makeString([id, data, animate]))
      if done?
        done()

    addEdge: (source, target, label, animate, done) ->
      edge_data.push({
        source: source,
        target: target,
        label: label
      })

      layoutBFS()

      render()

      console.log('addEdge ' + makeString([source, target, label, animate]))
      if done?
        done()

    removeEdge: (source, target, animate, done) ->
      for edge, i in edge_data
        if edge.source == source and edge.target == target
          edge_data.splice(i, 1)
          break

      layoutBFS()

      render()

      console.log('removeEdge ' + makeString([source, target, animate]))
      if done?
        done()
  }
)])
