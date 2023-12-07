extends Window

var character: Character

@onready var name_line_edit = $TabContainer/Attributes/MarginContainer/VBoxContainer/FlowContainer/Name_LineEdit
@onready var attribute_list = $TabContainer/Attributes/MarginContainer/VBoxContainer
@onready var empty_style = StyleBoxEmpty.new()
var token: Control

#called even before ready
func _enter_tree():
	token = $TabContainer/Token/MarginContainer/VBoxContainer/TokenPreview/ScrollContainer/CustomPolygon
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
	var text_edit = TextEdit.new()
	text_edit.text = name
	text_edit.add_theme_stylebox_override("Normal", empty_style)
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
	flow.add_child(text_edit)
	text_edit = TextEdit.new()
	text_edit.text = value
	text_edit.size_flags_horizontal = text_edit.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 35
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
		
# ================================= section of token editor =====================================

func _on_shape_size_x_spin_box_value_changed(value):
	character.token_size.x = value
	token.pivot_offset.x = value/2 #only in token preview, not on game board
	character.emit_signal("token_changed")

func _on_shape_size_y_spin_box_value_changed(value):
	character.token_size.y = value
	token.pivot_offset.y = value/2 #only in token preview, not on game board
	character.emit_signal("token_changed")


func _on_shape_scale_x_spin_box_value_changed(value):
	character.token_scale.x = value
	character.emit_signal("token_changed")


func _on_shape_scale_y_spin_box_value_changed(value):
	character.token_scale.y = value
	character.emit_signal("token_changed")


func _on_image_offset_x_spin_box_value_changed(value):
	character.token_texture_offset.x = value
	character.emit_signal("token_changed")


func _on_image_offset_y_spin_box_value_changed(value):
	character.token_texture_offset.y = value
	character.emit_signal("token_changed")


func _on_image_scale_x_spin_box_value_changed(value):
	character.token_texture_scale.x = value
	character.emit_signal("token_changed")


func _on_image_scale_y_spin_box_value_changed(value):
	character.token_texture_scale.y = value
	character.emit_signal("token_changed")
