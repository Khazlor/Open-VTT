#Author: Vladimír Horák
#Desc:
#Script for controlling tree structure with list of characters

extends Tree

var button_edit: Texture2D = preload("res://icons/Edit.svg")
var button_add: Texture2D = preload("res://icons/Add.svg")
var button_remove: Texture2D = preload("res://icons/Remove.svg")
var icon: Texture2D = preload("res://icon.svg")

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)

var global_item: TreeItem

func _ready():
	Globals.char_tree = self
	hide_root = true
	connect("moved", _move_item)
	if multiplayer.has_multiplayer_peer() and not Globals.lobby.check_is_server():  #multiplayer - client
		return
	var item = create_item() #root
	item.set_selectable(0, false)
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
	var item
	if parent == null: 
		item = create_item(null, 0)
	else:
		item = create_item(parent, 0)
	item.set_icon(0, icon)
	item.set_icon_max_width(0, 25)
	item.set_text(0, item_name)
	item.add_button(0, button_edit)
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
		if is_ancestor(global_item, item):
			character.global = true
		else:
			character.global = false
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


func is_ancestor(ancestor: TreeItem, descendant: TreeItem):
	while descendant != null:
		descendant = descendant.get_parent()
		if descendant == ancestor:
			return true
	return false

func _get_drag_data(_item_position):
	#place drag and drop layer on top - in case of dragging to map
	Globals.drag_drop_canvas_layer.layer = 2
	
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
	
	Globals.drag_drop_canvas_layer.layer = -1
	emit_signal('moved', item, to_item, shift)


func _move_item(item: TreeItem, to_item: TreeItem, shift: int):
	if item == null or to_item == null:
		return
	if item == to_item:
		return
		
	var to_character = to_item.get_meta("character")
	var character = item.get_meta("character")
	if character == null: #dragging main "folders"
		return
	match(shift):	
		BEFORE:
			#move in folder
			var path = character.get_path_to_save()
			if to_character == null: #drag on main folder - cannot drag before
				return
			var to_path = to_character.get_path_to_save(false) + character.name
			if path == to_path:
				return
			#resolve file conflict
			var path_old = to_path
			var i = 0
			while DirAccess.dir_exists_absolute(to_path):
				i += 1
				to_path = path_old + "_" + str(i)
			if i != 0:
				character.name = character.name + "_" + str(i)
				item.set_text(0, character.name)
			print("move from: " + path + " to: " + to_path)
			
			DirAccess.rename_absolute(path, to_path)
			character.global = to_character.global
			
			#move in tree
			item.move_before(to_item)
			
		ON:
			#move in folder
			
			var path = character.get_path_to_save()
			var to_path
			if to_character != null: #drag on created character
				to_path = to_character.get_path_to_save() + "/" + character.name
			else:  #drag on main folder
				if to_item.get_text(0) == "Globals":
					to_path = Globals.base_dir_path + "/saves/Characters/" + character.name
				else:
					to_path = Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters/" + character.name
			if path == to_path:
				return
			#resolve file conflict
			var path_old = to_path
			var i = 0
			while DirAccess.dir_exists_absolute(to_path):
				i += 1
				to_path = path_old + "_" + str(i)
			if i != 0:
				character.name = character.name + "_" + str(i)
				item.set_text(0, character.name)
			print("move from: " + path + " to: " + to_path)
			
			DirAccess.rename_absolute(path, to_path)
			if to_character != null:
				character.global = to_character.global
			else:
				if to_item.get_text(0) == "Globals":
					character.global = true
				else:
					character.global = false
			
			#move in tree
			if to_item.get_child_count() == 0:
				var dummy = create_item(to_item)
				item.move_before(dummy)
				to_item.remove_child(dummy)
				dummy.free()
			else:
				item.move_before(to_item.get_first_child())
			
		AFTER:
			#move in folder
			var path = character.get_path_to_save()
			if to_character == null: #drag on main folder - cannot drag before
				return
			var to_path = to_character.get_path_to_save(false) + character.name
			if path == to_path:
				return
			#resolve file conflict
			var path_old = to_path
			var i = 0
			while DirAccess.dir_exists_absolute(to_path):
				i += 1
				to_path = path_old + "_" + str(i)
			if i != 0:
				character.name = character.name + "_" + str(i)
				item.set_text(0, character.name)
			print("move from: " + path + " to: " + to_path)
			
			DirAccess.rename_absolute(path, to_path)
			character.global = to_character.global
			
			#move in tree
			var next_to_item = to_item.get_next() #get next sibling of to_item
			item.move_after(to_item)
		
func rename_character(item: TreeItem, new_name: String):
	var character = item.get_meta("character")
	var old_name = character.name
	var new_path = character.get_path_to_save(false)
	var old_path = new_path + old_name
	new_path = new_path + new_name
	var new_path_org = new_path
	var i = 0
	#resolve conflict
	while DirAccess.dir_exists_absolute(new_path):
		i += 1
		new_path = new_path_org + "_" + str(i)
		
	if i != 0: #filename was changed
		character.name = new_name + "_" + str(i)
		item.set_text(0, character.name)
	else:
		character.name = new_name
	DirAccess.rename_absolute(old_path, new_path) #rename folder
	DirAccess.rename_absolute(new_path + "/" + old_name, new_path + "/" + character.name) #rename file
	print("rename: ", old_path, " ", new_path)
	character.save(false)

#loads all characters
func load_characters():
	#locals
	var dir = DirAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters")
	var item:TreeItem = add_new_item("Campaign", get_root(), false)
	item.erase_button(0, 0)
	item.erase_button(0, 2)
	if dir != null:
		load_characters_in_dir(dir, "", item, false)
	item = add_new_item("Globals", get_root(), false)
	global_item = item
	item.erase_button(0, 0)
	item.erase_button(0, 2)
	#globals
	dir = DirAccess.open(Globals.base_dir_path + "/saves/Characters")
	if dir != null:
		load_characters_in_dir(dir, "", item, true)

#loads characters in dir and it's subdirs
func load_characters_in_dir(dir: DirAccess, char_name: String, parent_item: TreeItem, global: bool):
	#load character
	var item: TreeItem
	if not char_name.is_empty():
		item = add_new_item(char_name, parent_item, false)
		var char = Character.new()
		char.load_char(dir.get_current_dir(), char_name, global, item)
		item.collapsed = true
	else:
		item = parent_item
	#subdirs
	var dirs = dir.get_directories()
	for d in dirs:
		dir.change_dir(d)
		load_characters_in_dir(dir, d, item, global)
		dir.change_dir("..")

func get_char_path(tree_item: TreeItem):
	var path_arr = []
	var root = get_root()
	while tree_item != root:
		path_arr.append(tree_item.get_text(0))
		tree_item = tree_item.get_parent()
	return path_arr

func get_char_at_path(path_arr):
	var i = path_arr.size() - 1
	var tree_item = get_root()
	while i >= 0:
		var found = false
		for child_item in tree_item.get_children():
			if child_item.get_text(0) == path_arr[i]:
				print("found i: ", i)
				tree_item = child_item
				i -= 1
				found = true
				break
		if not found:
			print("character not found in tree")
			return null
	print("char found")
	return tree_item
