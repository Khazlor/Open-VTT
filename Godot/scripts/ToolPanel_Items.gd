#Author: Vladimír Horák
#Desc:
#Script for item list in ToolPanel on right side of screen

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

#double click on items opens it's editing
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

#clicked on add or remove buttons
func _on_tree_button_clicked(item, column, id, mouse_button_index):
	if id == 0:#add new
		var item_creation = item_creation_dialog.instantiate()
		if item.get_meta("item_dict") != null:
			item_creation.item_dict = item.get_meta("item_dict").duplicate(true)
		add_child(item_creation)
		item_creation.popup()
		await item_creation.close_requested
		var new_item = tree.add_new_item(item_creation.item_dict["name"], item)
		new_item.set_meta("item_dict", item_creation.item_dict)
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
	if not Globals.client: #not client
		tree.save_items()
