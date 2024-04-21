#Author: Vladimír Horák
#Desc:
#Script controlling tree structure GUI representing map layers

extends Tree

var button_visible: Texture2D = preload("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = preload("res://icons/GuiVisibilityHidden.svg")
var button_DM: Texture2D = preload("res://icons/DM.png")
var button_DM_not: Texture2D = preload("res://icons/DM_not.png")
var button_players: Texture2D = preload("res://icons/Players.png")
var button_players_not: Texture2D = preload("res://icons/Players_not.png")
var button_add: Texture2D = preload("res://icons/Add.svg")
var button_remove: Texture2D = preload("res://icons/Remove.svg")
var button_light: Texture2D = preload("res://icons/LightOccluder2D.svg")
var layer = preload("res://components/draw.tscn")

var draw_root

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)

func _enter_tree():
	create_root()
	if Globals.lobby.check_is_server():
		size.x = 320


func _ready():
	pass
	
func create_root():
	hide_root = false
	connect("moved", _move_item)
	
	var item = create_item() #root
	item.set_selectable(0, false)
	#set root of draw_layers - might no longer be needed
	draw_root = $"../../../Draw/Layers"
	item.set_meta("draw_layer", draw_root) 
	if Globals.lobby.check_is_server():
		item.add_button(0, button_add, 3)
	else:
		hide_root = true
	

func add_new_item(item_name: String, parent: TreeItem = null, existing_node: Node2D = null, end = false):
	#if tree was empty, hide root
	if hide_root == false:
		hide_root = true
	var index = 0 #add at start of children
	if end:
		index = -1 #add to end of children
	var item
	if parent == null: 
		item = create_item(null, index)
	else:
		item = create_item(parent, index)
	item.set_text(0, item_name)
	
	var draw_layer
	
	if existing_node == null:
		draw_layer = Node2D.new()
		#set meta for recreation after loading
		draw_layer.set_meta("item_name", item_name)
		draw_layer.set_meta("type", "layer")
		draw_layer.set_meta("visibility", 1)
		draw_layer.set_meta("player_layer", 1)
		draw_layer.set_meta("DM", 0)

		draw_layer.set_meta("tree_item", item)
		
		draw_layer.z_as_relative = false
		item.set_meta("draw_layer", draw_layer)
		if parent == null:
			draw_root.add_child(draw_layer)
			draw_root.move_child(draw_layer, 0)
		else:
			parent.get_meta("draw_layer").add_child(draw_layer)
			parent.get_meta("draw_layer").move_child(draw_layer, 0)
		
		draw_layer.set_owner(draw_root)
		Globals.draw_comp.create_object_on_remote_peers(draw_layer)
		
		change_z_indexes()
	
	else:
		draw_layer = existing_node
		existing_node.z_as_relative = false
		existing_node.set_meta("tree_item", item)
		item.set_meta("draw_layer", existing_node)
	if not Globals.lobby.check_is_server() and (not existing_node.get_meta("player_layer") or existing_node.get_meta("DM") or not existing_node.get_meta("visibility")): #hide layer tree_item for player:
		item.visible = false
	if Globals.lobby.check_is_server():
		if draw_layer.get_meta("visibility"):
			item.add_button(0, button_visible)
		else:
			item.add_button(0, button_hidden)
		if draw_layer.get_meta("DM"):
			item.add_button(0, button_DM)
		else:
			item.add_button(0, button_DM_not)
		if draw_layer.get_meta("player_layer"):
			item.add_button(0, button_players)
		else:
			item.add_button(0, button_players_not)
		item.add_button(0, button_add)
		item.add_button(0, button_remove)
		item.add_button(0, button_light)
		
#	var draw_layer = Node2D.new()
#	draw_layer.z_as_relative = false
#	item.set_meta("draw_layer", draw_layer)
#	draw_root.add_child(draw_layer)
#	if parent == null:
#		draw_root.move_child(draw_layer, -2)
#	else:
#		draw_root.move_child(draw_layer, item.get_parent().get_meta("draw_layer").get_index())
#	print("created item = " + item_name + ": " + str(draw_layer.get_index()))
	return item

#@rpc("any_peer", "call_remote", "reliable")
#func create_layer_on_remote_peers():
	#pass
	
@rpc("any_peer", "call_remote", "reliable")
func move_layer_on_remote_peers(node_path, to_node_path, shift):
	_move_item(get_node(node_path).get_meta("tree_item"), get_node(to_node_path).get_meta("tree_item"), shift, true)

@rpc("any_peer", "call_remote", "reliable")
func synch_layer_property(node_path, property_dict):
	var layer = get_node(node_path)
	var item = layer.get_meta("tree_item")
	for property_key in property_dict:
		if property_key == "item_name":
			layer.set_meta("item_name", property_dict[property_key])
		if property_key == "visibility":
			layer.set_meta("visibility", property_dict[property_key])
		if property_key == "DM":
			layer.set_meta("DM", property_dict[property_key])
		if property_key == "light":
			pass
	

func is_child_of(child_treeitem, parent_treeitem):
	if child_treeitem == parent_treeitem:
		return false
	var root = get_root()
	while child_treeitem != root:
		child_treeitem = child_treeitem.get_parent()
		if child_treeitem == parent_treeitem:
			return true
	return false

func _get_drag_data(_item_position):
	if not Globals.lobby.check_is_server():
		return
	set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
	var selected = get_selected()
	if not selected:
		return
	var preview = Label.new()
	preview.text = selected.get_text(0)
	set_drag_preview(preview)
	return selected


func _can_drop_data(_item_position, data):
	if not Globals.lobby.check_is_server():
		return false
	return data is TreeItem


