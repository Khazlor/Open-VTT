class_name Map_res
extends Resource

@export var map_name = "Map Name"
@export var map_desc = "Description"
@export var grid_size = 70
@export var unit_size = 5
@export var unit = "ft"
@export var image = "res://images/Placeholder-1479066.png"
@export var saved_scene: PackedScene = null

func save(packed_scene: PackedScene):
	print("saving")
	saved_scene = packed_scene
	if saved_scene == null:
		print("saved scene is null")
		return
	save_map()

func save_map():
	var map_save = FileAccess.open("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.WRITE)
	if map_save == null:
		print("file open error - aborting")
		return
	map_save.store_var(map_desc)
	map_save.store_var(grid_size)
	map_save.store_var(image)
	map_save.store_var(saved_scene, true)
	map_save.close()
	
func load_map(map_name):
	self.map_name = map_name
	if not FileAccess.file_exists("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name):
		return #no save to load
	
	var map_save = FileAccess.open("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.READ)
	if map_save == null:
		print("file open error - aborting")
		return
	map_desc = map_save.get_var()
	grid_size = map_save.get_var()
	image = map_save.get_var()
	saved_scene = map_save.get_var(true)
	map_save.close()
