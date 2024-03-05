extends PanelContainer

var slot_setting_comp = preload("res://components/equip_slot_setting.tscn")

@onready var char_sheet = $"../../.."

@onready var left_slots = $ScrollContainer/VBoxContainer/LeftVBoxContainer/SlotsVBoxContainer
@onready var middle_slots = $ScrollContainer/VBoxContainer/MiddleVBoxContainer/SlotsVBoxContainer
@onready var right_slots = $ScrollContainer/VBoxContainer/RightVBoxContainer/SlotsVBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	#load settings for all slots
	for slot_dict in char_sheet.character.equip_slots[0]: #left slots
		var new_slot = slot_setting_comp.instantiate()
		new_slot.char_sheet = char_sheet
		new_slot.equip_slot_dict = slot_dict
		left_slots.add_child(new_slot)
	for slot_dict in char_sheet.character.equip_slots[1]: #middle slots
		var new_slot = slot_setting_comp.instantiate()
		new_slot.char_sheet = char_sheet
		new_slot.equip_slot_dict = slot_dict
		middle_slots.add_child(new_slot)
	for slot_dict in char_sheet.character.equip_slots[2]: #right slots
		var new_slot = slot_setting_comp.instantiate()
		new_slot.char_sheet = char_sheet
		new_slot.equip_slot_dict = slot_dict
		right_slots.add_child(new_slot)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_left_add_button_pressed():
	var new_slot = slot_setting_comp.instantiate()
	new_slot.char_sheet = char_sheet
	char_sheet.character.equip_slots[0].append(new_slot.equip_slot_dict)
	new_slot.slot_side = 0
	left_slots.add_child(new_slot)
	char_sheet.character.emit_signal("equip_slots_changed", new_slot.equip_slot_dict, 0, true)


func _on_middle_add_button_pressed():
	var new_slot = slot_setting_comp.instantiate()
	new_slot.char_sheet = char_sheet
	char_sheet.character.equip_slots[1].append(new_slot.equip_slot_dict)
	new_slot.slot_side = 1
	middle_slots.add_child(new_slot)
	char_sheet.character.emit_signal("equip_slots_changed", new_slot.equip_slot_dict, 1, true)


func _on_right_add_button_pressed():
	var new_slot = slot_setting_comp.instantiate()
	new_slot.char_sheet = char_sheet
	char_sheet.character.equip_slots[2].append(new_slot.equip_slot_dict)
	new_slot.slot_side = 2
	right_slots.add_child(new_slot)
	char_sheet.character.emit_signal("equip_slots_changed", new_slot.equip_slot_dict, 2, true)
