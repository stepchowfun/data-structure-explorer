models = angular.module('models', [])

command_steps = []

class pointer_machine
  constructor: (() ->),
  name: 'Pointer machine',
  getInitialState: ((options) ->
    return {
      options: options,
      state: []
    }
  ),
  getCommandSteps: ((state, command, operations) ->
    command_steps = []
    (() ->
      context = { }
      context.command_steps = undefined;
      for api_fn_name, api_fn of pointer_machine.prototype.api
        context[api_fn_name] = api_fn
      for operation in operations
        context[operation.name] = operation.fn
      `with (context) {
        eval(command);
      }`
      null
    )()
    return command_steps
  ),
  api: {
    append: ((x) ->
      command_steps.push({
        repr: 'append ' + x.toString(),
        up: ((state) ->
          state.state.push(x)
          console.log(state.state)
        ),
        down: ((state) ->
          state.state.pop()
          console.log(state.state)
        ),
      })
    )
  }

class bst
  constructor: (() ->),
  name: 'Binary search tree',
  getInitialState: ((options) ->
    return {
      options: options
    }
  ),
  getCommandSteps: ((state, command, operations) ->
    result = (() ->
      context = { }
      for operation in operations
        context[operation.name] = operation.fn
      `with (context) {
        return eval(command);
      }`
      null
    )()
    return [
      {
        repr: 'x.foo = 5',
        up: ((state) -> console.log state),
        down: ((state) -> console.log state)
      },
      {
        repr: 'y.bar = 7',
        up: ((state) -> console.log state),
        down: ((state) -> console.log state)
      }
    ]
  )

models.value('models', [
  new pointer_machine(),
  new bst(),
])
