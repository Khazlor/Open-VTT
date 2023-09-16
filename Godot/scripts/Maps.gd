extends Control

const MapCard = preload("res://componens/mapcard.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(PersistentData)
	for map in PersistentData.map_list:
		$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(MapCard.instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized():
	var screensize = get_viewport().size
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.columns = screensize.x/400


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_new_map_pressed():
	PersistentData.map_list.append(Map_res.new())
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(MapCard.instantiate())
