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
			token.character = character.duplicate(true)
		Globals.draw_layer.add_child(token)
		Globals.map.add_token(token)
	
