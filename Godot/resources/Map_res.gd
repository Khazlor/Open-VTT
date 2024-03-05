#Author: Vladimír Horák
#Desc:
#Resource for saving map data

class_name Map_res
extends Resource

var token_comp = preload("res://components/token.tscn") #token component

@export var map_name = "Map Name"
@export var map_desc = "Description"
@export var background_color = Color.DARK_GRAY
#grid settings
@export var grid_enable = true
@export var grid_color = Color(0,128,0,128)
@export var grid_thickness = 0.01
@export var grid_size = 70
@export var unit_size = 5
@export var unit = "ft"
#darkness settings
@export var darkness_enable = false
@export var darkness_color = Color.BLACK
@export var DM_darkness_color = Color.DIM_GRAY
#fov settings
@export var fov_enable = false
@export var fov_opacity = 0.3
@export var fov_color = Color.BLACK
#preview
@export var image = "res://images/Placeholder-1479066.png"
#saved layers
@export var saved_layers: PackedScene = null
var tokens = []
var token_paths = []
var token_indexes = []

func save(packed_layers: PackedScene):
	saved_layers = packed_layers
	if saved_layers == null:
		print("saved layers is null")
		return
	save_map()

#saving using store_var(obj, true) currently broken in godot for objects with attached script with class_name as per:
#https://github.com/godotengine/godot/issues/68666
#stored var includes attached script as plain text -> leads to multiple scripts with same class_name -> parse error
#work around - saving tokens separately -> will no longer be needed if issue is fixed
func save_map():
	var map_save = FileAccess.open("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.WRITE)
	if map_save == null:
		print("file open error - aborting")
		return
	#save map data
	map_save.store_var(saved_layers, true)
	map_save.store_var(map_desc)
	map_save.store_var(grid_size)
	map_save.store_var(image)
	#save tokens - separately - more above
	map_save.store_var(tokens.size())
	for token in tokens:
		save_token(map_save, token)
	map_save.close()
	

func load_map(map_name):
	self.map_name = map_name
	if not FileAccess.file_exists("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name):
		return #no save to load
	
	var map_save = FileAccess.open("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + map_name, FileAccess.READ)
	if map_save == null:
		print("file open error - aborting")
		return
	#load map
	saved_layers = map_save.get_var(true)
	map_desc = map_save.get_var()
	grid_size = map_save.get_var()
	image = map_save.get_var()
	#load tokens
	tokens.clear()
	token_paths.clear()
	token_indexes.clear()
	var token_count = map_save.get_var()
	for i in token_count:
		load_token(map_save)
	map_save.close()
	
	return 


func save_token(save_file: FileAccess, token: Control):
	save_file.store_var(token.character.singleton)
	if token.character.singleton == false: #store character in token
		token.character.store_char_data(save_file)
	save_file.store_var(token.get_parent().get_path())
	save_file.store_var(token.get_index())
	save_file.store_var(token.token_polygon.position)
	save_file.store_var(token.token_polygon.size)
	save_file.store_var(token.token_polygon.scale)
	save_file.store_var(token.token_polygon.rotation)
	
func load_token(save_file: FileAccess):
	var token = token_comp.instantiate()
	var character = Character.new()
	character.singleton = save_file.get_var()
	if character.singleton == false: #load character from token
		character.get_char_data(save_file)
	else:
		pass #link token to character TODO
	var path: NodePath = save_file.get_var()
	var index: int = save_file.get_var()
	var token_polygon = token.get_child(0)
	token_polygon.position = save_file.get_var()
	token_polygon.custom_minimum_size = save_file.get_var()
	token_polygon.size = token_polygon.custom_minimum_size
	token_polygon.scale = save_file.get_var()
	token_polygon.rotation = save_file.get_var()
	tokens.append(token)
	token_paths.append(path)
	token_indexes.append(index)
	#set character in token
	token.character = character
	token_polygon.character = character

func add_token(token):
	tokens.append(token)

func remove_token(token):
	tokens.erase(token)
