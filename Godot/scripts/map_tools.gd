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


func _on_color_picker_button_popup_closed():
	Globals.colorLines = $MarginContainer2/VBoxContainer/ColorPickerButton.color
	get_node("MarginContainer/VBoxContainer/Draw").grab_focus()


func _on_color_picker_button_2_popup_closed():
	Globals.colorBack = $MarginContainer2/VBoxContainer/ColorPickerButton2.color
	get_node("MarginContainer/VBoxContainer/Draw").grab_focus()


func _on_spin_box_value_changed(value):
	Globals.lineWidth = $MarginContainer2/VBoxContainer/SpinBox.value
	get_node("MarginContainer/VBoxContainer/Draw").grab_focus()


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
	$MarginContainer/VBoxContainer/SnapPopupPanel.visible = true




func _on_snap_check_box_toggled(button_pressed):
	Globals.snapping = not Globals.snapping


func _on_snap_fraction_option_button_item_selected(index):
	Globals.snappingFraction = index + 1
