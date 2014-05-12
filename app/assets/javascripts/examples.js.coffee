examples = angular.module('examples', ['models'])

examples.factory('examples', ['models', ((models) ->
  return [
    {
      name: 'Binary search tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (global.root === null) {\n    global.root = make_node({ value: value });\n  } else {\n    if (subtree === undefined) {\n      subtree = global.root;\n    }\n    if (value < subtree.value) {\n      if (subtree.left_child === null) {\n        subtree.left_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.left_child);\n      }\n    } else if (value > subtree.value) {\n      if (subtree.right_child === null) {\n        subtree.right_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.right_child);\n      }\n    } else {\n      throw Error("Value already exists: " + String(value) + ".");\n    }\n  }\n}'
        },
        {
          name: 'contains',
          code: 'function contains(value, subtree) {\n  if (global.root === null) {\n    return false;\n  }\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    return false;\n  }\n  if (value < subtree.value) {\n    return contains(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    return contains(value, subtree.right_child);\n  } else {\n    return true;\n  }\n}'
        },
        {
          name: 'remove',
          code: 'function replace_node(old_node, new_node) {\n  if (old_node === global.root) {\n    global.root = new_node;\n    if (new_node !== null) {\n      new_node.parent = null;\n    }\n  } else {\n    if (old_node.parent.left_child === old_node) {\n      old_node.parent.left_child = new_node;\n    } else {\n      old_node.parent.right_child = new_node;\n    }\n    if (new_node !== null) {\n      new_node.parent = old_node.parent;\n    }\n    old_node.parent = null;\n  }\n}\n\nfunction find_min(subtree) {\n  if (global.root === null) {\n    throw Error("Empty tree");\n  }\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree.left_child === null) {\n    return subtree;\n  } else {\n    return find_min(subtree.left_child);\n  }\n}\n\nfunction remove(value, subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Value does not exist: " + String(value) + ".");\n  }\n  if (value < subtree.value) {\n    remove(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    remove(value, subtree.right_child);\n  } else {\n    if (subtree.left_child === null && subtree.right_child === null) {\n      replace_node(subtree, null);\n      delete_node(subtree);\n    } else if (subtree.left_child === null) {\n      replace_node(subtree, subtree.right_child);\n      delete_node(subtree);\n    } else if (subtree.right_child === null) {\n      replace_node(subtree, subtree.left_child);\n      delete_node(subtree);\n    } else {\n      var successor = find_min(subtree.right_child);\n      subtree.value = successor.value;\n      remove(successor.value, successor);\n    }\n  }\n}'
        }
      ],
      model: models[0],
      model_options: {
        fields: ['value', 'parent', 'left_child', 'right_child']
      }
    },
    {
        name: "AVL Tree",
        model: models[0],
        model_options: {
            fields: ['left_child', 'value', 'parent', 'right_child']
        },
        operations: [{
        name: 'insert',
        code: 'function insert(value, subtree) {\n  // Normal BST insert\n  if (global.root === null) {\n    global.root = make_node({ value: value });\n  } else {\n    if (subtree === undefined) {\n      subtree = global.root;\n    }\n    if (value < subtree.value) {\n      if (subtree.left_child === null) {\n        subtree.left_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.left_child);\n      }\n      balance(subtree);\n    } else if (value > subtree.value) {\n      if (subtree.right_child === null) {\n        subtree.right_child = make_node({ value: value, parent: subtree });\n      } else {\n        insert(value, subtree.right_child);\n      }\n      balance(subtree);\n    } else {\n      throw Error("Value already exists: " + String(value) + ".");\n    }\n  }\n}'
        },
        {
        name: 'right_rotate',
        code: 'function right_rotate(subtree) {\n	var left = subtree.left_child;\n  subtree.left_child = left.right_child;\n  left.parent = subtree.parent;\n  if (subtree.parent){\n    subtree.parent = left;\n  }\n  left.right_child = subtree;\n  if (global.root === subtree){\n   	 global.root = left;\n  }\n}'
        },
        {
        name: 'left_rotate',
        code: 'function left_rotate(subtree) {\n	var right = subtree.right_child;\n  subtree.right_child = right.left_child;\n  right.parent = subtree.parent;\n  if (subtree.parent){\n    throw Error(subtree.parent);\n    subtree.parent = right;\n  }\n  right.left_child = subtree;\n  if (global.root === subtree){\n   	global.root = right; \n  }\n}'
        },
        {
        name: 'get_balance',
        code: 'function get_height(subtree) {\n  if (!subtree){\n		return 0;\n  } else {\n   	return 1 + Math.max(get_height(subtree.left_child), get_height(subtree.right_child))\n  }\n}\n\nfunction get_balance(subtree) {\n  if (!subtree){\n    return 0;\n  }\n	return get_height(subtree.left_child) - get_height(subtree.right_child);\n}'
        },
        {
        name: 'balance'
        code: 'function balance(subtree) {\n \n  if (get_balance(subtree) > 1){\n    if (subtree.value < subtree.left_child.value)\n    {\n       left_rotate(subtree.left_child);\n    }\n    right_rotate(subtree);\n  }\n\n  else if (get_balance(subtree) < -1){\n    if (subtree.value > subtree.right_child.value)\n    {\n        right_rotate(subtree.right_child);\n    }\n    left_rotate(subtree);\n  }\n}'
        }
        {
        name: 'remove',
        code: 'function replace_node(old_node, new_node) {\n  if (old_node === global.root) {\n    global.root = new_node;\n    if (new_node !== null) {\n      new_node.parent = null;\n    }\n  } else {\n    if (old_node.parent.left_child === old_node) {\n      old_node.parent.left_child = new_node;\n    } else {\n      old_node.parent.right_child = new_node;\n    }\n    if (new_node !== null) {\n      new_node.parent = old_node.parent;\n    }\n    old_node.parent = null;\n  }\n}\n\nfunction find_min(subtree) {\n  if (global.root === null) {\n    throw Error("Empty tree");\n  }\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree.left_child === null) {\n    return subtree;\n  } else {\n    return find_min(subtree.left_child);\n  }\n}\n\nfunction remove(value, subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Value does not exist: " + String(value) + ".");\n  }\n  if (value < subtree.value) {\n    remove(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    remove(value, subtree.right_child);\n  } else {\n    var check_this = subtree.parent;\n    if (subtree.left_child === null && subtree.right_child === null) {\n      replace_node(subtree, null);\n      delete_node(subtree);\n    } else if (subtree.left_child === null) {\n      replace_node(subtree, subtree.right_child);\n      delete_node(subtree);\n    } else if (subtree.right_child === null) {\n      replace_node(subtree, subtree.left_child);\n      delete_node(subtree);\n    } else {\n      var successor = find_min(subtree.right_child);\n      subtree.value = successor.value;\n      remove(successor.value, successor);\n    }\n  	if (check_this && get_balance(check_this) > 1){\n      	if (get_balance(check_this.left_child) < 0){\n      		left_rotate(check_this.left_child);\n  			}\n  			right_rotate(check_this);\n  	}\n  	if (check_this && get_balance(check_this) < -1){\n      	if (get_balance(check_this.right_child) > 0){\n      		right_rotate(check_this.right_child);\n  			}\n  			left_rotate(check_this);\n    }\n  }\n}'
        }
        ],
    }
    ]
)])
