#Author: Vladimír Horák
#Desc:
#Script for controlling tree structure with list of precreated items

extends Tree

var item_creation_dialog = preload("res://components/item_creation.tscn")

var button_add: Texture2D = preload("res://icons/Add.svg")
var button_remove: Texture2D = preload("res://icons/Remove.svg")
var icon: Texture2D = preload("res://icon.svg")

enum {BEFORE = -1, ON = 0, AFTER = 1}

signal moved(item, to_item, shift)

var global_item: TreeItem

func _ready():
	hide_root = true
	connect("moved", _move_item)
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():  #multiplayer - client
		return
	var item = create_item() #root
	item.set_selectable(0, false)
	item.add_button(0, button_add, 0)
	load_items()
	if item.get_child_count() == 0:
		hide_root = false


func add_new_item(item_name: String, parent: TreeItem = null):
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
	item.add_button(0, button_add)
	item.add_button(0, button_remove)
	return item


func is_ancestor(ancestor: TreeItem, descendant: TreeItem):
	while descendant != null:
		descendant = descendant.get_parent()
		if descendant == ancestor:
			return true
	return false

func _get_drag_data(_item_position):
	#place drag and drop layer on top - in case of dragging to map
	Globals.drag_drop_canvas_layer.layer = 128
	
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
	match(shift):	
		BEFORE:
			#move in tree
			item.move_before(to_item)
			
		ON:
			#move in tree
			if to_item.get_child_count() == 0:
				var dummy = create_item(to_item)
				item.move_before(dummy)
				to_item.remove_child(dummy)
				dummy.free()
			else:
				item.move_before(to_item.get_first_child())
			
		AFTER:
			#move in tree
			var next_to_item = to_item.get_next() #get next sibling of to_item
			item.move_after(to_item)
		
func save_items():
	var item_list = get_treeitem_dict_and_children(self.get_root())
	var file = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/items.json", FileAccess.WRITE)
	file.store_var(item_list[1])
	file.close()
	
#recursively gets treeitem's item_dict and children
func get_treeitem_dict_and_children(tree_item: TreeItem):
	var child_list = []
	for child in tree_item.get_children():
		child_list.append(get_treeitem_dict_and_children(child))
	return [tree_item.get_meta("item_dict"), child_list]
	
func load_items():
	if FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/items.json"):
		var file = FileAccess.open(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/items.json", FileAccess.READ)
		var item_list = file.get_var()
		file.close()
		for item in item_list:
			print(item)
			set_treeitem_dict_and_children(self.get_root(), item)
		
		
#recursively sets treeitem's item_dict and children
func set_treeitem_dict_and_children(parent_item: TreeItem, dict_child_arr):
	var new_item = self.add_new_item(dict_child_arr[0]["name"], parent_item)
	new_item.set_meta("item_dict", dict_child_arr[0])
	for child in dict_child_arr[1]:
		set_treeitem_dict_and_children(new_item, child)
