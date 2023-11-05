extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var layers = $Draw/Layers
	var tree = $CanvasLayer/Layers/Tree
	#load
	if Globals.new_map.saved_layers != null:
		print("load")
		layers.replace_by(Globals.new_map.saved_layers.instantiate())
		layers = $Draw/Layers
		#recursively create treeitem for each layer
		
		tree.load_self_and_children(layers, null)
		
		$Draw.layers_root = layers
		
#		var item = $CanvasLayer/Layers/Tree.create_item()
#		item.add_child(Globals.new_map.saved_layer_tree)
#		print_tree_pretty()
		
#		for child in draw.get_children():
#			if child.name == "Lines":
#				draw.remove_child(child)
#		draw.add_child(Globals.map.saved_scene.instantiate())
	else:
		print("new map")
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
	
func _on_tree_exiting():
	#set ownership of all nodes (might have been deleted when moving layers around)
	set_owner_on_self_and_children($Draw/Layers, $Draw/Layers)
	var saved_layers = PackedScene.new()
	saved_layers.pack($Draw/Layers);
	Globals.map.save(saved_layers)


func _on_maps_button_pressed():
	$CanvasLayer/VSplitContainer.visible = true
	
func _on_maps_back_button_pressed():
	$CanvasLayer/VSplitContainer.visible = false

func _on_maps_mouse_entered():
	print("entered")
	Globals.mouseOverMaps = true
	
func _on_maps_mouse_exited():
	print("exited")
	Globals.mouseOverMaps = false
	
#sets owner of node and all its children and subchildren
func set_owner_on_self_and_children(node, owner: Node2D):
	node.set_owner(owner)
	var meta = node.get_meta("item_name")
	if meta != null:
		print(meta, node.owner)
	else:
		print(node, node.owner)
	for child in node.get_children(true):
		set_owner_on_self_and_children(child, owner)
		
