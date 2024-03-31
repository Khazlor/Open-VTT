extends PanelContainer

var equipment_slot_comp = preload("res://components/equipment_slot.tscn")

@onready var char_sheet = $"../../.."

@onready var left_slots = $MarginContainer/HBoxContainer/SlotsLeft
@onready var middle_slots = $MarginContainer/HBoxContainer/SlotsMiddle
@onready var right_slots = $MarginContainer/HBoxContainer/VBoxContainer/SlotsRight

# Called when the node enters the scene tree for the first time.
func _ready():
	load_slots()
	char_sheet.character.connect("equip_slots_changed", update_slot)
	char_sheet.character.connect("equip_slot_synched", on_equip_slot_synched)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_slot_params(slot):
	for i in char_sheet.character.equip_slots.size():
		for j in char_sheet.character.equip_slots[i].size():
			if is_same(slot, char_sheet.character.equip_slots[i][j]):
				return [i, j]
	return null

func on_equip_slot_synched():
	#clear slots
	for slot in left_slots.get_children():
		left_slots.remove_child(slot)
		slot.queue_free()
	for slot in middle_slots.get_children():
		middle_slots.remove_child(slot)
		slot.queue_free()
	for slot in right_slots.get_children():
		right_slots.remove_child(slot)
		slot.queue_free()
	#recreate slots
	load_slots()

func _on_edit_button_pressed():
	if char_sheet.inventory_sheet.visible: #visible inventory - show settings
		char_sheet.inventory_sheet.visible = false
		char_sheet.equipment_slot_settings.visible = true
	else: #visible settings - show inventory
		char_sheet.equipment_slot_settings.visible = false
		char_sheet.inventory_sheet.visible = true
		

func load_slots():
	for slot_dict in char_sheet.character.equip_slots[0]: #left slots
		var new_slot = equipment_slot_comp.instantiate()
		new_slot.equip_slot_dict = slot_dict
		new_slot.equipment_sheet = self
		left_slots.add_child(new_slot)
	for slot_dict in char_sheet.character.equip_slots[1]: #middle slots
		var new_slot = equipment_slot_comp.instantiate()
		new_slot.equip_slot_dict = slot_dict
		new_slot.equipment_sheet = self
		middle_slots.add_child(new_slot)
	for slot_dict in char_sheet.character.equip_slots[2]: #right slots
		var new_slot = equipment_slot_comp.instantiate()
		new_slot.equip_slot_dict = slot_dict
		new_slot.equipment_sheet = self
		right_slots.add_child(new_slot)

func update_slot(equip_slot_dict, side: int, new: bool):
	print("new slot")
	if new:
		var new_slot = equipment_slot_comp.instantiate()
		new_slot.equip_slot_dict = equip_slot_dict
		if side == 0:
			new_slot.equipment_sheet = self
			left_slots.add_child(new_slot)
		elif side == 1:
			new_slot.equipment_sheet = self
			middle_slots.add_child(new_slot)
		elif side == 2:
			new_slot.equipment_sheet = self
			right_slots.add_child(new_slot)
	else:
		var slots
		if side == 0:
			slots = left_slots.get_children()
		elif side == 1:
			slots = middle_slots.get_children()
		elif side == 2:
			slots = right_slots.get_children()
		for slot in slots:
			if is_same(equip_slot_dict, slot.equip_slot_dict):
				slot.load_slot()
				return
