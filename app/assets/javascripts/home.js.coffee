# initialize Foundation
$ -> $(document).foundation()

# application module
cherries = angular.module('cherries', [])

cherries.controller('CherriesController', ['$scope', ($scope) ->
  $scope.data_structures = [
    {
      name: 'Binary search tree',
      fields: ['test', 'hello'],
      operations: [
        {
          name: 'make_bst',
          code: 'Hello'
        }
      ]
    },
    {
      name: 'Splay tree',
      fields: ['foo', 'bar', 'baz'],
      operations: [
        {
          name: 'make_splay_tree',
          code: 'World'
        }
      ]
    }
  ]
  window.data_structures = $scope.data_structures

  $scope.active_page = 0
  $scope.active_data_structure = $scope.data_structures[0]

  $scope.newDataStructure = (event) ->
    name = 'Untitled'
    counter = 1
    while name in (data_structure.name for data_structure in $scope.data_structures)
      counter += 1
      name = 'Untitled ' + String(counter)
    data_structure = {
      name: name,
      fields: [],
      operations: []
    }
    $scope.data_structures.push(data_structure)
    $scope.activateDataStructure(data_structure, event)

  # fields

  $scope.activateDataStructure = (data_structure, event) ->
    $scope.active_page = 0
    $scope.active_data_structure = data_structure
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_define_link').click()), 1)

  $scope.clearAddFieldError = (data_structure) ->
    data_structure.new_field_error = null

  $scope.addField = (data_structure, event) ->
    if !data_structure.new_field_name? || data_structure.new_field_name == ''
      data_structure.new_field_error = 'Please enter a name.'
      return
    if data_structure.new_field_name in data_structure.fields
      data_structure.new_field_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test(data_structure.new_field_name))
      data_structure.new_field_error = 'Invalid name.'
      return
    data_structure.fields.push(data_structure.new_field_name)
    data_structure.new_field_name = ''
    $scope.clearAddFieldError(data_structure)
    setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()

  $scope.moveFieldUp = (data_structure, field, event) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? && index > 0
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index - 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_field_link_' + field).click()), 1)

  $scope.moveFieldDown = (data_structure, field, event) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index? && index < data_structure.fields.length - 1
      data_structure.fields.splice(index, 1)
      data_structure.fields.splice(index + 1, 0, field)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_field_link_' + field).click()), 1)

  $scope.removeField = (data_structure, field, event) ->
    index = null
    for name, i in data_structure.fields
      if name == field
        index = i
        break
    if index?
      data_structure.fields.splice(index, 1)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()

  # operations

  $scope.clearAddOperationError = (data_structure) ->
    data_structure.new_operation_error = null

  $scope.addOperation = (data_structure, event) ->
    if !data_structure.new_operation_name? || data_structure.new_operation_name == ''
      data_structure.new_operation_error = 'Please enter a name.'
      return
    if data_structure.new_operation_name in (operation.name for operation in data_structure.operations)
      data_structure.new_operation_error = 'Already exists.'
      return
    if !(/^[\$_a-zA-Z][\$_a-zA-Z0-9]*$/.test(data_structure.new_operation_name))
      data_structure.new_operation_error = 'Invalid name.'
      return
    data_structure.operations.push({
      name: data_structure.new_operation_name,
      code: '',
    })
    data_structure.new_operation_name = ''
    $scope.clearAddOperationError(data_structure)
    setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()

  $scope.moveOperationUp = (data_structure, operation, event) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? && index > 0
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index - 1, 0, operation)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_operation_link_' + operation.name).click()), 1)

  $scope.moveOperationDown = (data_structure, operation, event) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index? && index < data_structure.operations.length - 1
      data_structure.operations.splice(index, 1)
      data_structure.operations.splice(index + 1, 0, operation)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
      setTimeout((() -> $('#dropdown_operation_link_' + operation.name).click()), 1)

  $scope.removeOperation = (data_structure, operation, event) ->
    index = null
    for op, i in data_structure.operations
      if op.name == operation.name
        index = i
        break
    if index?
      data_structure.operations.splice(index, 1)
      setTimeout((() -> $(document).foundation()), 1)
    if event?
      event.preventDefault()
      event.stopPropagation()
])
