#Author: Vladimír Horák
#Desc:
#Script for controlling Character sheet GUI

extends Window

var SelectedEdit

var character: Character

var bar_setting = load("res://components/bar_setting.tscn")
var attr_bubble_setting = load("res://components/attr_bubble_setting.tscn")
var macro_setting = load("res://components/macro_setting.tscn")

@onready var inventory_sheet = $TabContainer/Inventory/Inventory
@onready var equipment_slot_settings = $TabContainer/Inventory/EquipSlotSettings

@onready var name_line_edit = $TabContainer/Attributes/MarginContainer/ScrollContainer/VBoxContainer/FlowContainer/Name_LineEdit
@onready var attribute_list = $TabContainer/Attributes/MarginContainer/ScrollContainer/VBoxContainer
@onready var macro_list = $TabContainer/Attributes/MarginContainer2/ScrollContainer/VBoxContainer/MacroVBoxContainer
@onready var shape = $TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeFlowContainer/OptionButton
@onready var bars = $TabContainer/Token/MarginContainer2/VBoxContainer/PanelContainer/VBoxContainer/BarsVBoxContainer
@onready var attr_bubbles = $TabContainer/Token/MarginContainer2/VBoxContainer/PanelContainer2/VBoxContainer/AttrVBoxContainer

@onready var empty_style = StyleBoxEmpty.new()
var token: Control

#called even before ready
func _enter_tree():
	token = $TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/TokenPreview/ScrollContainer/Token
	token.character = character

# Called when the node enters the scene tree for the first time.
func _ready():
	load_character()
	
	character.connect("attr_modifier_applied", on_attr_modifier_applied)
	character.apply_modifiers() #sets tooltips of modified attributes
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_requested():
	if not character.save_as_token:
		character.save()
	print("closing subwindow")
	if $PopupButton.visible == false:
		print("closing popped up subwindow")
		var view = get_parent().get_viewport()
		print(view)
		print(view.gui_embed_subwindows)
		view.set_embedding_subwindows(false)
		self.hide()
		self.queue_free()
		view.set_embedding_subwindows(true)
	else:
		print("closing embedded subwindow")
		self.queue_free()
		
		
#func _on_focus_exited():
#	if mode == Window.MODE_MINIMIZED:
#		print("TODO - minimizing bugged - closing instead")
##		mode = Window.MODE_WINDOWED
##		self.queue_free()


func _on_popup_button_pressed():
	$PopupButton.visible = false #hide button
	#recreate window with embedding disabled
	var parent = self.get_parent()
	parent.get_viewport().set_embedding_subwindows(false)
	parent.remove_child(self)
	parent.add_child(self)
	parent.get_viewport().set_embedding_subwindows(true)


func _on_add_attribute_button_pressed():
	if character.attributes.has(name_line_edit.text):
		print("character already has " + name_line_edit.text + " attribute")
		return
	character.attributes[name_line_edit.text] = ["", ""]
	add_attribute_to_attribute_list(name_line_edit.text, ["", ""])


func add_attribute_to_attribute_list(name: String, value: Array):
	var flow = HBoxContainer.new()
	var text_edit = LineEdit.new()
	#attribute name LineEdit
	text_edit.text = name
	text_edit.add_theme_stylebox_override("Normal", empty_style)
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	text_edit.set_meta("attr", name)
	text_edit.connect("focus_entered", on_edit_focus_entered)
	text_edit.connect("text_submitted", _on_attr_name_edit_text_submitted)
	flow.add_child(text_edit)
	#attribute value TextEdit
	text_edit = TextEdit.new()
	text_edit.text = value[0]
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	text_edit.scroll_fit_content_height = true
	text_edit.connect("focus_entered", on_edit_focus_entered)
	text_edit.connect("text_changed", _on_attr_val_text_changed)
	flow.add_child(text_edit)
	#modified attribute value TextEdit (attribute modified by attribute modifiers)
	text_edit = TextEdit.new()
	text_edit.text = value[1] #might be modified later
	text_edit.editable = false
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	text_edit.scroll_fit_content_height = true
	text_edit.tooltip_text = value[1]
	flow.add_child(text_edit)
	attribute_list.add_child(flow)


func _on_add_macro_button_pressed():
	var new_marco_setting = macro_setting.instantiate()
	new_marco_setting.character_sheet = self
	var name = new_marco_setting.get_valid_macro_name(new_marco_setting.macro_dict["name"])
	new_marco_setting.macro_dict["name"] = name
	if macro_list.get_child_count() != 0:
		new_marco_setting.macro_dict["ord"] = macro_list.get_child(macro_list.get_child_count() - 1).macro_dict["ord"] + 1
	macro_list.add_child(new_marco_setting)
	character.macros[name] = new_marco_setting.macro_dict

