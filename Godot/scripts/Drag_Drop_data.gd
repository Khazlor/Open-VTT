extends Control

var token_comp = preload("res://componens/token.tscn") #token component
@onready var d = $"../.." #to get before canvas layer for get_global_mouse_position()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _can_drop_data(position, data):
	return data is TreeItem
	
func _drop_data(position, data):
	if data.get_meta("character") != null:
		print("dropped: " + data.get_meta("character").name)
		var token = token_comp.instantiate()
		token.get_child(0).position = d.get_global_mouse_position() #set position of image - UI will follow via remote transform
		Globals.draw_layer.add_child(token)
	
