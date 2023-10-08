extends Control
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_draw_item_selected(index):
	if index == 0:
		Globals.tool = "rect"
	elif index == 1:
		Globals.tool = "lines"
	elif index == 2:
		Globals.tool = "circle"

func _on_margin_container_mouse_entered():
	Globals.mouseOverButton = true


func _on_margin_container_mouse_exited():
	Globals.mouseOverButton = false


func _on_select_pressed():
	Globals.tool = "select"


func _on_draw_pressed():
	var index = $MarginContainer/VBoxContainer/Draw.get_selected_id()
	if index == 0:
		Globals.tool = "rect"
	elif index == 1:
		Globals.tool = "lines"
	elif index == 2:
		Globals.tool = "circle"


func _on_snap_options_pressed():
	$MarginContainer/VBoxContainer/SnapPopupPanel.visible = not $MarginContainer/VBoxContainer/SnapPopupPanel.visible
	$MarginContainer/VBoxContainer/SnapPanelContainer/HBoxContainer/SnapOptions.get_popup().visible = false


func _on_snap_check_box_toggled(button_pressed):
	Globals.snapping = not Globals.snapping


func _on_snap_fraction_option_button_item_selected(index):
	Globals.snappingFraction = index + 1


func _on_measure_options_pressed():
	Globals.tool = "measure"
	$MarginContainer/VBoxContainer/MeasurePopupPanel.visible = not $MarginContainer/VBoxContainer/MeasurePopupPanel.visible
	$MarginContainer/VBoxContainer/HBoxContainer/MeasureOptions.get_popup().visible = false


func _on_measure_pressed():
	Globals.tool = "measure"

func _on_measure_line_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 1


func _on_measure_circle_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 2


func _on_measure_angle_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 3


func _on_line_edit_text_changed(new_text):
	Globals.measureAngle = int($MarginContainer/VBoxContainer/MeasurePopupPanel/VBoxContainer/HBoxContainer/MeasureAngleLineEdit.text)


func _on_text_pressed():
	Globals.tool = "text"


func _on_font_option_button_item_selected(index):
	Globals.font = $VBoxContainer/TextOptions/Panel/VBoxContainer/FontOptionButton.get_item_text(index) # Replace with function body.


func _on_font_size_spin_box_value_changed(value):
	Globals.fontSize = value


func _on_font_color_picker_button_popup_closed():
	Globals.fontColor = $VBoxContainer/TextOptions/Panel/VBoxContainer/FontColorPickerButton.color


func _on_line_spin_box_value_changed(value):
	Globals.lineWidth = value


func _on_line_color_picker_button_popup_closed():
	Globals.colorLines = $VBoxContainer/LineOptions/Panel/VBoxContainer/LineColorPickerButton.color


func _on_fill_color_picker_button_popup_closed():
	Globals.colorBack = $VBoxContainer/LineOptions/Panel/VBoxContainer/FillColorPickerButton.color


func _on_save_pressed():
	var packed_scene = PackedScene.new()
	packed_scene.pack(get_tree().get_current_scene())
	ResourceSaver.save(packed_scene, "res://my_scene.tscn")


func _on_load_pressed():
	var packed_scene = load("res://my_scene.tscn")
	get_tree().change_scene_to_packed(packed_scene)


