examples = angular.module('examples', ['models'])

examples.factory('examples', ['models', ((models) ->
  return [
    {
      name: 'Binary search tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (global.root === null) {\n    global.root = make_node({ value: value });\n  } else {\n    if (subtree === undefined) {\n      subtree = global.root;\n    }\n    if (value < subtree.value) {\n      if (subtree.left_child === null) {\n        subtree.left_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.left_child);\n      }\n    } else if (value > subtree.value) {\n      if (subtree.right_child === null) {\n        subtree.right_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.right_child);\n      }\n    } else {\n      throw Error("Value already exists: " + String(value) + ".");\n    }\n  }\n}'
        }
      ],
      model: models[0],
      model_options: {
        fields: ['value', 'parent', 'left_child', 'right_child']
      }
    }
  ]
)])
