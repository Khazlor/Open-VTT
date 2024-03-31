extends MarginContainer


var button_visible: Texture2D = preload("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = preload("res://icons/GuiVisibilityHidden.svg")

var item_creation_dialog = preload("res://components/item_creation.tscn")

var dialog_item

@onready var tree = $Tree

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_tree_item_activated():
	var item_creation = item_creation_dialog.instantiate()
	var tree_item = tree.get_selected()
	item_creation.item_dict = tree_item.get_meta("item_dict")
	add_child(item_creation)
	item_creation.popup()
	await item_creation.close_requested
#	tree_item.set_meta("item_dict", item_creation.item_dict) #probably not needed
	tree_item.set_text(0, item_creation.item_dict["name"])
	remove_child(item_creation)
	item_creation.queue_free()
	


func _on_tree_button_clicked(item, column, id, mouse_button_index):
	if id == 0:#add new
		var item_creation = item_creation_dialog.instantiate()
		add_child(item_creation)
		item_creation.popup()
		await item_creation.close_requested
		var new_item = tree.add_new_item(item_creation.item_dict["name"], item)
		new_item.set_meta("item_dict", item_creation.item_dict) #probably not needed
		remove_child(item_creation)
		item_creation.queue_free()
	if id == 1:#remove
		dialog_item = item
		$ConfirmationDialog.popup()


func _on_confirmation_dialog_confirmed():
	custom_remove_item(dialog_item)
	
	
func custom_remove_item(item: TreeItem):
	item.free()
	
	if tree.get_root().get_first_child() == null:
		tree.hide_root = false
		


func _on_tree_tree_exiting():
	if multiplayer.is_server():
		tree.save_items()
