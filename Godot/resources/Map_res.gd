class_name Map_res
extends Resource

@export var map_name = "Map Name"
@export var map_desc = "Description"
@export var grid_size = 70
@export var unit_size = 5
@export var unit = "ft"
@export var image = "res://images/Placeholder-1479066.png"
@export var saved_layers: PackedScene = null

func save(packed_layers: PackedScene):
	print("saving")
	saved_layers = packed_layers
	if saved_layers == null:
		print("saved layers is null")
		return
	save_map()

func save_map():
	var map_save = FileAccess.open("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.WRITE)
	if map_save == null:
		print("file open error - aborting")
		return
	map_save.store_var(saved_layers, true)
	map_save.store_var(map_desc)
	map_save.store_var(grid_size)
	map_save.store_var(image)
	print(map_desc)
	print(grid_size)
	print(image)
	print(saved_layers)
	map_save.close()
	print("save completed")
	
func load_map(map_name):
	print("map loading")
	self.map_name = map_name
	if not FileAccess.file_exists("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name):
		return #no save to load
	
	var map_save = FileAccess.open("res://saves/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.READ)
	if map_save == null:
		print("file open error - aborting")
		return
	saved_layers = map_save.get_var(true)
	map_desc = map_save.get_var()
	grid_size = map_save.get_var()
	image = map_save.get_var()
	print(map_desc)
	print(grid_size)
	print(image)
	print(saved_layers)
	map_save.close()
	print("map loaded")

