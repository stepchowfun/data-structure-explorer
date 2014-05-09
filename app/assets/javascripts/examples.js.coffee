examples = angular.module('examples', ['models'])

examples.factory('examples', ['models', ((models) ->
  return [
    {
      name: 'Binary search tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (global.root === null) {\n    global.root = make_node({ value: value });\n  } else {\n    if (subtree === undefined) {\n      subtree = global.root;\n    }\n    if (value < subtree.value) {\n      if (subtree.left_child === null) {\n        subtree.left_child = make_node({ value: value });\n      } else {\n        insert(value, subtree.left_child);\n      }\n    } else if (value > subtree.value) {\n      if (subtree.right_child === null) {\n        subtree.right_child = make_node({ value: value });\n      } else {\n        insert(value, subtree.right_child);\n      }\n    } else {\n      throw Error("Value already exists: " + String(value) + ".");\n    }\n  }\n}'
        },
        {
          name: 'remove',
          code: 'function remove(value, subtree) {\n\n}'
        },
        {
          name: 'contains',
          code: 'function contains(value, subtree) {\n  if (global.root === null) {\n    return false;\n  }\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    return false;\n  }\n  if (value < subtree.value) {\n    return contains(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    return contains(value, subtree.right_child);\n  } else {\n    return true;\n  }\n}'
        }
      ],
      model: models[0],
      model_options: {
        fields: ['value', 'left_child', 'right_child']
      }
    },
    {
      name: 'Splay tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n\n}'
        },
        {
          name: 'remove',
          code: 'function remove(value, subtree) {\n\n}'
        },
        {
          name: 'contains',
          code: 'function contains(value, subtree) {\n\n}'
        }
      ],
      model: models[1],
      model_options: { }
    },
    {
      name: 'MonoCell',
      operations: [ ],
      model: models[0],
      model_options: { fields: ['value'] }
    }
  ]
)])
