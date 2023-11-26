extends Tree

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")
var button_add: Texture2D = load("res://icons/Add.svg")
var button_remove: Texture2D = load("res://icons/Remove.svg")
var icon: Texture2D = load("res://icon.svg")

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)


func _ready():
	hide_root = true
	connect("moved", _move_item)
	var item = create_item() #root
	item.set_selectable(0, false)
	#set root of draw_layers - might no longer be needed
	item.add_button(0, button_add, 1)
	
	load_characters()
	
#	print("creating character tree ===========================================")
#	item = add_new_item("Players")
#	add_new_item("Jack", item)
#	add_new_item("Jim", item)
#	add_new_item("Jamie", item)
#	add_new_item("John", item)
#	add_new_item("Josh", item)
#	var item2 = add_new_item("Monsters")
#	item = add_new_item("Dragons", item2)
#	item.collapsed = true
#	add_new_item("Red Dragon", item)
#	add_new_item("Black Dragon", item)
#	item = add_new_item("Undead", item2)
#	item.collapsed = true
#	add_new_item("Skeleton", item)
#	add_new_item("Zombie", item)



func add_new_item(item_name: String, parent: TreeItem = null, new: bool = true):
	#if tree was empty, hide root
	if hide_root == false:
		hide_root = true
	print("creating item: " + item_name)
	var item
	if parent == null: 
		item = create_item(null, 0)
	else:
		item = create_item(parent, 0)
	item.set_icon(0, icon)
	item.set_icon_max_width(0, 25)
	item.set_text(0, item_name)
	item.add_button(0, button_add)
	item.add_button(0, button_remove)
	
	#create character
	if new:
		var character: Character = item.get_parent().get_meta("character")
		if character == null:
			character = Character.new()
		else:
			character = character.duplicate(true)
		item.set_meta("character", character)
		character.name = item_name
		character.tree_item = item
#		character.global = true
		character.save(true)
		#if conflict changed name
		item.set_text(0, character.name)
	
	
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
	match(shift):	
		BEFORE:
			item.move_before(to_item)
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#			layer.reparent(to_layer.get_parent()) #using disables internal
			layer.get_parent().remove_child(layer)
			to_layer.get_parent().add_child(layer, false, INTERNAL_MODE_FRONT)
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
			to_layer.add_child(layer, false, INTERNAL_MODE_FRONT)
			to_layer.move_child(layer, 0)
		AFTER:
			var next_to_item = to_item.get_next() #get next sibling of to_item
			item.move_after(to_item)
			
#			#check if moved
#			if prev_item != item.get_prev_in_tree():
#			layer.reparent(to_layer.get_parent())
			layer.get_parent().remove_child(layer)
			to_layer.get_parent().add_child(layer, false, INTERNAL_MODE_FRONT)
			to_layer.get_parent().move_child(layer, to_layer.get_index()+1) #not needed - sorted by z_index - only for saving and loading
		
#loads all characters
func load_characters():
	#locals
	var dir = DirAccess.open("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters")
	if dir != null:
		load_characters_in_dir(dir, "", null, false)
	#globals
	dir = DirAccess.open("res://saves/Characters")
	if dir != null:
		load_characters_in_dir(dir, "Global", get_root(), true)

#loads characters in dir and it's subdirs
func load_characters_in_dir(dir: DirAccess, char_name: String, parent_item: TreeItem, global: bool):
	#load character
	var item: TreeItem
	if parent_item != null:
		item = add_new_item(char_name, parent_item, false)
		var char = Character.new()
		char.load_char(dir.get_current_dir(), char_name, global, item)
		item.collapsed = true
	else:
		item = get_root()
	#subdirs
	var dirs = dir.get_directories()
	for d in dirs:
		dir.change_dir(d)
		load_characters_in_dir(dir, d, item, global)
		dir.change_dir("..")

	

