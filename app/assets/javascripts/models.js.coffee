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
