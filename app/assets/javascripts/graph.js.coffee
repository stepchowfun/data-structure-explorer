graph = angular.module('graph', ['makeString', 'debounce'])

graph.factory('graph', ['makeString', 'debounce', ((makeString, debounce) ->
  ANIMATION_DURATION = 300
  X_SPACING = 200
  Y_SPACING = 200
  RADIUS = 60
  LINE_HEIGHT = 20

  root_id = null
  node_data = [ ]
  edge_data = [ ]
  view_x = -100
  view_y = -100
  view_width = 200
  view_height = 200
  last_mouse_x = 0
  last_mouse_y = 0

  getWidth = () ->
    width = $('#graph').width()
    if width > 0
      return width
    return 200

  getHeight = () ->
    height = $('#graph').height()
    if height > 0
      return height
    return 200

  getHeight = () -> $('#graph').height()

  selectNodes = () ->
    return d3.select('#graph #nodes').selectAll('g.node').data(node_data, (d) -> d.id)

  selectNode = (node) ->
    return d3.select('#graph #nodes').select('g.node#' + node.id)

  selectEdges = () ->
    return d3.selectAll('#graph #edges').selectAll('g.edge').data(edge_data, (d) -> String(d.source) + ':' + String(d.target) + ':' + d.label)

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
    edge_data.sort(
      (a, b) ->
        if a.label < b.label
          return -1
        else if a.label > b.label
          return 1
        return 0
    )
    for edge in edge_data
      if edge.source == node.id
        target_node = getNode(edge.target)
        if !(target_node in adjacent)
          adjacent.push(target_node)
    for edge in edge_data
      if edge.target == node.id
        source_node = getNode(edge.source)
        if !(source_node in adjacent)
          adjacent.push(source_node)
    return adjacent

  layoutBFS = () ->
    if node_data.length == 0
      view_x = -100
      view_y = -100
      view_width = 200
      view_height = 200
      return

    node_data.sort(
      (a, b) ->
        if a.id < b.id
          return -1
        else if a.id > b.id
          return 1
        return 0
    )

    visited = [ ]
    preprocessSubtrees = (root) ->
      visited.push(root)
      root.children = (adjacent for adjacent in getAdjacent(root) when !(adjacent in visited))
      root.children.sort(
        (a, b) ->
          if a.id < b.id
            return -1
          else if a.id > b.id
            return 1
          return 0
      )
      if root.children.length == 0
        root.width = 1
        root.height = 1
      else
        root.width = 0
        root.height = 0
        for child in root.children
          preprocessSubtrees(child)
          root.width += child.width
          if root.height < child.height + 1
            root.height = child.height + 1

    roots = [ ]
    if root_id?
      root = getNode(root_id)
      roots.push(root)
      preprocessSubtrees(root)
    while visited.length < node_data.length
      root = null
      for node in node_data
        if !(node in visited)
          root = node
          break
      roots.push(root)
      preprocessSubtrees(root)

    layoutTree = (root, x, y) ->
      root.x = x
      root.y = y
      sub_x = x - root.width * X_SPACING / 2
      for child in root.children
        layoutTree(child, sub_x + child.width * X_SPACING / 2, y + Y_SPACING)
        sub_x += child.width * X_SPACING

    total_width = 0
    total_height = 0
    for root in roots
      total_width += root.width
      if total_height < root.height
        total_height = root.height
    x = -total_width * X_SPACING / 2
    for root in roots
      layoutTree(root, x + root.width * X_SPACING / 2, 0)
      x += root.width * X_SPACING

    view_x = -total_width * X_SPACING / 2
    view_y = -X_SPACING / 2
    view_width = total_width * X_SPACING
    view_height = total_height * Y_SPACING

    undefined

  updateViewBox = (animate) ->
    x_factor = (last_mouse_x - $('#graph').offset().left) / getWidth()
    y_factor = (last_mouse_y - $('#graph').offset().top) / getHeight()
    if x_factor < 0
      x_factor = 0
    if y_factor < 0
      y_factor = 0
    if x_factor > 1
      x_factor = 1
    if y_factor > 1
      y_factor = 1
    x_min = view_x
    y_min = view_y
    x_max = view_x + view_width - getWidth()
    y_max = view_y + view_height - getHeight()
    width = getWidth()
    height = getHeight()
    if view_width < width
      x = view_x + view_width / 2 - getWidth() / 2
    else
      x = x_min + (x_max - x_min) * x_factor
    if view_height < height
      y = view_y + view_height / 2 - getHeight() / 2
    else
      y = y_min + (y_max - y_min) * y_factor
    svg = d3.select('#graph')
    if animate
      svg = svg.transition().duration(ANIMATION_DURATION)
    svg.attr('viewBox', String(x) + ' ' + String(y) + ' ' + String(width) + ' ' + String(height))

  render = (animate) ->
    selection = selectNodes()
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection.attr('transform', (d) -> ('translate(' + String(d.x) + ', ' + String(d.y) + ')'))

    selection = selectEdges().select('line')
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection
      .attr('x1', (d) ->
        source_node = getNode(d.source)
        target_node = getNode(d.target)
        norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
        return source_node.x + RADIUS * (target_node.x - source_node.x) / norm
      )
      .attr('y1', (d) ->
        source_node = getNode(d.source)
        target_node = getNode(d.target)
        norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
        return source_node.y + RADIUS * (target_node.y - source_node.y) / norm
      )
      .attr('x2', (d) ->
        source_node = getNode(d.source)
        target_node = getNode(d.target)
        norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
        return target_node.x - RADIUS * (target_node.x - source_node.x) / norm
      )
      .attr('y2', (d) ->
        source_node = getNode(d.source)
        target_node = getNode(d.target)
        norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
        return target_node.y - RADIUS * (target_node.y - source_node.y) / norm
      )

    updateViewBox(true)

  $(window).resize(debounce () ->
    render(true)
  )

  $(window).mousemove((event) ->
    last_mouse_x = event.pageX
    last_mouse_y = event.pageY
    if $('#graph').is(":visible")
      updateViewBox(false)
  )

  return {
    setRoot: (target, animate, done) ->
      console.log('setRoot ' + makeString([target, animate]))

      if root_id == target
        if done?
          done()
      else
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
        x: 0,
        y: -Y_SPACING,
      }
      node_data.push(node)
      selection = selectNodes().enter().append('g').attr('id', id).attr('class', 'node')
      selection
        .attr('transform', 'translate(' + String(node.x) + ', ' + String(node.y) + ')')
        .attr('opacity', 0)
        .transition().duration(ANIMATION_DURATION).attr('opacity', 1)
      selection.append('circle')
        .attr('class', 'node-circle')
        .attr('cx', 0)
        .attr('cy', 0)
        .attr('r', 0)
        .transition().duration(ANIMATION_DURATION).attr('r', RADIUS)
      selection.append('text')
        .attr('class', 'node-name')
        .text(id)
        .attr('x', -RADIUS)
        .attr('y', -RADIUS)
      data_group_outline = selection.append('g').attr('class', 'data_outline')
      data_group = selection.append('g').attr('class', 'data')
      data_entries = [ ]
      i = 0
      for k, v of data
        data_entries.push(k + ': ' + v)
      data_group_outline.selectAll('text').data(data_entries, (d) -> d).enter().append('text')
        .text((d) -> d)
        .attr('x', 0)
        .attr('y', (d, i) -> (15 + LINE_HEIGHT * (i - data_entries.length / 2)))
        .attr('text-anchor', 'middle')
      data_group.selectAll('text').data(data_entries, (d) -> d).enter().append('text')
        .text((d) -> d)
        .attr('x', 0)
        .attr('y', (d, i) -> (15 + LINE_HEIGHT * (i - data_entries.length / 2)))
        .attr('text-anchor', 'middle')
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
      selection.transition().duration(ANIMATION_DURATION).attr('opacity', 0)
      selection.select('circle.node-circle').transition().duration(ANIMATION_DURATION).attr('r', 0)
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

      node = getNode(id)
      node.data = data
      data_entries = [ ]
      i = 0
      for k, v of data
        data_entries.push(k + ': ' + v)
      selection = selectNode(node)
      data_group_outline = selection.select('g.data_outline').selectAll('text').data(data_entries, (d) -> d)
      data_group = selection.select('g.data').selectAll('text').data(data_entries, (d) -> d)
      data_group_outline.enter().append('text')
        .text((d) -> d)
        .attr('x', 0)
        .attr('y', (d, i) -> (15 + LINE_HEIGHT * (i - data_entries.length / 2)))
        .attr('text-anchor', 'middle')
      data_group_outline.exit().remove()
      data_group.enter().append('text')
        .text((d) -> d)
        .attr('x', 0)
        .attr('y', (d, i) -> (15 + LINE_HEIGHT * (i - data_entries.length / 2)))
        .attr('text-anchor', 'middle')
      data_group.exit().remove()
      if animate
        selection.select('circle.node-circle').transition().duration(150).attr('r', RADIUS * 1.3)
        setTimeout((() ->
          selection.select('circle.node-circle').transition().duration(150).attr('r', RADIUS)
        ), 200)
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

      selection = selectEdges().enter().append('g').attr('class', 'edge').append('line')
      selection
        .attr('x1', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return source_node.x + RADIUS * (target_node.x - source_node.x) / norm
        )
        .attr('y1', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return source_node.y + RADIUS * (target_node.y - source_node.y) / norm
        )
        .attr('x2', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return source_node.x + RADIUS * (target_node.x - source_node.x) / norm
        )
        .attr('y2', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return source_node.y + RADIUS * (target_node.y - source_node.y) / norm
        )
      selection.transition().duration(ANIMATION_DURATION)
        .attr('x2', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return target_node.x - RADIUS * (target_node.x - source_node.x) / norm
        )
        .attr('y2', (d) ->
          source_node = getNode(d.source)
          target_node = getNode(d.target)
          norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
          return target_node.y - RADIUS * (target_node.y - source_node.y) / norm
        )

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
