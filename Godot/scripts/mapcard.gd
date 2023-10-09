extends Control
var map: Map_res

# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelContainer/Name.text = map.map_name
	$PanelContainer/MarginContainer/VBoxContainer/Desc.text = map.map_desc
	$PanelContainer/preview.texture = load(map.image)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_pressed():
	if Globals.map != null:
		print(Globals.map.saved_scene)
	Globals.map = map
	print(Globals.map.saved_scene)
	get_tree().change_scene_to_file("res://scenes/map.tscn")
