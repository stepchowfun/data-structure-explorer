active_data_structure = null

root = null

get_root = () ->
  return root

set_root = (node) ->
  root = node

class Node
  constructor: (fields) ->
    @fields = { }
    for field in active_data_structure.fields
      @fields[field] = null
    if fields?
      for key, value of fields
        @set_field(key, value)

  get_field: (field) ->
    if field in active_data_structure.fields
      return @fields[field]
    else
      throw Error('Unknown field: ' + String(field))

  set_field: (field, value) ->
    if field in active_data_structure.fields
      @fields[field] = value
    else
      throw 'Unknown field: ' + String(field)

$ ->
  for data_structure in window.data_structures
    if data_structure.name == 'Binary search tree'
      active_data_structure = data_structure

  node = new Node { left_child: null }
