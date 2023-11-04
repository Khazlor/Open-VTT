extends Control

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")

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


func _on_tree_button_clicked(item, column, id, mouse_button_index):
	var layer = item.get_meta("draw_layer")
	if id == 0:
		if layer.visible:
			item.set_button(column, id, button_hidden)
			layer.visible = false
		else:
			item.set_button(column, id, button_visible)
			layer.visible = true
		
