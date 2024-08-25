#Author: Vladimír Horák
#Desc:
#Script controlling buttons of tree structure GUI representing map layers

extends Control

var button_visible: Texture2D = preload("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = preload("res://icons/GuiVisibilityHidden.svg")
var button_DM: Texture2D = preload("res://icons/DM.png")
var button_DM_not: Texture2D = preload("res://icons/DM_not.png")
var button_players: Texture2D = preload("res://icons/Players.png")
var button_players_not: Texture2D = preload("res://icons/Players_not.png")

var dialog_item
var lightlist_item

@onready var tree = $Tree
@onready var lightlistPopup = $PopupPanel
@onready var lightlist = $PopupPanel/LightItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.layers = self
	
#rename
func _on_tree_item_activated():
	if Globals.lobby.check_is_server():
		tree.edit_selected(true)

#select layer
func _on_tree_item_selected():
	Globals.draw_layer = tree.get_selected().get_meta("draw_layer")
	if Globals.map.fov_enable:
		set_layers_visibility()
		set_token_visibility(Globals.draw_layer.light_mask)

@rpc("any_peer", "call_remote", "reliable")
func synch_button_press_on_remote(layer_path, column, id, mouse_button_index):
	_on_tree_button_clicked(get_node(layer_path).get_meta("tree_item"), column, id, mouse_button_index, true)

#some treeitem button pressed
func _on_tree_button_clicked(item, column, id, mouse_button_index, remote = false):
	var layer = item.get_meta("draw_layer")
	if id == 0:#visibility
		if remote == false:
			synch_button_press_on_remote.rpc(get_path_to(item.get_meta("draw_layer")), column, id, mouse_button_index)
		if layer.get_meta("visibility") == 0:
			layer.set_meta("visibility", 1)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_visible)
			else:
				set_tree_item_visibility(layer)
			set_layer_visibility(layer)
		else:
			layer.set_meta("visibility", 0)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_hidden)
			else:
				set_tree_item_visibility(layer)
			set_layer_visibility(layer)
	elif id == 1:#DM
		if remote == false:
			synch_button_press_on_remote.rpc(get_path_to(item.get_meta("draw_layer")), column, id, mouse_button_index)
		if layer.get_meta("DM") == 0:
			layer.set_meta("DM", 1)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_DM)
			else:
				set_tree_item_visibility(layer)
			set_layer_visibility(layer)
		else:
			layer.set_meta("DM", 0)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_DM_not)
			else:
				set_tree_item_visibility(layer)
			set_layer_visibility(layer)
	elif id == 2:#player_layer
		if remote == false:
			synch_button_press_on_remote.rpc(get_path_to(item.get_meta("draw_layer")), column, id, mouse_button_index)
		if layer.get_meta("player_layer") == 0:
			layer.set_meta("player_layer", 1)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_players)
			else:
				set_tree_item_visibility(layer)
		else:
			layer.set_meta("player_layer", 0)
			if Globals.lobby.check_is_server():
				item.set_button(column, id, button_players_not)
			else:
				set_tree_item_visibility(layer)
	elif id == 3:#add new
		var new_item = tree.add_new_item("new layer", item)
		tree.set_selected(new_item, 0)
	elif id == 4:#remove
		if remote:
			custom_remove_item(item)
		elif item.get_first_child() == null and layer.get_child_count() == 0:
			synch_button_press_on_remote.rpc(get_path_to(item.get_meta("draw_layer")), column, id, mouse_button_index)
			custom_remove_item(item)
		else:
			dialog_item = item
			$ConfirmationDialog.popup()
	elif id == 5:#light
		lightlistPopup.popup()
		lightlist.grab_focus()
		lightlist_item = item
		lightlist.deselect_all()
		for i in range(0, 17):
			if layer.light_mask & 1<<i: #bitwise and with bit value
				print(i, " is in lightmask")
				lightlist.select(i, false)
		lightlistPopup.position = get_global_mouse_position()

#sets visibility of layer in tree for players
func set_tree_item_visibility(layer):
	print("set_tree_item_visibility")
	var item = layer.get_meta("tree_item")
	if not layer.get_meta("visibility") or layer.get_meta("DM") or not layer.get_meta("player_layer"):
		item.visible = false
		if Globals.draw_layer == layer or layer.is_ancestor_of(Globals.draw_layer):
			var first_item = null
			for tree_item in tree.get_root().get_children():
				if tree_item.visible:
					first_item = tree_item
			print("hidden used layer - switching to: ", first_item)
			if first_item != null:
				tree.set_selected(first_item, 0)
				Globals.draw_layer = first_item.get_meta("draw_layer")
			else:
				Globals.draw_layer = null
	else:
		item.visible = true
		if Globals.draw_layer == null:
			tree.set_selected(item, 0)
			Globals.draw_layer = item.get_meta("draw_layer")
	
