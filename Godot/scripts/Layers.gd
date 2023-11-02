extends Control

@onready var tree = $Tree

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_tree_item_activated():
	tree.edit_selected(true)


func _on_tree_item_mouse_selected(position, mouse_button_index):
	Globals.draw_layer = tree.get_selected().get_meta("draw_layer")
