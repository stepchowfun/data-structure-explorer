examples = angular.module('examples', ['models'])

examples.factory('examples', ['models', ((models) ->
  return [
    {
      name: 'Binary search tree',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (subtree === undefined) {\n    if (global.root === null) {\n      global.root = make_node({ value: value });\n      return;\n    }\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    subtree = make_node({ value: value });\n    return;\n  }\n  if (value < subtree.value) {\n    if (subtree.left_child === null) {\n      subtree.left_child = make_node({ value: value, parent: subtree });\n    } else {\n      insert(value, subtree.left_child);\n    }\n  } else if (value > subtree.value) {\n    if (subtree.right_child === null) {\n      subtree.right_child = make_node({ value: value, parent: subtree });\n    } else {\n      insert(value, subtree.right_child);\n    }\n  } else {\n    throw Error("Value already exists: " + String(value) + ".");\n  }\n}'
        },
        {
          name: 'contains',
          code: 'function contains(value, subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    return false;\n  }\n  if (value < subtree.value) {\n    return contains(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    return contains(value, subtree.right_child);\n  } else {\n    return true;\n  }\n}'
        },
        {
          name: 'remove',
          code: 'function replace_node(old_node, new_node) {\n  if (old_node === global.root) {\n    global.root = new_node;\n    if (new_node !== null) {\n      new_node.parent = null;\n    }\n  } else {\n    if (old_node.parent.left_child === old_node) {\n      old_node.parent.left_child = new_node;\n    } else {\n      old_node.parent.right_child = new_node;\n    }\n    if (new_node !== null) {\n      new_node.parent = old_node.parent;\n    }\n    old_node.parent = null;\n  }\n}\n\nfunction find_min(subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Empty tree");\n  }\n  if (subtree.left_child === null) {\n    return subtree;\n  } else {\n    return find_min(subtree.left_child);\n  }\n}\n\nfunction remove(value, subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Value does not exist: " + String(value) + ".");\n  }\n  if (value < subtree.value) {\n    remove(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    remove(value, subtree.right_child);\n  } else {\n    if (subtree.left_child === null && subtree.right_child === null) {\n      replace_node(subtree, null);\n      subtree.remove();\n    } else if (subtree.left_child === null) {\n      replace_node(subtree, subtree.right_child);\n      subtree.remove();\n    } else if (subtree.right_child === null) {\n      replace_node(subtree, subtree.left_child);\n      subtree.remove();\n    } else {\n      var successor = find_min(subtree.right_child);\n      subtree.value = successor.value;\n      remove(successor.value, successor);\n    }\n  }\n}'
        }
      ],
      model: 'pointer_machine',
      model_options: {
        fields: ['value', 'parent', 'left_child', 'right_child']
      }
    },
    {
      name: 'Linked list',
      operations: [
        {
          name: 'insert',
          code: 'function insert(value) {\n  global.root = make_node({\n    value: value,\n    next: global.root\n  });\n}'
        },
        {
          name: 'contains',
          code: 'function contains(value) {\n  var pointer = global.root;\n  while (pointer !== null) {\n    if (pointer.value === value) {\n      return true;\n    }\n    pointer = pointer.next;\n  }\n  return false;\n}'
        },
        {
          name: 'remove',
          code: 'function remove(value) {\n  if (global.root !== null) {\n    if (global.root.value === value) {\n      var temp = global.root;\n      global.root = global.root.next;\n      temp.remove();\n      return;\n    }\n  }\n  var pointer = global.root;\n  while (pointer.next !== null) {\n    if (pointer.next.value === value) {\n      var temp = pointer.next;\n      pointer.next = pointer.next.next;\n      temp.remove();\n      return;\n    }\n    pointer = pointer.next;\n  }\n  throw Error("Value does not exist: " + String(value) + ".");\n}'
        }
      ],
      model: 'pointer_machine',
      model_options: {
        fields: ['value', 'next']
      }
    },
    {
      name: 'AVL Tree',
      model: 'pointer_machine',
      model_options: {
        fields: ['value', 'parent', 'left_child', 'right_child']
      },
      operations: [
        {
          name: 'insert',
          code: 'function insert(value, subtree) {\n  if (subtree === undefined) {\n    if (global.root === null) {\n      global.root = make_node({ value: value });\n      return;\n    }\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    subtree = make_node({ value: value });\n    return;\n  }\n  if (value < subtree.value) {\n    if (subtree.left_child === null) {\n      subtree.left_child = make_node({ value: value, parent: subtree });\n    } else {\n      insert(value, subtree.left_child);\n    }\n  } else if (value > subtree.value) {\n    if (subtree.right_child === null) {\n      subtree.right_child = make_node({ value: value, parent: subtree });\n    } else {\n      insert(value, subtree.right_child);\n    }\n  } else {\n    throw Error("Value already exists: " + String(value) + ".");\n  }\n  balance(subtree);\n}'
        },
        {
          name: 'right_rotate',
          code: 'function right_rotate(subtree) {\n  var left = subtree.left_child;\n  subtree.left_child = left.right_child;\n  if (left.right_child !== null) {\n    left.right_child.parent = subtree;\n  }\n  replace_node(subtree, left);\n  left.right_child = subtree;\n  subtree.parent = left;\n}'
        },
        {
          name: 'left_rotate',
          code: 'function left_rotate(subtree) {\n  var right = subtree.right_child;\n  subtree.right_child = right.left_child;\n  if (right.left_child !== null) {\n    right.left_child.parent = subtree;\n  }\n  replace_node(subtree, right);\n  right.left_child = subtree;\n  subtree.parent = right;\n}'
        },
        {
          name: 'get_balance',
          code: 'function get_height(subtree) {\n  if (subtree === null) {\n    return 0;\n  } else {\n    return 1 + Math.max(get_height(subtree.left_child), get_height(subtree.right_child));\n  }\n}\n\nfunction get_balance(subtree) {\n  if (subtree === null) {\n    return 0;\n  }\n  return get_height(subtree.left_child) - get_height(subtree.right_child);\n}'
        },
        {
          name: 'replace_node',
          code: 'function replace_node(old_node, new_node) {\n  if (old_node === global.root) {\n    global.root = new_node;\n    if (new_node !== null) {\n      new_node.parent = null;\n    }\n  } else {\n    if (old_node.parent.left_child === old_node) {\n      old_node.parent.left_child = new_node;\n    } else {\n      old_node.parent.right_child = new_node;\n    }\n    if (new_node !== null) {\n      new_node.parent = old_node.parent;\n    }\n    old_node.parent = null;\n  }\n}'
        },
        {
          name: 'balance',
          code: 'function balance(subtree) {\n  if (get_balance(subtree) > 1) {\n    if (subtree.value < subtree.left_child.value) {\n      left_rotate(subtree.left_child);\n    }\n    right_rotate(subtree);\n  }\n  else if (get_balance(subtree) < -1) {\n    if (subtree.value > subtree.right_child.value) {\n      right_rotate(subtree.right_child);\n    }\n    left_rotate(subtree);\n  }\n}'
        },
        {
          name: 'remove',
          code: 'function find_min(subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Empty tree");\n  }\n  if (subtree.left_child === null) {\n    return subtree;\n  } else {\n    return find_min(subtree.left_child);\n  }\n}\n\nfunction remove(value, subtree) {\n  if (subtree === undefined) {\n    subtree = global.root;\n  }\n  if (subtree === null) {\n    throw Error("Value does not exist: " + String(value) + ".");\n  }\n  if (value < subtree.value) {\n    remove(value, subtree.left_child);\n  } else if (value > subtree.value) {\n    remove(value, subtree.right_child);\n  } else {\n    var check_this = subtree.parent;\n    if (subtree.left_child === null && subtree.right_child === null) {\n      replace_node(subtree, null);\n      subtree.remove();\n    } else if (subtree.left_child === null) {\n      replace_node(subtree, subtree.right_child);\n      subtree.remove();\n    } else if (subtree.right_child === null) {\n      replace_node(subtree, subtree.left_child);\n      subtree.remove();\n    } else {\n      var successor = find_min(subtree.right_child);\n      subtree.value = successor.value;\n      remove(successor.value, successor);\n    }\n    if (check_this && get_balance(check_this) > 1) {\n      if (get_balance(check_this.left_child) < 0) {\n        left_rotate(check_this.left_child);\n      }\n      right_rotate(check_this);\n    }\n    if (check_this && get_balance(check_this) < -1) {\n      if (get_balance(check_this.right_child) > 0) {\n        right_rotate(check_this.right_child);\n      }\n      left_rotate(check_this);\n    }\n  }\n}'
        }
      ]
    },
    {
      name: 'Splay tree',
      model: 'pointer_machine',
      model_options: {
        fields: ['value', 'parent', 'left_child', 'right_child']
      }
      operations: [
        {
         name: 'left_rotate',
         code: 'function left_rotate(subtree) {\n  var right = subtree.right_child;\n  subtree.right_child = right.left_child;\n  if (right.left_child) {\n    right.left_child.parent = subtree;\n  }\n  replace_node(subtree, right);\n  right.left_child = subtree;\n  subtree.parent = right;\n}'
        },
        {
         name: 'right_rotate',
         code: 'function right_rotate(subtree) {\n  var left = subtree.left_child;\n  subtree.left_child = left.right_child;\n  if (left.right_child) {\n    left.right_child.parent = subtree;\n  }\n  replace_node(subtree, left);\n  left.right_child = subtree;\n  subtree.parent = left;\n}'
        },
        {
         name: 'splay',
         code: 'function splay(subtree) {\n  while (global.root !== subtree) {\n    if (global.root === subtree.parent) {\n      if (subtree.parent.left_child === subtree) {\n         right_rotate(subtree.parent);\n      } else {\n        left_rotate(subtree.parent); \n      }\n    } else {\n      if (subtree.parent.left_child === subtree) {\n        if (subtree.parent.parent.left_child === subtree.parent) {\n          right_rotate(subtree.parent.parent);\n           right_rotate(subtree.parent);\n        } else {\n           right_rotate(subtree.parent);\n          left_rotate(subtree.parent);\n        }\n      } else {\n        if (subtree.parent.parent.left_child === subtree.parent) {\n          left_rotate(subtree.parent); \n          right_rotate(subtree.parent);\n        } else {\n          left_rotate(subtree.parent.parent); \n          left_rotate(subtree.parent);\n        }\n      }\n    }\n  }\n}'
        },
        {
         name: 'insert',
         code: 'function insert(value) {\n  var current_node = global.root;\n  var current_parent;\n  while (current_node !== null) {\n    current_parent = current_node;\n    if (value < current_node.value) {\n      current_node = current_node.left_child;\n    } else {\n      current_node = current_node.right_child;\n    }\n  }\n  current_node = make_node({"value": value});\n  if (current_parent) {\n    current_node.parent = current_parent;\n    if (current_node.value < current_parent.value) {\n      current_parent.left_child = current_node; \n    } else {\n      current_parent.right_child = current_node; \n    }\n  } else {\n    global.root = current_node; \n  }\n  splay(current_node);\n}'
        },
        {
         name: 'remove',
         code: 'function remove(value) {\n  var to_remove = find_node(value);\n  if (to_remove) {\n    if (to_remove.right_child !== null && to_remove.left_child === null) {\n      replace_node(to_remove, to_remove.right_child); \n    } else if (to_remove.left_child !== null && to_remove.right_child === null) {\n       replace_node(to_remove, to_remove.left_child)\n    } else if (to_remove.left_child !== null && to_remove.right_child !== null) {\n      var replacement = to_remove.right_child;\n      while (replacement.left_child !== null) {\n        replacement = replacement.left_child;\n      }\n      if (replacement.parent !== to_remove) {\n        replace_node(replacement, replacement.right_child);\n        replacement.right_child = to_remove.right_child;\n        replacement.right_child.parent = replacement;\n      }\n      replace_node(to_remove, replacement);\n      replacement.left_child = to_remove.left_child;\n      replacement.left_child.parent = replacement;\n    }\n    to_remove.remove();\n  }\n}'
        },
        {
          name: 'replace_node',
          code: 'function replace_node(old_node, new_node) {\n  if (old_node === global.root) {\n    global.root = new_node;\n    if (new_node !== null) {\n      new_node.parent = null;\n    }\n  } else {\n    if (old_node.parent.left_child === old_node) {\n      old_node.parent.left_child = new_node;\n    } else {\n      old_node.parent.right_child = new_node;\n    }\n    if (new_node !== null) {\n      new_node.parent = old_node.parent;\n    }\n    old_node.parent = null;\n  }\n}'
        },
        {
          name: 'find_node',
          code: 'function find_node(value) {\n  current_node = global.root;\n  while (current_node !== null && current_node.value !== value) {\n    if (value < current_node.value) {\n      current_node = current_node.left_child; \n    } else {\n      current_node = current_node.right_child; \n    }\n  }\n  if (current_node !== null) {\n    splay(current_node);\n    return current_node;\n  }\n  return false;\n}'
        }
      ]
    }
  ]
)])
