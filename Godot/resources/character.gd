#Author: Vladimír Horák
#Desc:
#Resource for saving character data

extends Resource
class_name Character

@export var name = ""
@export var attributes = {} #dictionary for all attributes of character
@export var global = false #global characters are shared between campaings
@export var singleton = false #all tokens have linked attributes

@export var token_shape: StringName = &"Square"
@export var token_size: Vector2 = Vector2(70,70)
@export var token_scale: Vector2 = Vector2(1,1)
@export var token_outline_width: float = 5
@export var token_outline_color: Color = Color.BLACK
@export var token_outline_faction_color: bool = true
@export var token_texture: Texture2D
@export var token_texture_offset: Vector2 = Vector2(0,0)
@export var token_texture_scale: Vector2 = Vector2(1,1)

@export var bars = [] #list of all character bars
@export var attr_bubbles = [] #list of character attributes that are displayed in bubbles
@export var macros = {} #dict of all macros
var macros_in_bar = {} #dict of all macros in action bar

var tree_item: TreeItem

signal token_changed()
signal bars_changed()
signal attr_bubbles_changed()
signal attr_updated(attr: StringName)
signal macro_bar_changed(macro, macro2)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#save character resource to file
func save(resolve_conflict: bool = false):
	#get full path to save
	var path = get_path_to_save()
	if resolve_conflict:
		var path_old = path
		var i = 0
		while DirAccess.dir_exists_absolute(path):
			i += 1
			path = path_old + "_" + str(i)
		if i != 0:
			name = name + "_" + str(i)
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	if not DirAccess.dir_exists_absolute(path):
		print("folder does not exist: " + path)
	var save = FileAccess.open(path + "/" + name, FileAccess.WRITE)
	if save == null:
		print("file open error - aborting")
		print(error_string(FileAccess.get_open_error()))
		return
	store_char_data(save)
	save.close()
	
func store_char_data(save: FileAccess):
	save.store_var(name)
	save.store_var(attributes)
	save.store_var(global)
	save.store_var(singleton)
	save.store_var(token_shape)
	save.store_var(token_size)
	save.store_var(token_scale)
	save.store_var(token_outline_width)
	save.store_var(token_outline_color)
	save.store_var(token_outline_faction_color)
	if token_texture != null:
		save.store_var(token_texture.resource_path)
	else:
		save.store_var("")
	save.store_var(token_texture_offset)
	save.store_var(token_texture_scale)
	save.store_var(bars)
	save.store_var(attr_bubbles)
	save.store_var(macros)
	
func load_char(path: String, char_name: String, global: bool, tree_item: TreeItem):
	if not FileAccess.file_exists(path + "/" + char_name):
		return #no save to load
		
	self.name = char_name
	self.global = global
	self.tree_item = tree_item
	#load attributes from file
	var save = FileAccess.open(path + "/" + char_name, FileAccess.READ)
	if save == null:
		print("file open error - aborting")
		return
	get_char_data(save)
	save.close()
	
	tree_item.set_meta("character", self)
	#print("char loaded --- name: " + self.name + ", global: " + str(self.global) + ", attributes: " + str(attributes.size()))
	
func get_char_data(save: FileAccess):
	name = save.get_var()
	attributes = save.get_var()
	global = save.get_var()
	singleton = save.get_var()
	token_shape = save.get_var()
	token_size = save.get_var()
	token_scale = save.get_var()
	token_outline_width = save.get_var()
	token_outline_color = save.get_var()
	token_outline_faction_color = save.get_var()
	var texture_path = save.get_var()
	token_texture = load(texture_path)
	token_texture_offset = save.get_var()
	token_texture_scale = save.get_var()
	bars = save.get_var()
	attr_bubbles = save.get_var()
	macros = save.get_var()
	
	
func get_path_to_save(include_name: bool = true):
	var base_path: String #character folder
	if global:
		base_path = "res://saves/Characters"
	else:
		base_path = "res://saves/Campaigns/" + Globals.campaign.campaign_name + "/Characters"
	if not DirAccess.dir_exists_absolute(base_path):
		DirAccess.make_dir_recursive_absolute(base_path)
	var path: String #path to character inside character folder
	if include_name:
		path = name
	else:
		path = ""
	var item = tree_item.get_parent()
	var root = tree_item.get_tree().get_root()
	while item.get_parent() != root:
		path = item.get_text(0) + "/" + path
		item = item.get_parent()
	return base_path + "/" + path
	
func delete():
	var path = get_path_to_save(true)
	OS.move_to_trash(ProjectSettings.globalize_path(path)) #TODO might not work after project export: https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-move-to-trash
	
