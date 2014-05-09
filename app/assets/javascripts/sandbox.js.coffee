sandbox = angular.module('sandbox', [])

sandbox.factory('sandbox', ['makeString', (makeString) ->
  (() -> return ((fragments, definitions) ->
    context = { }
    for key, value of window
      context[key] = undefined
    context.sandbox = undefined
    context.fragment = undefined
    for key, value of definitions
      context[key] = value
    for fragment in fragments
      if fragment.name?
        eval('var ' + fragment.name + ' = undefined;')
    for fragment in fragments
      try
        fragment.compiled_value = ((window) ->
          if fragment.name?
            fragment_code = fragment.code
            fragment_name = fragment.name
            `with (context) {
              eval(fragment_code);
              return eval(fragment_name);
            }`
            undefined
          else
            fragment_code = fragment.code
            `with (context) {
              return eval(fragment_code);
            }`
            undefined
        ).call({ }, { })
        if fragment.name?
          if fragment.compiled_value == undefined
            throw Error('Undefined value: ' + fragment.name + '.')
          eval(fragment.name + ' = fragment.compiled_value;')
        fragment.error = null
      catch error
        if error == null or typeof error != 'object'
          fragment.error = {
            name: 'Error',
            message: 'Unexpected error: ' + makeString(error) + '.'
          }
        else
          fragment.error = error
          if !fragment.error.name?
            fragment.error.name = 'Error'
          if !fragment.error.message?
            fragment.error.message = 'Unexpected error: ' + makeString(error) + '.'
          if !fragment.error.stack?
            fragment.error.stack = 'No stack trace.'
    undefined
  ))()
])
