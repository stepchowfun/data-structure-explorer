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
          for evil in ['eval', 'Function', 'setTimeout', 'setInterval', 'requestAnimationFrame']
            if fragment.code.indexOf(evil) >= 0
              throw Error('Use of \'' + evil + '\' is disallowed.')
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
          fragment.error = Error('Unexpected error: ' + makeString(error) + '.')
        else
          fragment.error = error
        if !fragment.error.name?
          fragment.error.name = 'Error'
        if !fragment.error.message?
          fragment.error.message = 'Unexpected error: ' + makeString(error) + '.'
        if !fragment.error.stack?
          fragment.error.stack = 'No stack trace.'
        fragment.error.stack_list = null
        try
          stack_list = printStackTrace({e: error})
          console.log stack_list
          i = stack_list.length - 1
          found = false
          while i >= 0
            if /[^$]eval/g.test(stack_list[i])
              stack_list = stack_list.slice(0, i + 1)
              found = true
              break
            i -= 1
          if found
            i = 0
            while i < stack_list.length
              stack_list[i] = stack_list[i].replace(/\ \(.*\), \<anonymous\>/g, '')
              stack_list[i] = stack_list[i].replace('Object.', '')
              stack_list[i] = stack_list[i].replace('eval', 'code')
              stack_list[i] = stack_list[i].replace(/:([0-9]*)\:[0-9]*$/g, ':$1')
              i += 1
            fragment.error.stack_list = stack_list
        catch
          undefined
    undefined
  ))()
])
