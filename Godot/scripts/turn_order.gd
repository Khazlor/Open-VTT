extends Window

var selected: PanelContainer = null
@onready var items: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var turn_order_item = preload("res://componens/turn_order_item.tscn")

signal token_turn_selected(token)

var auto_sort_mode = 0 # -1 = no sort - add to end, 0 = ascending, 1 = descending 
#needs implementing turn order settings - will do if time allows - TODO 

func _enter_tree():
	Globals.turn_order = self

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	



func _on_prev_button_pressed():
	if selected != null:
		items.get_child(selected.get_index() - 1)._on_button_pressed() #call select by press
	else:
		if items.get_child(-1) != null:
			items.get_child(-1)._on_button_pressed() #call select by press on last


func _on_next_button_pressed():
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
#		var item_i = item.token.character.attributes["initiative"]
	var sorted = items.get_children()
	sorted.sort_custom(custom_sort)
	for item in sorted:
		items.move_child(item, -1)
		

func custom_sort(a, b):
	return a.token.character.attributes["initiative"].to_int() < b.token.character.attributes["initiative"].to_int()


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
	
	
	
