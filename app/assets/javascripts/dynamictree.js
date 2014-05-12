var animation = angular.module('animation', [])
animation.factory('animation', ['$window', function(){
var container = $("#tree-container");
var width = 600;
var height = 600;
var tree = d3.layout.tree()
    .size([width - 60, height - 60]);

var root = {fields:{"field1": 0, "field2": 3}, id:0},
    nodes = tree(root);
    extra_links = [];
root.parent = root;
root.px = root.x;
root.py = root.y;
var diagonal = d3.svg.diagonal().projection(function(d) { return [d.x + 25, d.y] });

var svg = d3.select(document.getElementById("tree-container")).append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")
    .attr("id", "g")
    .attr("transform", "translate(10,10)");

var node = svg.selectAll(".node"),
    link = svg.selectAll(".link");
var num_fields = 0;
var field_list = [];
for (field in nodes[0].fields){
	num_fields++;
	field_list.push(field);
}

var counter = 1;
var duration = 750;
//    timer = setInterval(update, duration);
//    [node, data, "add", fieldfromparent]
//    [node, notused, "remove"]
//    [node, field, "set_field", value]
//    [node, node2, "add_child"]
//    [node, node2, "remove_child"]
  
//var updates = [[0, {"field1": 3, "field2": 5}, "add", "field2"], [1, {"field1": 6, "field2": 2}, "add", "field1"], [1, 10, "set_field", "field2"], [0, {"field1": 5, "field2": 7}, "add", "field1"], [2, 3, "add_child", "field2"], [1, 3, "remove_child"],[2, 3, "add_child", "field2"],[2, {"field1": 8, "field2": 16}, "add", "field2"], [3, 4, "add_child", "field1"], [4, null, "remove"],[1, {"field1": 7, "field2": -2}, "add", "field1"], [2, null, "remove"]] 
//update(updates);
//var updates = [[0, {"field1": 2, "field2": 7}, "add", "field2"], [1, {"field1":6, "field2": 3}, "add", "field1"], [1, {"field1": 1, "field2": 20}, "add", "field2"], [0, 1, "remove_child"]]
var index = 0
setInterval(function(){update(updates, index); index++;}, duration);
function test(){ console.log("TEST") }
function update(updates, index, root) {
//  node = node.data(tree.nodes(root), function(d) { return d.id; });
//  link = link.data(tree.links(nodes), function(d) { return d.source.id + "-" + d.target.id; });


  if (!index){
	index = 0;
  }
  if (index >= updates.length){
//	return;
	throw Error("index out of bounds");
  }
  var our_node = nodes[updates[index][0]];
  var data = updates[index][1];
  // new node to be added
  if (updates[index][2] == "add"){
	  var n = {id: counter,
	      parent:our_node,
	      parent_list: [our_node],
	      fields:data};
	      if (our_node){
		if (our_node.children) our_node.children.push(n); else our_node.children = [n];
	      }
	  counter++;
	  nodes.push(n);
	  // Recompute the layout and data join.
	  node = node.data(tree.nodes(root), function(d) { return d.id; });
	  link = link.data(tree.links(nodes).concat(extra_links), function(d) { return d.source.id + "-" + d.target.id; }); 
	  // Add entering nodes in the parent’s old position.
	  var square_size = 50;
	  var nodeEnter = node.enter().append("g")
		.attr("class", "node")
		.attr("id", function(d){return "id"+d.id;});
      		fields_seen = 0;

  	  for (field in nodes[0].fields){
		  nodeEnter.append("rect")
	//		    .attr("class", "n dt 2014-05-09 23:07:57 -0400
//
//		    e")
	     	    .attr("width", square_size)
	      	    .attr("height", square_size)
	            .attr("x", function(d) { return d.parent.px + 50*fields_seen; })
	            .attr("y", function(d) { return d.parent.py; })
		    .attr("square", true)
		    .attr("offset", function(d) { return 50*fields_seen; })
		    .attr("fill", "white")
		    .attr("stroke", "black")
	    	    //            .attr("id", function(d) { return "id" + d.id; })
		    .attr("class", function(d){ return "node"+d.id; });
//		    .text(function (d) { return d.id; });
	            fields_seen++;
		  nodeEnter.append("text")
		      .attr("dx", function(d) { return -25 + 50*fields_seen; })
		      .attr("dy", 25)
		      .style("text-anchor", function(d) { return "start" })
//		      .attr("id", function (d) { return "textid" + d.id; })
		      .attr("class", function(d) { return "node"+d.id })
		      .attr("field", function(d) { return field; })
		      .text(function(d) { return d.fields[field] });

  	  }
	  // Add entering links in the parent’s old position.
	 link.enter().insert("path", ".node")
	      .attr("class", "link")
	      .attr("child_node", function(d) { return "link" + d.target.id })
	      .attr("parent_node", function(d) { return "link" + d.source.id })
	      .attr("offset", function(d) { return field_list.indexOf(updates[index][3])*50; }) 
	      .attr("d", function(d) {
		var diagonal = d3.svg.diagonal().projection(function(d) { return [d.x + 25 + field_list.indexOf(updates[index][3])*50, d.y] });

		var o = {x: d.source.px, y: d.source.py};
		return diagonal({source: o, target: o});
	      }); 
  } else if (updates[index][2] == "remove"){
	var nodeExit =node.exit().transition()
		.duration(duration)
 	      .attr("x", function(d) { return d.parent.px; }).remove();
	nodeExit.select("rect")
		.attr("width", 25);
	nodeExit.select("text")
		.attr("dy", 3); 
	link.exit().remove();
	// remove ourselves from the children lists of all our parents
	for (var p = 0; p < our_node.parent_list.length; p++){	
		var node_to_delete = null;
		for (var i = 0; i < our_node.parent_list[p].children.length; i++){
			if (our_node.parent_list[p].children[i].id == our_node.id){
				node_to_delete = i;
			}
		}
		our_node.parent_list[p].children.splice(node_to_delete, 1);
	}
	if (our_node.children){
		for (var c = 0; c < our_node.children.length; c++){	
			var node_to_delete = null;
			for (var i = 0; i < our_node.children[c].parent_list.length; i++){
				if (our_node.children[c].parent_list[i].id == our_node.id){
					node_to_delete = i;
				}
			}
			our_node.children[c].parent_list.splice(node_to_delete, 1);
			if (our_node.children[c].parent.id == our_node.id && our_node.children[c].parent_list.length != 0){
				our_node.children[c].parent = our_node.children.parent_list[0];
			}
		}
	}
	new_extra_links = []
	for (var l = 0; l < extra_links.length; l++){	
		if (extra_links[l].source.id != our_node.id && extra_links[l].target.id != our_node.id){
			new_extra_links.push(extra_links[l]);
		}
	}
	extra_links = new_extra_links;
	for (var l = 0; l < extra_links.length; l++){	
	}

	  node = node.data(tree.nodes(root), function(d) { return d.id; });
	  link = link.data(tree.links(nodes).concat(extra_links), function(d) { return d.source.id + "-" + d.target.id; });
	  var nodeExit =node.exit().transition()
		.duration(duration)
		.attr("cx", function(d) { return d.parent.px; }).remove();
	  nodeExit.select("circle")
		.attr("r", 4);
	nodeExit.select("text")
		.attr("dy", 3); 
  } else if (updates[index][2] == "set_field"){
	var field = updates[index][3];
	our_node.fields[field] = data;
	d3.selectAll(".node"+our_node.id).filter("[field="+updates[index][3]+"]").text(data);
  } else if (updates[index][2] == "add_child"){
	var child_node = nodes[updates[index][1]];
	extra_links.push({source: our_node, target: child_node, parent_node: "link"+our_node.id, child_node: "link"+child_node.id});
 	child_node.parent_list.push(our_node);
	if (our_node.children){
		our_node.children.push(child_node);
	} else { our_node.children = [child_node]; }
 	link = link.data(tree.links(nodes).concat(extra_links), function(d) { return d.source.id + "-" + d.target.id; }); 
	 link.enter().insert("path", ".node")
	      .attr("class", "link")
	      .attr("child_node", function(d) { return "link" + d.target.id })
	      .attr("parent_node", function(d) { return "link" + d.source.id })
	      .attr("offset", function(d) { return field_list.indexOf(updates[index][3])*50; }) 
	      .attr("d", function(d) {
		var diagonal = d3.svg.diagonal().projection(function(d) { return [d.x + 50 + field_list.indexOf(updates[index][3])*50, d.y] });

		var o = {x: d.source.px, y: d.source.py};
		return diagonal({source: o, target: o});
	      }); 

  } else if (updates[index][2] == "remove_child"){
	var child_node = nodes[updates[index][1]];
	var link_to_delete = null;
	for (var i = 0; i < extra_links.length; i++){
		if (extra_links[i].source.id == our_node.id && extra_links[i].target.id == child_node.id){
			link_to_delete = i;
		}
	}
	extra_links.splice(link_to_delete, 1);
	var link_in_parentlist = null;
	for (var i = 0; i < child_node.parent_list.length; i++){
		if (child_node.parent_list[i].id == our_node.id){
			link_in_parentlist = i;
		}
	}	
	child_node.parent_list.splice(link_in_parentlist, 1);
	var link_in_children = null;
	for (var i = 0; i < our_node.children.length; i++){
		if (our_node.children[i].id == child_node.id){
			link_in_children = i;
		}
	}	
	our_node.children.splice(link_in_children, 1);
	  node = node.data(tree.nodes(root), function(d) { return d.id; });
//	  link = link.data(tree.links(nodes).concat(extra_links), function(d) { return d.source.id + "-" + d.target.id; });
  }

  // Transition nodes and links to their new positions.
  var t = svg.transition()
      .duration(duration);

  links_list = t.selectAll(".link");
  for (i in links_list[0]){
	var new_pos = d3.svg.diagonal().projection(function(d){ return [d.x + 25 + 1*links_list[0][i].getAttribute("offset"), d.y]});
	var selection = t.selectAll("[parent_node="+links_list[0][i].getAttribute("parent_node")+"]").filter("[child_node="+links_list[0][i].getAttribute("child_node")+"]");
	selection.attr("d", new_pos);
	}
  t.selectAll(".node").attr("x", function(d) { return d.px = d.x; })
      .attr("y", function(d) { return d.py = d.y; });
  t.selectAll("text").attr("x", function(d) { return d.px = d.x; })
      .attr("y", function(d) { return d.py = d.y; });


  var rect = d3.selectAll("#g .node rect");
  rect.transition().duration(duration)
  // t.selectAll("[square=true]")
      .attr("x", function(d) { return d.x+1*this.getAttribute("offset"); })
      .attr("y", function(d) { return d.py = d.y; })

  if (updates[index][2] == "remove"){
	parented_links = d3.selectAll("[parent_node=link"+our_node.id+"]");
	if (parented_links){
		for (var l = 0; l < parented_links[0].length; l++){
			parented_links[0][l].remove();
		}
	}
	childed_links = d3.selectAll("[child_node=link"+our_node.id+"]");
	if (childed_links){
		for (var l = 0; l < childed_links[0].length; l++){
			childed_links[0][l].remove();
		}
	}
	d3.select("#id"+our_node.id)[0][0].remove();
   } else if (updates[index][2] == "remove_child"){
	var the_link = d3.selectAll("[parent_node=link"+our_node.id+"]").filter("[child_node=link"+nodes[updates[index][1]].id+"]");
   	   the_link[0][0].remove();
   }

}
}]);
