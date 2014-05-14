models = angular.module('models', ['sandbox', 'pointer_machine'])

command_steps = [ ]
current_state = null
current_model_options = null
rendering_disabled = false

models.factory('models', ['pointer_machine', (pointer_machine) ->
  machines_array = [
    pointer_machine
  ]
  machines_object = { }
  for machine in machines_array
    machines_object[machine.machine_name] = machine
  return machines_object
])

models.factory('getCurrentState', [() ->
  return () ->
    return current_state
])

models.factory('getCommandSteps', [() ->
  return () ->
    return command_steps
])

models.factory('getModelOptions', [() ->
  return () ->
    return current_model_options
])

models.factory('renderingDisabled', [() ->
  return () ->
    return rendering_disabled
])

models.factory('runCommand', ['sandbox', (sandbox) ->
  return (state, command, operations, model, model_options) ->
    command_steps = [ ]
    current_state = state
    current_model_options = model_options
    fragment = {
      code: command
    }
    definitions = { }
    for name, fn of model.api
      definitions[name] = fn
    for operation in operations
      definitions[operation.name] = operation.compiled_value
    rendering_disabled = true
    sandbox([fragment], definitions)
    command_steps.reverse()
    for command in command_steps
      command.down(current_state, false, null)
    command_steps.reverse()
    rendering_disabled = false
    if fragment.error?
      return {
        steps: null,
        return_value: null,
        error: fragment.error
      }
    return {
      steps: angular.copy(command_steps),
      return_value: fragment.compiled_value,
      error: null
    }
])
