active_data_structure = 'Binary search tree'

get_data_structure = (name) ->
  for data_structure in window.data_structures
    if data_structure.name == name
      return data_structure

class Node
  constructor: () ->
    @fields = {}
    for field in get_data_structure(active_data_structure).fields
      @fields[field] = null

root = null

get_root = () ->
  return root

set_root = (node) ->
  root = node

make_node = (fields) ->
  if fields?
    node = new Node()
    for field in fields
      set_field(node, field, fields[field])
  else
    return new Node()

get_field = (node, field) ->
  if field in get_data_structure(active_data_structure).fields
    return node.fields[field]
  else
    throw 'Unknown field: ' + String(field)

set_field = (node, field, value) ->
  if field in get_data_structure(active_data_structure).fields
    node.fields[field] = value
  else
    throw 'Unknown field: ' + String(field)