func _drop_data(item_position, item):
	if not Globals.lobby.check_is_server():
		return
	var to_item = get_item_at_position(item_position)
	var shift = get_drop_section_at_position(item_position)
	
	Globals.drag_drop_canvas_layer.layer = -1
	emit_signal('moved', item, to_item, shift)


func _move_item(item: TreeItem, to_item: TreeItem, shift: int, remote = false):
	if item == null or to_item == null:
		return
	if item == to_item:
		return
	if is_child_of(to_item, item):
		return #dragging parent on child
#	var prev_item = item.get_prev_in_tree() # to check if items were moved
	var to_layer = to_item.get_meta("draw_layer")
	var layer = item.get_meta("draw_layer")
	if remote == false: #called on this peer - update other peers
		move_layer_on_remote_peers.rpc(get_path_to(layer), get_path_to(to_layer), shift)
	print_indexes()
	match(shift):	
		BEFORE:
			item.move_before(to_item)
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#			layer.reparent(to_layer.get_parent()) #using disables internal
			layer.get_parent().remove_child(layer)
			to_layer.get_parent().add_child(layer)
			to_layer.get_parent().move_child(layer, to_layer.get_index()) #not needed - sorted by z_index - only for saving and loading
		ON:
			if to_item.get_child_count() == 0:
				var dummy = create_item(to_item)
				item.move_before(dummy)
				to_item.remove_child(dummy)
				dummy.free()
			else:
				item.move_before(to_item.get_first_child())
				
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#			layer.reparent(to_layer)
			layer.get_parent().remove_child(layer)
			to_layer.add_child(layer)
			to_layer.move_child(layer, 0)
		AFTER:
			var next_to_item = to_item.get_next() #get next sibling of to_item
			item.move_after(to_item)
			
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#			layer.reparent(to_layer.get_parent())
			layer.get_parent().remove_child(layer)
			to_layer.get_parent().add_child(layer)
			to_layer.get_parent().move_child(layer, to_layer.get_index()+1) #not needed - sorted by z_index - only for saving and loading
		
#	var prev_item = item.get_prev_in_tree() # to check if items were moved
#	var to_layer = to_item.get_meta("draw_layer")
#	var layer = item.get_meta("draw_layer")
#	print_indexes()
#	match(shift):	
#		BEFORE:
#			item.move_before(to_item)
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#				draw_root.move_child(layer, to_layer.get_index())
#				#children
#				var next_item = item.get_next() #get next sibling
#				while true:
#					item = item.get_next_in_tree() #iterate over all in order
#					if item == next_item:
#						break
#					layer = item.get_meta("draw_layer")
#					draw_root.move_child(layer, to_layer.get_index())
#		ON:
#			if to_item.get_child_count() == 0:
#				var dummy = create_item(to_item)
#				item.move_before(dummy)
#				to_item.remove_child(dummy)
#			else:
#				item.move_before(to_item.get_first_child())
#
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#				draw_root.move_child(layer, to_layer.get_index()-1)
#				#children
#				var i = layer.get_index()
#				var next_item = item.get_next() #get next sibling
#				while true:
#					item = item.get_next_in_tree() #iterate over all in order
#					if item == next_item:
#						break
#					layer = item.get_meta("draw_layer")
#					draw_root.move_child(layer, i-1)
#					i = layer.get_index()
#		AFTER:
#			var next_to_item = to_item.get_next() #get next sibling of to_item
#			item.move_after(to_item)
#
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#				if next_to_item != null:
#					draw_root.move_child(layer, next_to_item.get_index()+1)
#					#children
#					var next_item = item.get_next() #get next sibling
#					while true:
#						item = item.get_next_in_tree() #iterate over all in order
#						if item == next_item:
#							break
#						layer = item.get_meta("draw_layer")
#						draw_root.move_child(layer, next_to_item.get_index()+1)
#				else:
#					draw_root.move_child(layer, 1)
#					#children
#					var next_item = item.get_next() #get next sibling
#					while true:
#						item = item.get_next_in_tree() #iterate over all in order
#						if item == next_item:
#							break
#						layer = item.get_meta("draw_layer")
#						draw_root.move_child(layer, 1)
	change_z_indexes()
	print_indexes()
	return true
	
func print_indexes():
	var item = self.get_root()
	item = item.get_next_in_tree()
	while item != null:
		print("item = " + item.get_text(0) + ": " + str(item.get_meta("draw_layer").z_index))
		item = item.get_next_in_tree()
	print ("	||| END |||	")
	
func change_z_indexes():
	var item = self.get_root().get_next_in_tree()
	var z = 4095
	while item != null:
		item.get_meta("draw_layer").set_z_index(z)
		z -= 1
		item = item.get_next_in_tree()
		
		
#add child based on existing layer
func load_self_and_children(node: Node2D, parent: TreeItem):
	var item = add_new_item(node.get_meta("item_name"), parent, node, true)
	set_light_on_self_and_children(node, node.light_mask)
	for child in node.get_children(true):
		if child.has_meta("item_name"):
			load_self_and_children(child, item)
	
	
func set_light_on_self_and_children(node, mask):
	if node.is_class("CanvasItem"):
		node.light_mask = mask
		if node is PointLight2D:
			if not node.has_meta("fov"): #not fov light
				node.range_item_cull_mask = mask
			node.shadow_item_cull_mask = mask
		if node is LightOccluder2D:
			node.occluder_light_mask = mask
		for child in node.get_children():
			if child.has_meta("item_name"):
				continue
			set_light_on_self_and_children(child, mask)
			
			
#returns array of descendant treeitems
func get_descendants(treeitem: TreeItem):
	var array = []
	var final = treeitem.get_next()
	treeitem = treeitem.get_next_in_tree()
	while treeitem != final:
		array.append(treeitem)
		treeitem = treeitem.get_next_in_tree()
	return array
		
	


