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

    for edge in edge_data
      source_node = getNode(edge.source)
      target_node = getNode(edge.target)
      norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
      edge.x1 = source_node.x + RADIUS * (target_node.x - source_node.x) / norm
      edge.y1 = source_node.y + RADIUS * (target_node.y - source_node.y) / norm
      edge.x2 = target_node.x - RADIUS * (target_node.x - source_node.x) / norm
      edge.y2 = target_node.y - RADIUS * (target_node.y - source_node.y) / norm

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

    selection = selectEdges().select('line.edge-line')
    if animate
      selection = selection.transition().duration(ANIMATION_DURATION)
    selection
      .attr('x1', (d) -> d.x1)
      .attr('y1', (d) -> d.y1)
      .attr('x2', (d) -> d.x2)
      .attr('y2', (d) -> d.y2)

    updateViewBox(animate)

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
      if root_id == target
        if done?
          done()
      else
        old_root_id = root_id
        root_id = target
        layoutBFS()
        render(animate)
        if animate
          if old_root_id?
            selectNode(getNode(old_root_id)).select('circle.node-circle').transition().duration(ANIMATION_DURATION).attr('fill', '#fff')
          if root_id?
            selectNode(getNode(root_id)).select('circle.node-circle').transition().duration(ANIMATION_DURATION).attr('fill', '#eee')
          setTimeout((() ->
            if done?
              done()
          ), ANIMATION_DURATION)
        else
          if done?
            done()

    addNode: (id, data, animate, done) ->
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
      if animate
        selection
          .attr('opacity', 0)
          .transition().duration(ANIMATION_DURATION).attr('opacity', 1)
      node_circle = selection.append('circle')
        .attr('class', 'node-circle')
        .attr('fill', '#fff')
        .attr('cx', 0)
        .attr('cy', 0)
        if animate
          node_circle
            .attr('r', 0)
            .transition().duration(ANIMATION_DURATION).attr('r', RADIUS)
        else
          node_circle.attr('r', RADIUS)
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
      if animate
        setTimeout((() ->
          layoutBFS()
          render(animate)
          setTimeout((() ->
            if done?
              done()
          ), ANIMATION_DURATION)
        ), ANIMATION_DURATION)
      else
        layoutBFS()
        render(animate)
        if done?
          done()

    removeNode: (id, animate, done) ->
      for node, i in node_data
        if node.id == id
          node_data.splice(i, 1)
          break
      selection = selectNodes().exit()
      if animate
        selection.transition().duration(ANIMATION_DURATION).attr('opacity', 0)
        selection.select('circle.node-circle').transition().duration(ANIMATION_DURATION).attr('r', 0)
        setTimeout((() ->
          selection.remove()
          layoutBFS()
          render(animate)
          setTimeout((() ->
            if done?
              done()
          ), ANIMATION_DURATION)
        ), ANIMATION_DURATION)
      else
        selection.remove()
        layoutBFS()
        render(animate)
        if done?
          done()

    setNodeData: (id, data, animate, done) ->
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
      source_node = getNode(source)
      target_node = getNode(target)
      norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
      edge = {
        source: source,
        target: target,
        label: label,
        x1: source_node.x + RADIUS * (target_node.x - source_node.x) / norm,
        y1: source_node.y + RADIUS * (target_node.y - source_node.y) / norm,
        x2: target_node.x - RADIUS * (target_node.x - source_node.x) / norm,
        y2: target_node.y - RADIUS * (target_node.y - source_node.y) / norm
      }
      edge_data.push(edge)
      selection = selectEdges().enter().append('g').attr('class', 'edge')
      edge_line = selection.append('line').attr('class', 'edge-line')
      edge_line
        .attr('marker-end', 'url(#arrow)')
        .attr('x1', edge.x1)
        .attr('y1', edge.y1)
      if animate
        edge_line
          .attr('x2', edge.x1)
          .attr('y2', edge.y1)
        edge_line.transition().duration(ANIMATION_DURATION)
          .attr('x2', edge.x2)
          .attr('y2', edge.y2)
      else
        edge_line
          .attr('x2', edge.x2)
          .attr('y2', edge.y2)
      if animate
        setTimeout((() ->
          layoutBFS()
          render(animate)
          setTimeout((() ->
            if done?
              done()
          ), ANIMATION_DURATION)
        ), ANIMATION_DURATION)
      else
        layoutBFS()
        render(animate)
        if done?
          done()

    removeEdge: (source, target, label, animate, done) ->
      source_node = getNode(source)
      target_node = getNode(target)
      norm = Math.sqrt(Math.pow(target_node.x - source_node.x, 2) + Math.pow(target_node.y - source_node.y, 2))
      for edge, i in edge_data
        if edge.source == source and edge.target == target and edge.label == label
          edge_data.splice(i, 1)
          break
      selection = selectEdges().exit()
      if animate
        selection.select('line').transition().duration(ANIMATION_DURATION)
          .attr('x2', (d) -> d.x1)
          .attr('y2', (d) -> d.y1)
        setTimeout((() ->
          selection.remove()
          layoutBFS()
          render(animate)
          setTimeout((() ->
            if done?
              done()
          ), ANIMATION_DURATION)
        ), ANIMATION_DURATION)
      else
        selection.remove()
        layoutBFS()
        render(animate)
        if done?
          done()
  }
)])
