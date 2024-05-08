#Author: Vladimír Horák
#Desc:
#Script component enabling dragging of characters from character_tree and items from inventory to map and creating tokens and containers

extends Control

var token_comp = preload("res://components/token.tscn") #token component
@onready var dr = $"../.." #to get before canvas layer for get_global_mouse_position()

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.drag_drop_canvas_layer = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#fix when component is not moved back after drag and drop finishes
func _unhandled_input(event):
	if Input.is_action_just_pressed("mouseleft"):
		Globals.drag_drop_canvas_layer.layer = -1

#drag and drop section

func _can_drop_data(position, data):
	return data is TreeItem
	
func _drop_data(position, data):
	Globals.drag_drop_canvas_layer.layer = -1
	if Globals.draw_layer == null:
		return
	print(data)
	if data.has_meta("character"): #dropping character - create token
		var token = token_comp.instantiate()
		token.get_child(0).position = dr.get_global_mouse_position() #set position of image - UI will follow via remote transform
		var character = data.get_meta("character")
		if character.singleton: #character with linked attributes
			token.character = character
		else:
			token.character = character.duplicate(true)
			token.character.save_as_token = true
			token.character.load_equipped_items_from_equipment()
			token.character.load_attr_modifiers_from_equipment()
		token.set_meta("type", "token")
		Globals.draw_layer.add_child(token)
		Globals.map.add_token(token)
		token.light_mask = Globals.draw_layer.light_mask
		token.fov.shadow_item_cull_mask = Globals.draw_layer.light_mask
		Globals.draw_comp.create_object_on_remote_peers(token)
	if data.has_meta("item_dict"): #dropping item - add to inventory or create container
		print("item drop")
		var item_dict = data.get_meta("item_dict")
		var new_item_dict = item_dict.duplicate(true)
		new_item_dict["equipped"] = false
		if data.has_meta("inventory"): #dragging from inventory - remove from old
			var inventory = data.get_meta("inventory")
			if item_dict["equipped"]: #unequip
				var char = data.get_meta("item_char")
				char.unequip_item(item_dict)
			var item_pos
			for i in inventory.size():
				if is_same(inventory[i], item_dict): #remove from inventory array
					inventory.remove_at(i)
					item_pos = i
					break
			if data.has_meta("item_char"):
				Globals.draw_comp.synch_object_inventory_remove.rpc(Globals.draw_comp.get_path_to(data.get_meta("item_char").token), item_dict, item_pos)
				data.get_meta("item_char").emit_signal("inv_changed")
			elif data.has_meta("item_container"):
				Globals.draw_comp.synch_object_inventory_remove.rpc(Globals.draw_comp.get_path_to(data.get_meta("item_container")), item_dict, item_pos)
				data.get_meta("item_container").emit_signal("inv_changed")
		var mouse_pos = dr.get_global_mouse_position()
		var clicked = dr.get_clicked(mouse_pos)
		print(clicked)
		if clicked != null:
			print("clicked found")
			if "character" in clicked: #dropped on character
				clicked.character.items.append(new_item_dict)
				Globals.draw_comp.synch_object_inventory_add.rpc(Globals.draw_comp.get_path_to(clicked), new_item_dict)
				clicked.character.emit_signal("inv_changed")
				return
			elif clicked.has_meta("inventory"): #dropped on container
				clicked.get_meta("inventory").append(new_item_dict)
				Globals.draw_comp.synch_object_inventory_add.rpc(Globals.draw_comp.get_path_to(clicked), new_item_dict)
				clicked.emit_signal("inv_changed")
		#empty or not character/container - create container
		print("create container")
		var container = Panel.new() 
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.size = Vector2(70,70)
		if Globals.snapping:
			container.position = round(mouse_pos/(70/Globals.snappingFraction))*(70/Globals.snappingFraction) #snap to grid
		else:
			container.position = mouse_pos
		container.set_meta("inventory", [new_item_dict])
		container.set_meta("type", "container")
		container.add_user_signal("inv_changed")
		Globals.draw_layer.add_child(container)
		Globals.draw_comp.create_object_on_remote_peers(container)

#set drag_drop_layer to back on drag end - does not trigger when dragging from other windows
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		print("notification - drag end")
		Globals.drag_drop_canvas_layer.layer = -1
	
