#Author: Vladimír Horák
#Desc:
#Resource for saving character data

extends Resource
class_name Character

@export var name = ""
@export var attributes = {} #dictionary for all attributes of character
@export var global = false #global characters are shared between campaings
@export var singleton = false #all tokens have linked attributes

@export var token_shape: PackedVector2Array
@export var token_size: Vector2 = Vector2(20,20)
@export var token_scale: Vector2 = Vector2(1,1)
@export var token_outline_width: float = 2
@export var token_outline_color: Color = Color.BLACK
@export var token_outline_faction_color: bool = true
@export var token_texture: Texture2D
@export var token_texture_offset: Vector2 = Vector2(0,0)
@export var token_texture_scale: Vector2 = Vector2(1,1)

var tree_item: TreeItem

signal token_changed()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#save character resource to file
func save(resolve_conflict: bool = false):
	print("saving char: " + name)
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
		print("modified path: " + path)
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	print("trying to open file: " + path + "/" + name)
	if not DirAccess.dir_exists_absolute(path):
		print("folder does not exist: " + path)
	var save = FileAccess.open(path + "/" + name, FileAccess.WRITE)
	if save == null:
		print("file open error - aborting")
		print(error_string(FileAccess.get_open_error()))
		return
	save.store_var(attributes)
	save.close()
	print("saving char: " + name + " finished")
	
func load_char(path: String, char_name: String, global: bool, tree_item: TreeItem):
	print("char loading")
	
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
	attributes = save.get_var()
	save.close()
	
	tree_item.set_meta("character", self)
	print("char loaded --- name: " + self.name + ", global: " + str(self.global) + ", attributes: " + str(attributes.size()))
	
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
	while item != root:
		print("path =======> " + item.get_text(0))
		path = item.get_text(0) + "/" + path
		item = item.get_parent()
		if global:
			if item.get_parent() == root: #first folder Global - not actual folder
				break
	print("found path: " + path)
	return base_path + "/" + path
