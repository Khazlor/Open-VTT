extends Control

const MapCard = preload("res://componens/mapcard.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var map_dir = DirAccess.open("res://saves/" + Globals.campaign.campaign_name + "/maps")
	if map_dir == null:
		print("no maps")
		return
	var files = map_dir.get_files()
	for file in files:
		var map = Map_res.new()
		map.load_map(file)
		var mapcard = MapCard.instantiate()
		mapcard.map = map
		$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(mapcard)
	
	
#	print(PersistentData)
#	for map in Globals.campaign.map_list:
#		var mapcard = MapCard.instantiate()
#		mapcard.map = map
#		$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(mapcard)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized():
	var screensize = get_viewport().size
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.columns = screensize.x/400


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_new_map_pressed():
	var map = Map_res.new()
	
	if not DirAccess.dir_exists_absolute("res://saves/" + Globals.campaign.campaign_name + "/maps"):
		DirAccess.make_dir_recursive_absolute("res://saves/" + Globals.campaign.campaign_name + "/maps")
	var i = 0
	var oldname = map.map_name
	while FileAccess.file_exists("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map.map_name):
		i += 1
		map.map_name = oldname + "_" + str(i)
	map.save_map()
	
	var mapcard = MapCard.instantiate()
	mapcard.map = map
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(mapcard)
