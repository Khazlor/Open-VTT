extends Tree

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")
var layer = preload("res://componens/draw.tscn")

@onready var draw_root = $"../../../Draw"

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)


func _ready():
	var item = create_item() #root
	hide_root = true
	
	#set root of draw_layers
	item.set_meta("draw_layer", draw_root) 
	
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
	
	connect("moved", _move_item)


func add_new_item(item_name: String, parent: TreeItem = null):
#	var selected = get_selected()
	var item
	if parent == null: 
		item = create_item(null, 0)
	else:
		item = create_item(parent, 0)
	item.set_text(0, item_name)
	item.add_button(0, button_visible)
	
	var draw_layer = Node2D.new()
	item.set_meta("draw_layer", draw_layer)
	draw_root.add_child(draw_layer)
	if parent == null:
		draw_root.move_child(draw_layer, -2)
	else:
		draw_root.move_child(draw_layer, item.get_parent().get_meta("draw_layer").get_index())
	print("created item = " + item_name + ": " + str(draw_layer.get_index()))
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
	var prev_item = item.get_prev_in_tree() # to check if items were moved
	var to_layer = to_item.get_meta("draw_layer")
	var layer = item.get_meta("draw_layer")
	print_indexes()
	match(shift):	
		BEFORE:
			item.move_before(to_item)
			#check if moved
			if prev_item != item.get_prev_in_tree():
				draw_root.move_child(layer, to_layer.get_index())
				#children
				var next_item = item.get_next() #get next sibling
				while true:
					item = item.get_next_in_tree() #iterate over all in order
					if item == next_item:
						break
					layer = item.get_meta("draw_layer")
					draw_root.move_child(layer, to_layer.get_index())
		ON:
			if to_item.get_child_count() == 0:
				var dummy = create_item(to_item)
				item.move_before(dummy)
				to_item.remove_child(dummy)
			else:
				item.move_before(to_item.get_first_child())
				
			#check if moved
			if prev_item != item.get_prev_in_tree():
				draw_root.move_child(layer, to_layer.get_index()-1)
				#children
				var i = layer.get_index()
				var next_item = item.get_next() #get next sibling
				while true:
					item = item.get_next_in_tree() #iterate over all in order
					if item == next_item:
						break
					layer = item.get_meta("draw_layer")
					draw_root.move_child(layer, i-1)
					i = layer.get_index()
		AFTER:
			var next_to_item = to_item.get_next() #get next sibling of to_item
			item.move_after(to_item)
			
			#check if moved
			if prev_item != item.get_prev_in_tree():
				if next_to_item != null:
					draw_root.move_child(layer, next_to_item.get_index()+1)
					#children
					var next_item = item.get_next() #get next sibling
					while true:
						item = item.get_next_in_tree() #iterate over all in order
						if item == next_item:
							break
						layer = item.get_meta("draw_layer")
						draw_root.move_child(layer, next_to_item.get_index()+1)
				else:
					draw_root.move_child(layer, 1)
					#children
					var next_item = item.get_next() #get next sibling
					while true:
						item = item.get_next_in_tree() #iterate over all in order
						if item == next_item:
							break
						layer = item.get_meta("draw_layer")
						draw_root.move_child(layer, 1)
	print_indexes()
	return true
	
func print_indexes():
	var item = self.get_root()
	item = item.get_next_in_tree()
	while item != null:
		print("item = " + item.get_text(0) + ": " + str(item.get_meta("draw_layer").get_index()))
		item = item.get_next_in_tree()
	print ("	||| END |||	")

