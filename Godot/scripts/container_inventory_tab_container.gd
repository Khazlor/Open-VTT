extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	var tab_bar = get_tab_bar()
	tab_bar.mouse_filter = Control.MOUSE_FILTER_PASS #stops blocking drag and drop


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _can_drop_data(at_position, data):
	print("tab_can_drop_data = ", data.has_meta("item_dict"))
	return data.has_meta("item_dict")

func _drop_data(at_position, data):
	var inv = get_tab_control(get_tab_idx_at_point(at_position))
	var item_dict = data.get_meta("item_dict")
	var new_item_dict = item_dict.duplicate(true)
	new_item_dict["equipped"] = false
	inv.tree.add_item_treeitem(data.get_meta("item_dict").duplicate(true))
	if data.has_meta("inventory"): #dragging from inventory - remove from old
		var inventory = data.get_meta("inventory")
		if item_dict["equipped"]: #unequip
			var char = data.get_meta("item_char")
			char.unequip_item(item_dict)
		for i in inventory.size():
			if is_same(inventory[i], item_dict): #remove from inventory array
				inventory.remove_at(i)
				break
		data.free() #remove treeitem in old inventory
	Globals.drag_drop_canvas_layer.layer = -1
