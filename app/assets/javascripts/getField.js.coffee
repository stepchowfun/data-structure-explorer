getField = angular.module('getField', [])

# returns the field of an object if it exists
getField.value('getField', (object, field) ->
  if object == null or typeof object != 'object'
    return undefined
  return object[field]
)