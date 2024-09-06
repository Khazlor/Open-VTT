#Author: Vladimír Horák
#Desc:
#Script controlling mapcards in Maps scene - selecting map, signal for opening map setting popup

extends Control
var map: Map_res
signal mapcard_right_click(map, mapcard)

# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelContainer/VBoxContainer/Name.text = map.map_name
	$PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/Desc.text = map.map_desc
	$PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/Size.text = "size: " + str(map.grid_size) + "px = " +str(map.unit_size) + " " + map.unit 
	$PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/preview.texture = Globals.load_texture(map.image)


func _on_gui_input(event):
	if event.is_action_pressed("mouseleft"):
		Globals.new_map = map
		if get_tree().current_scene.name == "Maps":
			get_tree().change_scene_to_file("res://scenes/player_lobby.tscn")
		else: #already in player_lobby
			Globals.lobby._ready()
	elif event.is_action_pressed("mouseright"):
		Globals.new_map = map
		emit_signal("mapcard_right_click", map, self)
		
#		$"../../PopupPanel".position = get_global_mouse_position()
#		$"../../PopupPanel/VBoxContainer/MapName".text = map.map_name
#		$"../../PopupPanel/VBoxContainer/MapDesc".text = map.map_desc
#		$"../../PopupPanel/VBoxContainer/GridSizePx".value = map.grid_size
#		$"../../PopupPanel/VBoxContainer/UnitSize".value = map.unit_size
#		$"../../PopupPanel/VBoxContainer/Unit".text = map.unit
#		$"../../PopupPanel".visible = true
#
#		#keep popup in window
#		if $"../../PopupPanel".position.x + $"../../PopupPanel".size.x > get_viewport().size.x:
#			$"../../PopupPanel".position.x = get_viewport().size.x - $"../../PopupPanel".size.x
#		if $"../../PopupPanel".position.y + $"../../PopupPanel".size.y > get_viewport().size.y:
#			$"../../PopupPanel".position.y = get_viewport().size.y - $"../../PopupPanel".size.y
#
#		#connect signals
#		$"../../PopupPanel".connect("popup_hide", _on_popup_hide)
#		$"../../PopupPanel/VBoxContainer/ApplyButton".connect("pressed", _apply_edit)
#		$"../../PopupPanel/VBoxContainer/DuplicateButton".connect("pressed", _on_duplicate)
#		$"../../PopupPanel/VBoxContainer/DeleteButton".connect("pressed", _on_delete)
		
		
#func _on_popup_hide():
#	#disconnect all signals
#	$"../../PopupPanel".disconnect("popup_hide", _on_popup_hide)
#	$"../../PopupPanel/VBoxContainer/ApplyButton".disconnect("pressed", _apply_edit)
#	$"../../PopupPanel/VBoxContainer/DuplicateButton".disconnect("pressed", _on_duplicate)
#	$"../../PopupPanel/VBoxContainer/DeleteButton".disconnect("pressed", _on_delete)
#
#func _apply_edit():
#	#setting map_res
#	print(map.map_name + " = " + $"../../PopupPanel/VBoxContainer/MapName".text)
#	if map.map_name != $"../../PopupPanel/VBoxContainer/MapName".text:
#		var oldname = map.map_name
#		var newname = $"../../PopupPanel/VBoxContainer/MapName".text
#		map.map_name = $"../../PopupPanel/VBoxContainer/MapName".text
#		var i = 0
#		while FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name):
#			i += 1
#			map.map_name = newname + "_" + str(i)
#		if DirAccess.rename_absolute(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + oldname, Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map.map_name) != Error.OK:
#			map.map_name = oldname
#	map.map_desc = $"../../PopupPanel/VBoxContainer/MapDesc".text
#	map.grid_size = $"../../PopupPanel/VBoxContainer/GridSizePx".value
#	map.unit_size = $"../../PopupPanel/VBoxContainer/UnitSize".value
#	map.unit = $"../../PopupPanel/VBoxContainer/Unit".text
#
#	#setting map_card
#	$PanelContainer/Name.text = map.map_name
#	$PanelContainer/MarginContainer/VBoxContainer/Desc.text = map.map_desc
#	$PanelContainer/MarginContainer/VBoxContainer/Size.text = "size: " + str(map.grid_size) + "px = " +str(map.unit_size) + " " + map.unit 
#	$PanelContainer/preview.texture = Globals.load_texture(map.image)
#
#func _on_duplicate():
#	var newmap = map.duplicate(true)
#	var i = 0
#	var oldname = newmap.map_name
#	print(map.map_name)
#	print(map.map_desc)
#	print(newmap.map_name)
#	print(newmap.map_desc)
#	while FileAccess.file_exists(Globals.base_dir_path + "/saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + newmap.map_name):
#		i += 1
#		newmap.map_name = oldname + "_" + str(i)
#	newmap.save_map()
#
#	emit_signal("mapcard_duplicate", newmap)
#
#
#func _on_delete():
#	pass
