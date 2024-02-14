extends PanelContainer

@onready var character_sheet = $"../../../../../../../"

var macro_dict = {
	"name": "macro",
	"icon": "",
	"text": "",
	"in_bar": false,
	"ord": 0, #for ordering
	"colors": [Color(0.7, 0.2, 0.13, 1), Color(0.75, 0.3, 0, 1), Color(0.95, 0.75, 0.2, 1), Color(0, 0, 0, 1)],
	"b_text": "",
	"b_icon": 0,
	"b_text_size": 39,
	"b_icon_size": 50,
	}

@onready var parent = self.get_parent()

@onready var dialog = $ImageFileDialog
@onready var name_le = $VBoxContainer/HBoxContainer/MacroName
@onready var te = $VBoxContainer/MarginContainer/VBoxContainer/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/HBoxContainer/MacroName.text = macro_dict["name"]
	var image = load(macro_dict["icon"])
	if image != null:
		$VBoxContainer/HBoxContainer/IconTextureButton.texture_normal = image
	$VBoxContainer/HBoxContainer/CheckBox.button_pressed = macro_dict["in_bar"]
	te.text = macro_dict["text"]
	$VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/BackgroundColorPickerButton.color = macro_dict["colors"][0]
	$VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer2/BorderColorPickerButton.color = macro_dict["colors"][1]
	$VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer3/TextColorPickerButton.color = macro_dict["colors"][2]
	$VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer4/TextBorderColorPickerButton.color = macro_dict["colors"][3]
	$VBoxContainer/MarginContainer/VBoxContainer/FlowContainer/ButtonTextLineEdit.text = macro_dict["b_text"]
	$VBoxContainer/MarginContainer/VBoxContainer/FlowContainer/IconAlignmentHboxContainer/IconAlignmentOptionButton.selected = macro_dict["b_icon"]
	$VBoxContainer/MarginContainer/VBoxContainer/FlowContainer/TextSizeHboxContainer/TextSizeSpinBox.value = macro_dict["b_text_size"]
	$VBoxContainer/MarginContainer/VBoxContainer/FlowContainer/IconSizeHboxContainer/IconSizeSpinBox.value = macro_dict["b_icon_size"]
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func get_valid_macro_name(name: String):
	var new_name = name
	var i = 1
	while character_sheet.character.macros.has(new_name):
		new_name = name + "_" + str(i)
		i += 1
	return new_name

func _on_macro_name_text_submitted(new_text):
	character_sheet.character.macros.erase(macro_dict["name"])
	var name = get_valid_macro_name(new_text)
	name_le.text = name
	character_sheet.character.macros[name] = macro_dict
	if macro_dict["in_bar"]:
		character_sheet.character.macros_in_bar.erase(macro_dict["name"])
		character_sheet.character.macros_in_bar[name] = macro_dict
	macro_dict["name"] = name
	if macro_dict["in_bar"]:
		character_sheet.character.emit_signal("macro_bar_changed", macro_dict)
	
	
func _on_add_button_pressed():
	var new_macro_settings = self.duplicate(5)
	new_macro_settings.macro_dict = macro_dict.duplicate(true)
	var name = get_valid_macro_name(macro_dict["name"])
	new_macro_settings.macro_dict["name"] = name
	character_sheet.character.macros[name] = new_macro_settings.macro_dict
	if new_macro_settings.macro_dict["in_bar"]:
		character_sheet.character.macros_in_bar[name] = new_macro_settings.macro_dict
		character_sheet.character.emit_signal("macro_bar_changed", macro_dict)
	add_sibling(new_macro_settings)


func _on_move_up_button_pressed():
	var i = self.get_index()
	if i == 0: # first - do nothing - might change later TODO
		return
	else:
		var previous_dict = parent.get_child(i-1).macro_dict
		parent.move_child(self, i - 1)
		var ord = macro_dict["ord"]
		macro_dict["ord"] = previous_dict["ord"]
		previous_dict["ord"] = ord
		if macro_dict["in_bar"] and previous_dict["in_bar"]:
			character_sheet.character.emit_signal("macro_bar_changed", macro_dict)


func _on_move_down_button_pressed():
	var i = self.get_index()
	if i == character_sheet.character.macros.size() - 1: # last - do nothing - might change later TODO
		return
	else:
		var next_dict = parent.get_child(i+1).macro_dict
		parent.move_child(self, self.get_index() + 1)
		var ord = macro_dict["ord"]
		macro_dict["ord"] = next_dict["ord"]
		next_dict["ord"] = ord
		if macro_dict["in_bar"] and next_dict["in_bar"]:
			character_sheet.character.emit_signal("macro_bar_changed", macro_dict)


func _on_remove_button_pressed():
	character_sheet.character.macros.erase(macro_dict.name)
	if macro_dict["in_bar"]:
		character_sheet.character.macros_in_bar.erase(macro_dict.name)
		character_sheet.character.emit_signal("macro_bar_changed", macro_dict)
	self.queue_free()


func _on_icon_texture_button_pressed():
	dialog.popup()


func _on_token_image_file_dialog_file_selected(path):
	macro_dict["icon"] = path
	$VBoxContainer/HBoxContainer/IconTextureButton.texture_normal = load(path)
	if macro_dict["in_bar"]:
			character_sheet.character.emit_signal("macro_bar_changed", macro_dict)


func _on_text_edit_text_changed():
	macro_dict["text"] = te.text


func _on_check_box_toggled(button_pressed):
	if button_pressed == true:
		macro_dict["in_bar"] = true
		character_sheet.character.macros_in_bar[macro_dict["name"]] = macro_dict
	else:
		macro_dict["in_bar"] = false
		character_sheet.character.macros_in_bar.erase(macro_dict["name"])
	character_sheet.character.emit_signal("macro_bar_changed", macro_dict)


func _on_edit_button_pressed():
	$VBoxContainer/MarginContainer.visible = not $VBoxContainer/MarginContainer.visible


func _on_roll_button_pressed():
	print("macro call")
	Globals.roll_panel.execute_macro(macro_dict["text"], character_sheet.character)


func _on_button_text_line_edit_text_changed(new_text):
	macro_dict["b_text"] = new_text
	#TODO call change

func _on_icon_alignment_option_button_item_selected(index):
	macro_dict["b_icon"] = index
	#TODO call change
	
func _on_text_size_spin_box_value_changed(value):
	macro_dict["b_text_size"] = value
	#TODO call change

func _on_icon_size_spin_box_value_changed(value):
	macro_dict["b_icon_size"] = value
	#TODO call change

func _on_background_color_picker_button_color_changed(color):
	macro_dict["colors"][0] = color
	#TODO call change

func _on_border_color_picker_button_color_changed(color):
	macro_dict["colors"][1] = color
	#TODO call change

func _on_text_color_picker_button_color_changed(color):
	macro_dict["colors"][2] = color
	#TODO call change

func _on_text_border_color_picker_button_color_changed(color):
	macro_dict["colors"][3] = color
	#TODO call change

