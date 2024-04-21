extends PanelContainer

var equipment_sheet

var equip_slot_dict = {
	"name": "",
	"image": "",
	"categories": [],
	"item": null
	}
	
var tree_item #treeitem in inventory

# Called when the node enters the scene tree for the first time.
func _ready():
	load_slot()
	
	equipment_sheet.char_sheet.character.connect("unequip_item_from_slot", on_unequip_item_from_slot)
	equipment_sheet.char_sheet.character.connect("reload_equip_slot", on_reload_equip_slot)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _get_drag_data(_item_position):
	if equip_slot_dict["item"] != null:
		#place drag and drop layer on top - in case of dragging to map
		Globals.drag_drop_canvas_layer.layer = 2
		var item = equip_slot_dict["item"]
		var preview = Label.new()
		preview.text = item["name"]
		
		#find treeitem in inventory_sheet
		tree_item = equipment_sheet.char_sheet.inventory_sheet.tree.get_item_treeitem(item)
		
		#var object = Object.new() #just to be consistent and be able to set metadata
		#object.set_meta("item_dict", item)
		#object.set_meta("inventory", equipment_sheet.char_sheet.character.equipped_items)
		#object.set_meta("item_char", equipment_sheet.char_sheet.character)
		set_drag_preview(preview)
		return tree_item
	return null

func _can_drop_data(at_position, data):
	if data.has_meta("item_dict"):
		if equip_slot_dict["categories"].is_empty(): # categories empty == any item
			return true
		elif data.get_meta("item_dict")["category"] in equip_slot_dict["categories"]: # if category found
			return true
	return false

func _drop_data(at_position, data):
	#add new item to inventory as equiped - if already in inventory - remove later (possibly equiping from another inventory)
	var item_dict = data.get_meta("item_dict")
	var new_item_dict = item_dict.duplicate(true)
	new_item_dict["equipped"] = true
	equipment_sheet.char_sheet.character.equip_item(new_item_dict)
	if data.has_meta("inventory"): #dragging from inventory - remove dragged item
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
	equipment_sheet.char_sheet.inventory_sheet.tree.add_item_treeitem(new_item_dict, true, equipment_sheet.get_slot_params(equip_slot_dict))
	equip_slot_dict["item"] = new_item_dict
	
	load_slot()
	
	Globals.drag_drop_canvas_layer.layer = -1
	

func load_slot():
	print("loading slot", equip_slot_dict)
	var category_str = "" 
	for category in equip_slot_dict["categories"]:
		if category_str == "":
			category_str = category
		else:
			category_str = category_str + ", " + category
	tooltip_text = ""
	if equip_slot_dict["item"] != null:
		tooltip_text += equip_slot_dict["item"]["name"]
	tooltip_text += equip_slot_dict["name"] + "\nCategories:\n" + category_str
	if equip_slot_dict["item"] != null:
		var texture = Globals.load_texture(equip_slot_dict["item"]["icon"])
		if texture == null: #no item icon - set to default image and set label text
			$Label.text = equip_slot_dict["item"]["name"]
			texture = Globals.load_texture(equip_slot_dict["image"])
		if texture != null:
			var stylebox = StyleBoxTexture.new()
			stylebox.texture = texture
			add_theme_stylebox_override("panel", stylebox)
	else:
		#load background image
		var texture = Globals.load_texture(equip_slot_dict["image"])
		if texture != null:
			var stylebox = StyleBoxTexture.new()
			stylebox.texture = texture
			add_theme_stylebox_override("panel", stylebox)
		else:
			remove_theme_stylebox_override("panel")
		#clear label text
		$Label.text = ""

func on_unequip_item_from_slot(slot):
	print("is same?, ", is_same(slot, equip_slot_dict))
	print(slot)
	print(equip_slot_dict)
	if is_same(slot, equip_slot_dict):
		load_slot()
		return

func on_reload_equip_slot(slot_dict):
	if is_same(slot_dict, equip_slot_dict):
		print("reload slot")
		load_slot()
