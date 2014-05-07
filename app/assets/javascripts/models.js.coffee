models = angular.module('models', [])

models.value('models', [
  {
    name: 'Pointer machine',
    getInitialState: ((options) ->
      return {
        options: options
      }
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
  {
    name: 'Binary search tree',
    getInitialState: ((options) ->
      return {
        options: options
      }
    ),
    getCommandSteps: ((state, command) ->
      return []
    )
  }
])
