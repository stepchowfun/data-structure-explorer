makeString = angular.module('makeString', [])

# returns a string version of anything
makeString.value('makeString', (value) ->
  makeStringRecursive = (value, visited) ->
    if value == null or typeof value != 'object'
      return String(value)
    if value in visited
      return '...'
    visited.push(value)
    if value.hasOwnProperty('toString')
      try
        return value.toString()
      catch
    if value instanceof Array
      return '[' + (makeStringRecursive(e, visited) for e in value).join(', ') + ']'
    return '{' + (makeStringRecursive(k, visited) + ': ' + makeStringRecursive(v, visited) for k, v of value).join(', ') + '}'
  return makeStringRecursive(value, [ ])
)
