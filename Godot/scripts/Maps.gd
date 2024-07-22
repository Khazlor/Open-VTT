#Author: Vladimír Horák
#Desc:
#Script for controlling Maps scene -- creating, editing, selecting map from mapcard

extends Control

const MapCard = preload("res://components/mapcard.tscn")

#popup path for shorter paths
@onready var popup = $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/PopupPanel

var map: Map_res
var mapcard

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():  #multiplayer - client
		return
	popup.transient = true
	popup.exclusive = true
	if not DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps"):
		DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps")
	var files = DirAccess.get_files_at(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps")
	for file in files:
		if file.get_extension() != "":
			continue
		map = Map_res.new()
		map.load_map(file, false)
		
		_add_mapcard(map)
	
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
	map = Map_res.new()
	
	if not DirAccess.dir_exists_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps"):
		DirAccess.make_dir_recursive_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps")
	var i = 0
	var oldname = map.map_name
	while FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name):
		i += 1
		map.map_name = oldname + "_" + str(i)
	map.save_map(null)
	
	_add_mapcard(map)
	
func _add_mapcard(map: Map_res):
	mapcard = MapCard.instantiate()
	mapcard.map = map
	mapcard.connect("mapcard_right_click", _on_mapcard_right_click)
	$PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/MapGrid.add_child(mapcard)
	
func _on_mapcard_right_click(map: Map_res, mapcard):
	self.map = map
	self.mapcard = mapcard
	
	popup.position = get_global_mouse_position()
	popup.get_node("VBoxContainer/MapName").text = map.map_name
	popup.get_node("VBoxContainer/MapDesc").text = map.map_desc
	popup.get_node("VBoxContainer/GridSizePx").value = map.grid_size
	popup.get_node("VBoxContainer/UnitSize").value = map.unit_size
	popup.get_node("VBoxContainer/Unit").text = map.unit
	popup.visible = true
	
	#keep popup in window
	if popup.position.x + popup.size.x > get_viewport().size.x:
		popup.position.x = get_viewport().size.x - popup.size.x
	if popup.position.y + popup.size.y > get_viewport().size.y:
		popup.position.y = get_viewport().size.y - popup.size.y
	

func _on_apply_button_pressed():
	#setting map_res
	var newname = popup.get_node("VBoxContainer/MapName").text
	if map.map_name != newname:
		var oldname = map.map_name
		map.map_name = newname
		var i = 0
		while FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name):
			i += 1
			map.map_name = newname + "_" + str(i)
		if DirAccess.rename_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + oldname, Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name) != Error.OK:
			map.map_name = oldname
	map.map_desc = popup.get_node("VBoxContainer/MapDesc").text
	map.grid_size = popup.get_node("VBoxContainer/GridSizePx").value
	map.unit_size = popup.get_node("VBoxContainer/UnitSize").value
	map.unit = popup.get_node("VBoxContainer/Unit").text
	
	#setting map_card
	mapcard.get_node("PanelContainer/Name").text = map.map_name
	mapcard.get_node("PanelContainer/MarginContainer/VBoxContainer/Desc").text = map.map_desc
	mapcard.get_node("PanelContainer/MarginContainer/VBoxContainer/Size").text = "size: " + str(map.grid_size) + "px = " +str(map.unit_size) + " " + map.unit 
	mapcard.get_node("PanelContainer/preview").texture = Globals.load_texture(map.image)

	popup.hide()


func _on_cancel_button_pressed():
	popup.hide()
	


func _on_duplicate_button_pressed():
	var newmap = map.duplicate(true)
	var i = 0
	var oldname = newmap.map_name
	while FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + newmap.map_name):
		i += 1
		newmap.map_name = oldname + "_" + str(i)
	newmap.save_map()
	
	_add_mapcard(newmap)
	popup.hide()


func _on_delete_button_pressed():
	DirAccess.remove_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name)
	mapcard.queue_free()
	map = null
	popup.hide()
	

