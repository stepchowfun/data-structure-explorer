graph = angular.module('graph', ['makeString'])

graph.factory('graph', ['makeString', ((makeString) ->
  ANIMATION_DURATION = 300

  root = null
  node_data = [ ]
  edge_data = [ ]

  getWidth = () -> $('#graph').width()

  getHeight = () -> $('#graph').height()

  layoutBFS = () ->
    for node in node_data
      node.x = Math.random() * getWidth()
      node.y = Math.random() * getHeight()
    undefined

  selectNodes = () ->
    return d3.select('#graph').selectAll('circle').data(node_data, (d) -> d.id)

  render = (animate) ->
    selection = selectNodes()
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection
      .attr('cx', (d) -> d.x)
      .attr('cy', (d) -> d.y)
      .attr('r', (d) -> d.r)

  return {
    setRoot: (target, animate, done) ->
      console.log('setRoot ' + makeString([target, animate]))

      root = target

      layoutBFS()
      render(true)
      setTimeout((() ->
        if done?
          done()
      ), ANIMATION_DURATION)

    addNode: (id, data, animate, done) ->
      console.log('addNode ' + makeString([id, data, animate]))

      node_data.push({
        id: id,
        data: data,
        x: Math.random() * getWidth(),
        y: Math.random() * getHeight(),
        r: 50
      })

      selection = selectNodes().enter().append('circle')
      render()
      selection.attr('r', 0)
      selection.transition().duration(ANIMATION_DURATION).attr('r', (d) -> d.r)

      setTimeout((() ->
        layoutBFS()
        render(true)
        setTimeout((() ->
          if done?
            done()
        ), ANIMATION_DURATION)
      ), ANIMATION_DURATION)

    removeNode: (id, animate, done) ->
      console.log('removeNode ' + makeString([id, animate]))

      for node, i in node_data
        if node.id == id
          node_data.splice(i, 1)
          break

      selection = selectNodes().exit()
      selection.transition().duration(ANIMATION_DURATION).attr('r', 0)

      setTimeout((() ->
        selection.remove()
        layoutBFS()
        render(true)
        setTimeout((() ->
          if done?
            done()
        ), ANIMATION_DURATION)
      ), ANIMATION_DURATION)

    setNodeData: (id, data, animate, done) ->
      console.log('setNodeData ' + makeString([id, data, animate]))

      for node, i in node_data
        if node.id == id
          node_data[i].data = data
          break

      #

      if done?
        done()

    addEdge: (source, target, label, animate, done) ->
      console.log('addEdge ' + makeString([source, target, label, animate]))

      edge_data.push({
        source: source,
        target: target,
        label: label
      })

      #

      if done?
        done()

    removeEdge: (source, target, animate, done) ->
      console.log('removeEdge ' + makeString([source, target, animate]))
      
      for edge, i in edge_data
        if edge.source == source and edge.target == target
          edge_data.splice(i, 1)
          break

      #

      if done?
        done()
  }
)])
