#Author: Vladimír Horák
#Desc:
#Script enabling dragging of characters from character_tree to map and creating tokens

extends Control

var token_comp = preload("res://componens/token.tscn") #token component
@onready var d = $"../.." #to get before canvas layer for get_global_mouse_position()

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.drag_drop_canvas_layer = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _can_drop_data(position, data):
	return data is TreeItem
	
func _drop_data(position, data):
	Globals.drag_drop_canvas_layer.layer = -1
	if data.has_meta("character"):
		var token = token_comp.instantiate()
		token.get_child(0).position = d.get_global_mouse_position() #set position of image - UI will follow via remote transform
		var character = data.get_meta("character")
		if character.singleton: #character with linked attributes
			token.character = character
		else:
			print("macros original: ", character.macros_in_bar)
			token.character = character.duplicate(true)
			print("macros after dupl: ", token.character.macros_in_bar)
			token.character.token_texture = load(character.token_texture.resource_path) # duplicate removes resource path from loaded texture
		Globals.draw_layer.add_child(token)
		Globals.map.add_token(token)
		token.light_mask = Globals.draw_layer.light_mask
		token.fov.shadow_item_cull_mask = Globals.draw_layer.light_mask
	
