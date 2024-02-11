#Author: Vladimír Horák
#Desc:
#Script controlling tree structure GUI representing map layers

extends Tree

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")
var button_add: Texture2D = load("res://icons/Add.svg")
var button_remove: Texture2D = load("res://icons/Remove.svg")
var button_light: Texture2D = load("res://icons/LightOccluder2D.svg")
var layer = preload("res://componens/draw.tscn")

@onready var draw_root = $"../../../Draw/Layers"

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)


func _ready():
	hide_root = true
	connect("moved", _move_item)
	if Globals.new_map.saved_layers == null:
		var item = create_item() #root
		item.set_selectable(0, false)
		#set root of draw_layers - might no longer be needed
		item.set_meta("draw_layer", draw_root) 
		item.add_button(0, button_add, 1)
	
		print("tree not loaded")
		item = add_new_item("layer_group_1")
		item = add_new_item("layer_1", item)
		item = add_new_item("layer_2", item)
		item = add_new_item("layer_3", item)
		item = add_new_item("layer_4", item)
		item = add_new_item("layer_5", item)
		item = add_new_item("layer_group_2")
		add_new_item("layer_6", item)
		add_new_item("layer_7", item)
		add_new_item("layer_8", item)
		add_new_item("layer_9", item)
		add_new_item("layer_10", item)
		
	else:
		print("tree loaded")

func add_new_item(item_name: String, parent: TreeItem = null):
	#if tree was empty, hide root
	if hide_root == false:
		hide_root = true
	var item
	if parent == null: 
		item = create_item(null, 0)
	else:
		item = create_item(parent, 0)
	item.set_text(0, item_name)
	item.add_button(0, button_visible)
	item.add_button(0, button_add)
	item.add_button(0, button_remove)
	item.add_button(0, button_light)
	
	var draw_layer = Node2D.new()
	#set meta for recreation after loading
	draw_layer.set_meta("item_name", item_name)
	draw_layer.set_meta("visibility", 0)
	
	draw_layer.z_as_relative = false
	item.set_meta("draw_layer", draw_layer)
	if parent == null:
		draw_root.add_child(draw_layer)
		draw_root.move_child(draw_layer, 0)
	else:
		parent.get_meta("draw_layer").add_child(draw_layer)
		parent.get_meta("draw_layer").move_child(draw_layer, 0)
	
	draw_layer.set_owner(draw_root)
	
	change_z_indexes()
	
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


func _get_drag_data(_item_position):
	set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
	var selected = get_selected()
	if not selected:
		return
	var preview = Label.new()
	preview.text = selected.get_text(0)
	set_drag_preview(preview)
	return selected


func _can_drop_data(_item_position, data):
	return data is TreeItem


func _drop_data(item_position, item):
	var to_item = get_item_at_position(item_position)
	var shift = get_drop_section_at_position(item_position)
	
	emit_signal('moved', item, to_item, shift)


func _move_item(item: TreeItem, to_item: TreeItem, shift: int):
	if item == null or to_item == null:
		return
	if item == to_item:
		return
		
#	var prev_item = item.get_prev_in_tree() # to check if items were moved
	var to_layer = to_item.get_meta("draw_layer")
	var layer = item.get_meta("draw_layer")
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
	var item = create_item(parent)
	item.set_meta("draw_layer", node)
	var meta = node.get_meta("item_name")
	if meta != null:
		item.set_text(0, node.get_meta("item_name"))
	if parent != null: #non root have multiple buttons
		item.add_button(0, button_visible)
		if not node.visible:
			item.set_button(0, 0, button_hidden)
		item.add_button(0, button_add)
		item.add_button(0, button_remove)
		item.add_button(0, button_light)
	else: #root has only one button
		item.add_button(0, button_add, 1)
		item.set_selectable(0, false)
	
	for child in node.get_children(true):
		if child.has_meta("item_name"):
			load_self_and_children(child, item)
	
	
func set_light_on_self_and_children(node, mask):
	if node.is_class("CanvasItem"):
		node.light_mask = mask
		if node is PointLight2D:
			if not node.has_meta("fov"): #fov light
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
		
	


