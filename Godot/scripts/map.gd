extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	#load
	if Globals.map.saved_scene != null:
		print("load")
		$Draw/Lines.replace_by(Globals.map.saved_scene.instantiate())
#		for child in draw.get_children():
#			if child.name == "Lines":
#				draw.remove_child(child)
#		draw.add_child(Globals.map.saved_scene.instantiate())
	else:
		print("new map")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


