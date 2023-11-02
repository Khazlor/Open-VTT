extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	#load
	if Globals.new_map.saved_scene != null:
		print("load")
#		$Draw/Lines.replace_by(Globals.new_map.saved_scene.instantiate())
		
#		for child in draw.get_children():
#			if child.name == "Lines":
#				draw.remove_child(child)
#		draw.add_child(Globals.map.saved_scene.instantiate())
	else:
		print("new map")
	#changing map to new_map - after map was saved
	Globals.map = Globals.new_map
	Globals.draw_layer = $Draw/Lines
	#changing function on back button in Maps
	$CanvasLayer/VSplitContainer/Maps/Back.disconnect("pressed", $CanvasLayer/VSplitContainer/Maps/Back.get_signal_connection_list("pressed")[0].callable)
	$CanvasLayer/VSplitContainer/Maps/Back.connect("pressed", _on_maps_back_button_pressed)
#	$CanvasLayer/Maps.connect("mouse_entered", _on_maps_mouse_entered)
#	$CanvasLayer/Maps.connect("mouse_exited", _on_maps_mouse_exited)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_tree_exiting():
	var save = PackedScene.new()
	save.pack($Draw/Lines);
	Globals.map.save(save)


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
