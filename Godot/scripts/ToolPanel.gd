#Author: Vladimír Horák
#Desc:
#Script controlling ToolPanel - contains tabs with player data and setting for different elements
#contains character_tree button functions - TODO move to separate script applied on "Characters" Margin container

extends Control

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")

var char_sheet = preload("res://UI/character_sheet.tscn")

var dialog_item

@onready var tree = $TabContainer/Characters/ScrollContainer/Tree

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_tree_item_activated():
	#tree.edit_selected(true) # edit name - instead open
	print("opening character sheet")
	var ch_sh = char_sheet.instantiate()
	ch_sh.character = tree.get_selected().get_meta("character")
	add_child(ch_sh)


func _on_tree_item_selected():
	#Globals.draw_layer = tree.get_selected().get_meta("draw_layer")
	pass


func _on_tree_button_clicked(item, column, id, mouse_button_index):
	if id == 0:#add new
		if item == tree.get_root(): #first character
			tree.add_new_item("Character", item)
		else:
			tree.add_new_item(item.get_text(0) + "_copy", item)
	if id == 1:#remove
		dialog_item = item
		$ConfirmationDialog.popup()

#change meta data of layer for reload with edited name
func _on_tree_item_edited():
	#tree.get_edited().get_meta("draw_layer").set_meta("item_name", tree.get_edited().get_text(0))
	pass

func _on_confirmation_dialog_confirmed():
	custom_remove_item(dialog_item)
	
func custom_remove_item(item: TreeItem):
	#item.get_meta("draw_layer").queue_free()
	item.free()
	
	if tree.get_root().get_first_child() == null:
		tree.hide_root = false
		
