examples = angular.module('examples', ['models'])

examples.factory('examples', ['models', 'pointer_machine', 'bst', ((models, pointer_machine, bst) ->
  return [
    {
      name: 'Binary search tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (global.root == null) {\n    global.root = make_node({ value: value });\n  } else {\n    if (subtree == undefined) {\n      subtree = global.root;\n    }\n    if (value < subtree.value) {\n      if (subtree.left_child == null) {\n        subtree.left_child = make_node({ value: value });\n      } else {\n        insert(value, subtree.left_child);\n      }\n    }\n    else if (value > subtree.value) {\n      if (subtree.right_child == null) {\n        subtree.right_child = make_node({ value: value });\n      } else {\n        insert(value, subtree.right_child);\n      }\n    } else {\n      throw Error("Value already exists: " + JSON.stringify(value) + ".");\n    }\n  }\n}'
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
      model: pointer_machine,
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
      model: bst,
      model_options: { }
    }
  ]
)])
