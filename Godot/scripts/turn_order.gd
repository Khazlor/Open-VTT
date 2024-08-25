#Author: Vladimír Horák
#Desc:
#Script for controling turn_order component - tracking order of tokens in combat turn

extends Window

var selected: PanelContainer = null
@onready var items: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var turn_order_item = preload("res://components/turn_order_item.tscn")

signal token_turn_selected(token)

var auto_sort_mode = 0 # -1 = no sort - add to end, 0 = ascending, 1 = descending 
#needs implementing turn order settings - will do if time allows - TODO 

func _enter_tree():
	Globals.turn_order = self

# Called when the node enters the scene tree for the first time.
func _ready():
	unfocusable = false

func _on_prev_button_pressed():
	if selected != null:
		items.get_child(selected.get_index() - 1)._on_button_pressed() #call select by press
	else:
		if items.get_child(-1) != null:
			items.get_child(-1)._on_button_pressed() #call select by press on last


func _on_next_button_pressed():
	print("next")
	if selected != null:
		var i = selected.get_index() + 1
		if i < items.get_child_count():
			items.get_child(i)._on_button_pressed() #call select by press
		else:
			items.get_child(0)._on_button_pressed() #call select by press - from start
	else:
		if items.get_child(0) != null:
			items.get_child(0)._on_button_pressed() #call select by press on start


func _on_sort_button_pressed():
#	for item in items.get_children():
#		var item_i = item.token.character.attributes["initiative"][1]
	var sorted = items.get_children()
	sorted.sort_custom(custom_sort)
	for item in sorted:
		items.move_child(item, -1)


func custom_sort(a, b):
	return a.token.character.attributes["initiative"][1].to_int() < b.token.character.attributes["initiative"][1].to_int()


func _on_close_requested():
	self.hide()


func _on_clear_button_pressed():
	for item in items.get_children():
		item.queue_free()

	
func create_item(token):
	var new_item = turn_order_item.instantiate()
	new_item.token = token
	items.add_child(new_item)
	return new_item


func lose_focus():
	#workaround for window losing focus, just grab focus on main window does not work as of Godot 4.2.1
	#get_parent().get_window().move_to_foreground()
	self.unfocusable = true
	self.move_to_foreground()
	self.unfocusable = false
	

#window is focused - lose focus on right and middle clicks (normally only on left click outside)
func _on_window_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("mouseright") or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			lose_focus()
