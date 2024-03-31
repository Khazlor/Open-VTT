extends PanelContainer

var char_sheet

var slot_side = 0 # 0 == left, 1 == middle, 2 == right

var equip_slot_dict = {
	"name": "",
	"image": "",
	"categories": [],
	"item": null
	}

@onready var parent = self.get_parent()

@onready var dialog = $TokenImageFileDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	print("char sheet: ", char_sheet)
	$VBoxContainer/HBoxContainer/SlotName.text = equip_slot_dict["name"]
	var image = Globals.load_texture(equip_slot_dict["image"])
	if image != null:
		$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer/PanelContainer/ImageTextureButton.texture_normal = image
	var str = "" 
	for category in equip_slot_dict["categories"]:
		if str == "":
			str = category
		else:
			str = str + ", " + category
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer2/CategoriesLineEdit.text = str


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_slot_name_text_submitted(new_text):
	equip_slot_dict["name"] = new_text
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, self.get_index(), -1, equip_slot_dict, false, false)


func _on_add_button_pressed():
	var new_equip_slot_settings = self.duplicate(5)
	new_equip_slot_settings.char_sheet = char_sheet
	new_equip_slot_settings.equip_slot_dict = equip_slot_dict.duplicate(true)
	char_sheet.character.equip_slots[slot_side].insert(self.get_index()+1, new_equip_slot_settings.equip_slot_dict)
	add_sibling(new_equip_slot_settings)
	char_sheet.character.emit_signal("equip_slots_changed", new_equip_slot_settings.equip_slot_dict, slot_side, true)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, self.get_index()+1, -1, new_equip_slot_settings.equip_slot_dict, true, false)


func _on_move_up_button_pressed():
	var i = self.get_index()
	if i == 0: # first - move to back
		parent.move_child(self, -1)
		char_sheet.character.equip_slots[slot_side].pop_front()
		char_sheet.character.equip_slots[slot_side].append(equip_slot_dict)
	else:
		parent.move_child(self, i - 1)
		char_sheet.character.equip_slots[slot_side][i] = char_sheet.character.equip_slots[slot_side][i - 1]
		char_sheet.character.equip_slots[slot_side][i - 1] = equip_slot_dict
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, i, self.get_index(), equip_slot_dict, false, false)


func _on_move_down_button_pressed():
	var i = self.get_index()
	if i == char_sheet.character.equip_slots[slot_side].size() - 1: # last - move to front
		parent.move_child(self, 0)
		char_sheet.character.equip_slots[slot_side].pop_back()
		char_sheet.character.equip_slots[slot_side].push_front(equip_slot_dict)
	else:
		parent.move_child(self, self.get_index() + 1)
		char_sheet.character.equip_slots[slot_side][i] = char_sheet.character.equip_slots[slot_side][i + 1]
		char_sheet.character.equip_slots[slot_side][i + 1] = equip_slot_dict
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, i, self.get_index(), equip_slot_dict, false, false)


func _on_remove_button_pressed():
	var i = self.get_index()
	char_sheet.character.equip_slots[slot_side].remove_at(i)
	self.queue_free()
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, i, -1, equip_slot_dict, false, true)


func _on_image_texture_button_pressed():
	dialog.popup()


func _on_token_image_file_dialog_file_selected(path):
	path = await Globals.lobby.handle_file_transfer(path)
	equip_slot_dict["image"] = path
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer3/PanelContainer/ImageTextureButton.texture_normal = Globals.load_texture(path)
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, self.get_index(), -1, equip_slot_dict, false, false)

func _on_categories_line_edit_text_submitted(new_text):
	print(new_text)
	var category_strings = new_text.split(",", false)
	print(category_strings)
	var new_categories = []
	for string in category_strings:
		print(string)
		string.strip_edges()
		new_categories.append(string)
	equip_slot_dict["categories"] = new_categories
	char_sheet.character.emit_signal("equip_slots_changed", equip_slot_dict, slot_side, false)
	char_sheet.character.emit_signal("synch_equip_slot", slot_side, self.get_index(), -1, equip_slot_dict, false, false)

func _on_slot_name_focus_exited():
	if $VBoxContainer/HBoxContainer/SlotName.text != equip_slot_dict["name"]:
		_on_slot_name_text_submitted($VBoxContainer/HBoxContainer/SlotName.text)


func _on_categories_line_edit_focus_exited():
	_on_categories_line_edit_text_submitted($VBoxContainer/MarginContainer/FlowContainer/HBoxContainer2/CategoriesLineEdit.text)
