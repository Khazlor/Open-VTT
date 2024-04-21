#Author: Vladimír Horák
#Desc:
#Script controlling map scene - mainly loading and saving

extends Node2D

var char_sheet = preload("res://UI/character_sheet.tscn")


func _enter_tree():
	Globals.BG_ColorRect = $BackgroundCanvasLayer/BackgroundColorRect
	Globals.windows = $CanvasLayer/Windows

# Called when the node enters the scene tree for the first time.
func _ready():
	#light
	get_viewport().set_canvas_cull_mask_bit(2, false)
	var layers = $Draw/Layers
	var tree = $CanvasLayer/Layers/Tree
	randomize()
	
	#load
	
	Globals.draw_layer = layers
	if Globals.lobby.check_is_server():
		Globals.new_map.load_map(Globals.new_map.map_name)
		#else load in player_lobby
	else:
		$CanvasLayer/MapsButton.visible = false
		
	#recursively create treeitem for each layer
	for child in layers.get_children():
		if child.has_meta("item_name"):
			tree.load_self_and_children(child, null)
	tree.change_z_indexes()
			
	#tutorial
	if Globals.lobby.check_is_server():
		if Globals.campaign.tutorial:
			$Draw/TutorialWindow.popup()
			Globals.campaign.tutorial = false
			Globals.campaign.save_campaign()
	
	#turn order position:
	var turn_order = $CanvasLayer/Windows/TurnOrder
	turn_order.position.x = get_viewport_rect().size.x + $CanvasLayer/HSplitContainer.split_offset - turn_order.size.x - 20
	
	#if Globals.new_map.saved_layers != null:
		#layers.replace_by(Globals.new_map.saved_layers.instantiate())
		#layers = $Draw/Layers #get new $Draw/Layers
		##load tokens
		#for i in Globals.new_map.tokens.size():
			#print(Globals.new_map.tokens[i])
			#print(Globals.new_map.token_indexes[i])
			#print(Globals.new_map.token_paths[i])
			##Globals.new_map.token_paths[i] = NodePath(String(Globals.new_map.token_paths[i]).insert(5, "/PlayerLobby"))
			#var parent = get_node(Globals.new_map.token_paths[i])
			#print(parent)
			#if Globals.new_map.token_paths[i].is_empty():
				#print("path is empty")
			#parent.add_child(Globals.new_map.tokens[i])
			#parent.move_child(Globals.new_map.tokens[i], Globals.new_map.token_indexes[i])
			#Globals.new_map.tokens[i].light_mask = parent.light_mask
			#Globals.new_map.tokens[i].fov.shadow_item_cull_mask = parent.light_mask
		##recursively create treeitem for each layer
		#tree.load_self_and_children(layers, null)
		#
		#$Draw.layers_root = layers
##		var item = $CanvasLayer/Layers/Tree.create_item()
##		item.add_child(Globals.new_map.saved_layer_tree)
##		print_tree_pretty()
		#
##		for child in draw.get_children():
##			if child.name == "Lines":
##				draw.remove_child(child)
##		draw.add_child(Globals.map.saved_scene.instantiate())
	#else:
		#print("new map")
	#changing map to new_map - after map was saved
	Globals.map = Globals.new_map
	if tree.get_root().get_first_child() != null:
		tree.set_selected(tree.get_root().get_first_child(), 0)
	else:
		Globals.draw_layer = null
		tree.hide_root = false
		tree.set_selected(tree.get_root(), 0)
	#changing function on back button in Maps
	$CanvasLayer/VSplitContainer/Maps/Back.disconnect("pressed", $CanvasLayer/VSplitContainer/Maps/Back.get_signal_connection_list("pressed")[0].callable)
	$CanvasLayer/VSplitContainer/Maps/Back.connect("pressed", _on_maps_back_button_pressed)
#	$CanvasLayer/Maps.connect("mouse_entered", _on_maps_mouse_entered)
#	$CanvasLayer/Maps.connect("mouse_exited", _on_maps_mouse_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.+
func _process(delta):
	pass
	
	
func _on_child_exiting_tree(node):
	if node == self.get_child(-1): #first node - rest are still in tree - save layers
		#subwindows will be embeded - otherwise breaks popups of other scenes - reason for subviewport in this scene
		get_viewport().set_embedding_subwindows(true)
		#clear tokens list in map
		#Globals.map.tokens.clear() - no lomger filled in set_owner_on_self_and_children
		#set ownership of all nodes (might have been deleted when moving layers around)
		#set_owner_on_self_and_children($Draw/Layers, $Draw/Layers)
		
		#var saved_layers = PackedScene.new()
		#saved_layers.pack($Draw/Layers);
		#Globals.map.save($Draw/Layers)
		if Globals.lobby.check_is_server():
			Globals.map.save_map($Draw/Layers)

func _on_tree_exiting():
	if Globals.lobby.check_is_server():
		Globals.lobby.remove_map.rpc()

func _on_maps_button_pressed():
	$CanvasLayer/VSplitContainer.visible = true
	
func _on_maps_back_button_pressed():
	$CanvasLayer/VSplitContainer.visible = false
	
#sets owner of node and all its children and subchildren
func set_owner_on_self_and_children(node, owner: Node2D):
	if "character" in node: #character token - saving and loading broken - https://github.com/godotengine/godot/issues/68666 - saving separately
		#Globals.map.tokens.append(node) - now filled during token creation and loading
		return
	node.set_owner(owner)
	for child in node.get_children(true):
		set_owner_on_self_and_children(child, owner)
		
	
		


