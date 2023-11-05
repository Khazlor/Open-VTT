extends Control

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")

var dialog_item

@onready var tree = $Tree

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_tree_item_activated():
	tree.edit_selected(true)


func _on_tree_item_selected():
	Globals.draw_layer = tree.get_selected().get_meta("draw_layer")


func _on_tree_button_clicked(item, column, id, mouse_button_index):
	var layer = item.get_meta("draw_layer")
	if id == 0:#visibility
		if layer.visible:
			item.set_button(column, id, button_hidden)
			layer.visible = false
		else:
			item.set_button(column, id, button_visible)
			layer.visible = true
	if id == 1:#add new
		var new_item = tree.add_new_item("new layer", item)
		tree.set_selected(new_item, 0)
	if id == 2:#remove
		if item.get_first_child() == null and item.get_meta("draw_layer").get_child_count() == 0:
			custom_remove_item(item)
		else:
			dialog_item = item
			$ConfirmationDialog.popup()

#change meta data of layer for reload with edited name
func _on_tree_item_edited():
	tree.get_edited().get_meta("draw_layer").set_meta("item_name", tree.get_edited().get_text(0))


func _on_confirmation_dialog_confirmed():
	custom_remove_item(dialog_item)
	
func custom_remove_item(item: TreeItem):
	item.get_meta("draw_layer").queue_free()
	item.free()
	
	if tree.get_root().get_first_child() == null:
		tree.hide_root = false