#loads character from resource to character sheet
func load_character():
	#name
	title = character.name + " - Character sheet"
	#attributes
	for attribute in character.attributes:
		add_attribute_to_attribute_list(attribute, character.attributes[attribute])
		
		
	#macros
	for macro_dict_key in character.macros:
		var macro = macro_setting.instantiate()
		macro.macro_dict = character.macros[macro_dict_key]
		macro_list.add_child(macro)
	#order macross
	for macro in macro_list.get_children():
		macro_list.move_child(macro, macro.macro_dict["ord"])
		
	#load token settings
	for entry in Globals.tokenShapeDict:
		shape.add_item(entry)
		if entry == character.token_shape:
			shape.select(shape.item_count-1)
	token.custom_minimum_size = character.token_size
	token.select()
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeSizeFlowContainer/ShapeSizeXSpinBox.value = character.token_size.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeSizeFlowContainer/ShapeSizeYSpinBox.value = character.token_size.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeScaleFlowContainer/ShapeScaleXSpinBox.value = character.token_scale.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeScaleFlowContainer/ShapeScaleYSpinBox.value = character.token_scale.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/BorderFlowContainer/BorderWidthSpinBox.value = character.token_outline_width
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/BorderFlowContainer/BorderColorPickerButton.color = character.token_outline_color
	var texture = load(character.token_texture)
	if texture != null:
		$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImagePanelContainer/ImageTextureRect.texture = texture
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageOffsetFlowContainer/ImageOffsetXSpinBox.value = character.token_texture_offset.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageOffsetFlowContainer/ImageOffsetYSpinBox.value = character.token_texture_offset.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageScaleFlowContainer/ImageScaleXSpinBox.value = character.token_texture_scale.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageScaleFlowContainer/ImageScaleYSpinBox.value = character.token_texture_scale.y
	
	
	#bars
	for bar_data in character.bars:
		var bar = bar_setting.instantiate()
		bar.bar_dict = bar_data
		bars.add_child(bar)
	character.emit_signal("bars_changed")
	
	#attr_bubbles
	for attr_data in character.attr_bubbles:
		var attr = attr_bubble_setting.instantiate()
		attr.attr_dict = attr_data
		attr_bubbles.add_child(attr)
# ================================= section of token editor =====================================


func _on_option_button_item_selected(index):
	character.token_shape = shape.get_item_text(index)
	character.emit_signal("token_changed", true)


func _on_shape_size_x_spin_box_value_changed(value):
	character.token_size.x = value
	token.custom_minimum_size = character.token_size * character.token_scale
	character.emit_signal("token_changed", false)

func _on_shape_size_y_spin_box_value_changed(value):
	character.token_size.y = value
	token.custom_minimum_size = character.token_size * character.token_scale
	character.emit_signal("token_changed", false)


func _on_shape_scale_x_spin_box_value_changed(value):
	character.token_scale.x = value
	token.custom_minimum_size = character.token_size * character.token_scale
	character.emit_signal("token_changed", false)


func _on_shape_scale_y_spin_box_value_changed(value):
	character.token_scale.y = value
	token.custom_minimum_size = character.token_size * character.token_scale
	character.emit_signal("token_changed", false)

func _on_border_width_spin_box_value_changed(value):
	character.token_outline_width = value
	character.emit_signal("token_changed", false)
	
func _on_border_color_picker_button_color_changed(color):
	character.token_outline_color = color
	character.emit_signal("token_changed", false)

func _on_browse_image_button_pressed():
	$TokenImageFileDialog.popup()


func _on_token_image_file_dialog_file_selected(path):
	var texture = load(path)
	character.token_texture = path
	if texture != null:
		$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImagePanelContainer/ImageTextureRect.texture = texture
	character.emit_signal("token_changed", false)


func _on_image_offset_x_spin_box_value_changed(value):
	character.token_texture_offset.x = value
	character.emit_signal("token_changed", false)


func _on_image_offset_y_spin_box_value_changed(value):
	character.token_texture_offset.y = value
	character.emit_signal("token_changed", false)


func _on_image_scale_x_spin_box_value_changed(value):
	character.token_texture_scale.x = value
	character.emit_signal("token_changed", false)


func _on_image_scale_y_spin_box_value_changed(value):
	character.token_texture_scale.y = value
	character.emit_signal("token_changed", false)


# Bar settings
func _on_add_bar_button_pressed():
	var bar = bar_setting.instantiate()
	character.bars.insert(0, bar.bar_dict)
	bars.add_child(bar)
	character.emit_signal("bars_changed")


func _on_attr_name_edit_text_submitted(new_text):
	var old_text = SelectedEdit.get_meta("attr")
	if character.attributes.has(new_text): #already exists - set text back to old
		SelectedEdit.text = old_text
	else:
		character.attributes[new_text] = character.attributes[old_text]
		character.attributes.erase(old_text)

func on_edit_focus_entered():
	SelectedEdit = gui_get_focus_owner()
	
func _on_attr_val_text_changed():
	var attr = SelectedEdit.get_parent().get_child(0).text
	var new_text = SelectedEdit.text
	character.attributes[attr][0] = new_text
	character.apply_modifiers_to_attr(attr)
	character.emit_signal("attr_updated", attr)
	
# Attribute Bubble settings
func _on_add_attr_button_pressed():
	var attr = attr_bubble_setting.instantiate()
	character.attr_bubbles.insert(0, attr.attr_dict)
	attr_bubbles.add_child(attr)
	character.emit_signal("attr_bubbles_changed")

func on_attr_modifier_applied(attribute: StringName, tooltip):
	for attr in attribute_list.get_children():
		var name_le = attr.get_child(0)
		if name_le != null:
			if name_le.get_meta("attr") == attribute:
				attr.get_child(2).text = character.attributes[attribute][1]
				print("set_tooltip: ", tooltip)
				attr.get_child(2).tooltip_text = tooltip
				return
