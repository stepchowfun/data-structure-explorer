api = angular.module('api', [])

api.value('api', {
  pointer_machine: {
    getInitialState: (() ->
      return null
    ),
    getCommandSteps: ((state, command) ->
      return [
        {
          repr: 'x.foo = 5',
          up: ((state) -> ),
          down: ((state) -> )
        },
        {
          repr: 'y.bar = 7',
          up: ((state) -> ),
          down: ((state) -> )
        }
      ]
    )
  },
  bst: {
    getInitialState: (() ->
      return null
    ),
    getCommandSteps: ((state, command) ->
      return []
    )
  }
})
