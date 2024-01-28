#Author: Vladimír Horák
#Desc:
#Script for controlling Character sheet GUI

extends Window

var SelectedEdit

var character: Character

var bar_setting = load("res://componens/bar_setting.tscn")

@onready var name_line_edit = $TabContainer/Attributes/MarginContainer/VBoxContainer/FlowContainer/Name_LineEdit
@onready var attribute_list = $TabContainer/Attributes/MarginContainer/VBoxContainer
@onready var shape = $TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeFlowContainer/OptionButton
@onready var bars = $TabContainer/Token/MarginContainer2/VBoxContainer/PanelContainer/VBoxContainer/BarsVBoxContainer
@onready var empty_style = StyleBoxEmpty.new()
var token: Control

#called even before ready
func _enter_tree():
	token = $TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/TokenPreview/ScrollContainer/Token
	token.character = character

# Called when the node enters the scene tree for the first time.
func _ready():
	load_character()
	print("sheet")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_requested():
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
	character.attributes[name_line_edit.text] = ""
	add_attribute_to_attribute_list(name_line_edit.text, "")
	
func add_attribute_to_attribute_list(name: String, value: String):
	var flow = HBoxContainer.new()
	var text_edit = LineEdit.new()
	text_edit.text = name
	text_edit.add_theme_stylebox_override("Normal", empty_style)
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	text_edit.set_meta("attr", name)
	text_edit.connect("focus_entered", on_edit_focus_entered)
	text_edit.connect("text_submitted", _on_attr_name_edit_text_submitted)
	flow.add_child(text_edit)
	text_edit = TextEdit.new()
	text_edit.text = value
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	text_edit.scroll_fit_content_height = true
	text_edit.connect("focus_entered", on_edit_focus_entered)
	text_edit.connect("text_changed", _on_attr_val_text_changed)
	flow.add_child(text_edit)
	attribute_list.add_child(flow)
	
#loads character from resource to character sheet
func load_character():
	#name
	title = character.name + " - Character sheet"
	#attributes
	for attribute in character.attributes:
		print(attribute + " ==> " + character.attributes[attribute])
		add_attribute_to_attribute_list(attribute, character.attributes[attribute])
		
	#load token settings
	for entry in Globals.tokenShapeDict:
		shape.add_item(entry)
		if entry == character.token_shape:
			shape.select(shape.item_count-1)
	shape.get_child(0, true).always_on_top = true #set option button popup to be always on top - otherwise behind character sheet
	token.custom_minimum_size = character.token_size
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeSizeFlowContainer/ShapeSizeXSpinBox.value = character.token_size.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeSizeFlowContainer/ShapeSizeYSpinBox.value = character.token_size.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeScaleFlowContainer/ShapeScaleXSpinBox.value = character.token_scale.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/ShapeScaleFlowContainer/ShapeScaleYSpinBox.value = character.token_scale.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/BorderFlowContainer/BorderWidthSpinBox.value = character.token_outline_width
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ShapePanel/VBoxContainer/BorderFlowContainer/BorderColorPickerButton.color = character.token_outline_color
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImagePanelContainer/ImageTextureRect.texture = character.token_texture
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageOffsetFlowContainer/ImageOffsetXSpinBox.value = character.token_texture_offset.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageOffsetFlowContainer/ImageOffsetYSpinBox.value = character.token_texture_offset.y
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageScaleFlowContainer/ImageScaleXSpinBox.value = character.token_texture_scale.x
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImageScaleFlowContainer/ImageScaleYSpinBox.value = character.token_texture_scale.y
	
	for bar_data in character.bars:
		var bar = bar_setting.instantiate()
		bar.bar_dict = bar_data
		bars.add_child(bar)
	character.emit_signal("bars_changed")

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
	character.token_texture = load(path)
	$TabContainer/Token/MarginContainer/VBoxContainer/VSplitContainer/VBoxContainer/ImagePanel/VBoxContainer/ImagePanelContainer/ImageTextureRect.texture = character.token_texture
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
	if character.attributes.has(new_text): #already exists
		character.attributes
		SelectedEdit.text = old_text
	else:
		character.attributes[new_text] = character.attributes[old_text]
		character.attributes.erase(old_text)

func on_edit_focus_entered():
	SelectedEdit = gui_get_focus_owner()
	
func _on_attr_val_text_changed():
	var attr = SelectedEdit.get_parent().get_child(0).text
	var new_text = SelectedEdit.text
	character.attributes[attr] = new_text
	character.emit_signal("attr_updated", attr)