#sets visibility of layer on map
func set_layer_visibility(layer):
	if not layer.get_meta("visibility") or (not Globals.lobby.check_is_server() and layer.get_meta("DM")):
		layer.visible = false
	else:
		layer.visible = true


@rpc("any_peer", "call_remote", "reliable")
func set_item_name_on_remote(layer_path, item_name):
	var layer = get_node(layer_path)
	layer.set_meta("item_name", item_name)
	layer.get_meta("tree_item").set_text(0, item_name)

#change meta data of layer for reload with edited name
func _on_tree_item_edited():
	var layer = tree.get_edited().get_meta("draw_layer")
	var text = tree.get_edited().get_text(0)
	layer.set_meta("item_name", text)
	set_item_name_on_remote.rpc(get_path_to(layer), text)


func _on_confirmation_dialog_confirmed():
	synch_button_press_on_remote.rpc(get_path_to(dialog_item.get_meta("draw_layer")), 0, 4, 0)
	custom_remove_item(dialog_item)
	
func custom_remove_item(item: TreeItem):
	var draw_layer = item.get_meta("draw_layer")
	item.free()
	if tree.get_root().get_first_child() == null:
		tree.hide_root = false
	draw_layer.connect("tree_exited", Globals.new_map.remove_tokens_from_token_array)
	draw_layer.queue_free()

@rpc("any_peer", "call_remote", "reliable")
func set_light_on_self_and_children_remote(layer_path, mask):
	var layer = get_node(layer_path)
	tree.set_light_on_self_and_children(layer, mask)
	

func _on_light_item_list_multi_selected(index, selected):
	var indexes = lightlist.get_selected_items()
	var mask = 0
	for i in indexes:
		mask += 1<<i #bitwise setting of int based on index position
	var layer = lightlist_item.get_meta("draw_layer")
	tree.set_light_on_self_and_children(layer, mask)
	set_light_on_self_and_children_remote.rpc(get_path_to(layer), mask)
	

func _on_light_item_list_focus_exited():
	lightlist.visible = false


@rpc("any_peer", "call_remote", "reliable")
func propagate_light_mask_to_peers(layer_path, mask):
	var layer = get_node(layer_path)
	propagate_light_mask(layer.get_meta("tree_item"), mask)
	
	
func _on_light_propagate_button_pressed():
	var layer = lightlist_item.get_meta("draw_layer")
	var mask = layer.light_mask
	propagate_light_mask(lightlist_item, mask)
	propagate_light_mask_to_peers.rpc(get_path_to(layer), mask)
	
func propagate_light_mask(item, mask):
	var layer = item.get_meta("draw_layer")
	tree.set_light_on_self_and_children(layer, mask)
	for child in item.get_children():
		propagate_light_mask(child, mask)
		
@rpc("any_peer", "call_local", "reliable")
func set_token_visibility(mask = null):
	if mask == null:
		if Globals.draw_layer == null:
			return
		mask = Globals.draw_layer.light_mask
	var token_clear = false
	for token in Globals.map.tokens:
		if token != null:
			if token.light_mask & mask: #if at least one bit same
				if token.character.player_character:
					token.fov.visible = true
			else:
				token.fov.visible = false
		else:
			token_clear = true
	if token_clear:
		Globals.new_map.remove_tokens_from_token_array()
			
			
#set layers visibility based on selected layer when using FOV
@rpc("any_peer", "call_local", "reliable")
func set_layers_visibility():
	var layers = tree.get_root().get_children()
	for layer in layers:
		layer = layer.get_meta("draw_layer")
		if layer == Globals.draw_layer or layer.is_ancestor_of(Globals.draw_layer):
			layer.visible = true
			return #want to see layers below
		else:
			layer.visible = false
			
#reset layer visibility after FOV disabled
@rpc("any_peer", "call_local", "reliable")
func reset_layers_visibility():
	var tree_layers = tree.get_root().get_children()
	for tree_layer in tree_layers:
		set_layer_visibility(tree_layer.get_meta("draw_layer"))

