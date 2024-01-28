extends Control

@onready var character_sheet = $"../../../../../../../../"

var bar_dict = {
	"name": "bar",
	"size": 5,
	"color": Color.BLACK,
	"attr1": "",
	"attr2": ""
	}

@onready var parent = self.get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer/ColorPickerButton.color = bar_dict["color"]
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer2/SizeSpinBox.value = bar_dict["size"]
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer3/AtrributeLineEdit.text = bar_dict["attr1"]
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer4/Attribute2LineEdit.text = bar_dict["attr2"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_add_button_pressed():
	var new_bar_settings = self.duplicate(5)
	new_bar_settings.bar_dict = bar_dict.duplicate(true)
	character_sheet.character.bars.insert(self.get_index()+1, new_bar_settings.bar_dict)
	add_sibling(new_bar_settings)
	character_sheet.character.emit_signal("bars_changed")


func _on_move_up_button_pressed():
	var i = self.get_index()
	if i == 0: # first - move to back
		parent.move_child(self, -1)
		character_sheet.character.bars.pop_front()
		character_sheet.character.bars.append(bar_dict)
	else:
		parent.move_child(self, i - 1)
		character_sheet.character.bars[i] = character_sheet.character.bars[i - 1]
		character_sheet.character.bars[i - 1] = bar_dict
	character_sheet.character.emit_signal("bars_changed")


func _on_move_down_button_pressed():
	var i = self.get_index()
	if i == character_sheet.character.bars.size() - 1: # last - move to front
		parent.move_child(self, 0)
		character_sheet.character.bars.pop_back()
		character_sheet.character.bars.push_front(bar_dict)
	else:
		parent.move_child(self, self.get_index() + 1)
		character_sheet.character.bars[i] = character_sheet.character.bars[i + 1]
		character_sheet.character.bars[i + 1] = bar_dict
	character_sheet.character.emit_signal("bars_changed")


func _on_remove_button_pressed():
	character_sheet.character.bars.remove_at(self.get_index())
	self.queue_free()
	character_sheet.character.emit_signal("bars_changed")


func _on_color_picker_button_color_changed(color):
	bar_dict["color"] = color
	character_sheet.character.emit_signal("bars_changed")


func _on_size_spin_box_value_changed(value):
	bar_dict["size"] = value
	character_sheet.character.emit_signal("bars_changed")


func _on_atrribute_line_edit_text_submitted(new_text):
	bar_dict["attr1"] = new_text
	character_sheet.character.emit_signal("bars_changed")
	

func _on_attribute_2_line_edit_text_submitted(new_text):
	bar_dict["attr2"] = new_text
	character_sheet.character.emit_signal("bars_changed")


func _on_color_picker_button_picker_created(): #move in front of character sheet
	$VBoxContainer/MarginContainer/FlowContainer/HBoxContainer/ColorPickerButton.get_child(0, true).always_on_top = true
