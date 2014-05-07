active_data_structure = 'Binary search tree'

get_data_structure = (name) ->
  for data_structure in window.data_structures
    if data_structure.name == name
      return data_structure

root = null

get_root = () ->
  return root

set_root = (node) ->
  root = node

class Node
  constructor: (fields) ->
    @fields = { }
    for field in get_data_structure(active_data_structure).fields
      @fields[field] = null
    if fields?
      for key, value of fields
        @set_field(key, value)

  get_field: (field) ->
    if field in get_data_structure(active_data_structure).fields
      return @fields[field]
    else
      throw Error('Unknown field: ' + String(field))

  set_field: (field, value) ->
    if field in get_data_structure(active_data_structure).fields
      @fields[field] = value
    else
      throw 'Unknown field: ' + String(field)

$ ->
  node = new Node { left_child: null }
