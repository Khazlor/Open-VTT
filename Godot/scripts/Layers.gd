#Author: Vladimír Horák
#Desc:
#Script controlling buttons of tree structure GUI representing map layers

extends Control

var button_visible: Texture2D = load("res://icons/GuiVisibilityVisible.svg")
var button_hidden: Texture2D = load("res://icons/GuiVisibilityHidden.svg")

var dialog_item
var lightlist_item

@onready var tree = $Tree
@onready var lightlistPopup = $PopupPanel
@onready var lightlist = $PopupPanel/LightItemList

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
	if Globals.map.fov_enable:
		set_layers_visibility()
		set_token_visibility(Globals.draw_layer.light_mask)


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
		if item.get_first_child() == null and layer.get_child_count() == 0:
			custom_remove_item(item)
		else:
			dialog_item = item
			$ConfirmationDialog.popup()
	if id == 3:#light
		lightlistPopup.popup()
		lightlist.grab_focus()
		lightlist_item = item
		lightlist.deselect_all()
		for i in range(0, 17):
			if layer.light_mask & 1<<i: #bitwise and with bit value
				print(i, " is in lightmask")
				lightlist.select(i, false)
		lightlistPopup.position = get_global_mouse_position()

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

func _on_light_item_list_multi_selected(index, selected):
	var indexes = lightlist.get_selected_items()
	var mask = 0
	for i in indexes:
		mask += 1<<i #bitwise setting of int based on index position
	var layer = lightlist_item.get_meta("draw_layer")
	tree.set_light_on_self_and_children(layer, mask)
	

func _on_light_item_list_focus_exited():
	lightlist.visible = false


func _on_light_propagate_button_pressed():
	var layer = lightlist_item.get_meta("draw_layer")
	var mask = layer.light_mask
	propagate_light_mask(lightlist_item, mask)
	
func propagate_light_mask(item, mask):
	var layer = item.get_meta("draw_layer")
	tree.set_light_on_self_and_children(layer, mask)
	for child in item.get_children():
		propagate_light_mask(child, mask)
		
func set_token_visibility(mask):
	for token in Globals.map.tokens:
		if token.light_mask & mask: #if at least one bit same
			token.fov.visible = true
		else:
			token.fov.visible = false
			
func set_layers_visibility():
	var layers = tree.get_root().get_children()
	for layer in layers:
		layer = layer.get_meta("draw_layer")
		if layer == Globals.draw_layer or layer.is_ancestor_of(Globals.draw_layer):
			layer.visible = true
			return #want to see layers below
		else:
			layer.visible = false
	
