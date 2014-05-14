graph = angular.module('graph', ['makeString'])

graph.factory('graph', ['makeString', ((makeString) ->
  ANIMATION_DURATION = 300

  root_id = null
  node_data = [ ]
  edge_data = [ ]

  getWidth = () -> $('#graph').width()

  getHeight = () -> $('#graph').height()

  selectNodes = () ->
    return d3.select('#graph').selectAll('circle').data(node_data, (d) -> d.id)

  selectEdges = () ->
    return d3.select('#graph').selectAll('line').data(edge_data, (d) -> String(d.source) + ':' + String(d.target) + ':' + d.label)

  getNode = (id) ->
    for node in node_data
      if node.id == id
        return node
    return null

  getEdge = (source, target, label) ->
    for edge in edge_data
      if edge.source == source and edge.target == target and edge.label == label
        return edge
    return null

  getEdges = (source, target) ->
    edges = [ ]
    for edge in edge_data
      if edge.source == source and edge.target == target
        edges.push(edge)
    return edges

  getAdjacent = (node) ->
    adjacent = [ ]
    for edge in edge_data
      if edge.source == node.id
        target_node = getNode(edge.target)
        if !(target_node in adjacent)
          adjacent.push(target_node)
      if edge.target == node.id
        source_node = getNode(edge.source)
        if !(source_node in adjacent)
          adjacent.push(source_node)
    return adjacent


  layoutBFS = () ->
    node_data.sort(
      (a, b) ->
        if a.id < b.id
          return -1
        else if a.id > b.id
          return 1
        return 0
    )

    visited = { }
    frontier = { }


    for node in node_data
      node.x = Math.random() * getWidth()
      node.y = Math.random() * getHeight()

    undefined

  render = (animate) ->
    selection = selectNodes()
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection
      .attr('cx', (d) -> d.x)
      .attr('cy', (d) -> d.y)
      .attr('r', (d) -> d.r)

    selection = selectEdges()
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection
      .attr('x1', (d) -> getNode(d.source).x)
      .attr('y1', (d) -> getNode(d.source).y)
      .attr('x2', (d) -> getNode(d.target).x)
      .attr('y2', (d) -> getNode(d.target).y)

  return {
    setRoot: (target, animate, done) ->
      console.log('setRoot ' + makeString([target, animate]))

      root_id = target

      layoutBFS()
      render(true)
      setTimeout((() ->
        if done?
          done()
      ), ANIMATION_DURATION)

    addNode: (id, data, animate, done) ->
      console.log('addNode ' + makeString([id, data, animate]))

      node = {
        id: id,
        data: data,
        x: 50,
        y: 50,
        r: 50
      }
      node_data.push(node)

      selection = selectNodes().enter().append('circle')
      selection.attr('cx', node.x)
      selection.attr('cy', node.y)
      selection.attr('r', 0)
      selection.transition().duration(ANIMATION_DURATION).attr('r', node.r)

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

      source_node = getNode(source)
      target_node = getNode(target)

      edge_data.push({
        source: source,
        target: target,
        label: label
      })

      selection = selectEdges().enter().append('line')
      selection
        .attr('stroke', 'black')
        .attr('x1', source_node.x)
        .attr('y1', source_node.y)
        .attr('x2', source_node.x)
        .attr('y2', source_node.y)
      selection.transition().duration(ANIMATION_DURATION)
        .attr('x2', target_node.x)
        .attr('y2', target_node.y)

      setTimeout((() ->
        layoutBFS()
        render(true)
        setTimeout((() ->
          if done?
            done()
        ), ANIMATION_DURATION)
      ), ANIMATION_DURATION)

    removeEdge: (source, target, label, animate, done) ->
      console.log('removeEdge ' + makeString([source, target, animate]))

      source_node = getNode(source)
      target_node = getNode(target)

      for edge, i in edge_data
        if edge.source == source and edge.target == target and edge.label == label
          edge_data.splice(i, 1)
          break

      selection = selectEdges().exit()
      selection.transition().duration(ANIMATION_DURATION)
        .attr('x2', source_node.x)
        .attr('y2', source_node.y)

      setTimeout((() ->
        selection.remove()
        layoutBFS()
        render(true)
        setTimeout((() ->
          if done?
            done()
        ), ANIMATION_DURATION)
      ), ANIMATION_DURATION)
  }
)])
