#Author: Vladimír Horák
#Desc:
#Script controlling map_tools - drawing tools on the left side of screen

extends Control
# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.tool = "select"
	Globals.tool_bar = $MarginContainer/VBoxContainer/Select
	
	$VBoxContainer/TextOptions/Panel/VBoxContainer/FontSizeSpinBox.get_line_edit().focus_mode = FOCUS_CLICK
	$VBoxContainer/LineOptions/Panel/VBoxContainer/LineSpinBox.get_line_edit().focus_mode = FOCUS_CLICK
	
	#load settings
	$MarginContainer/VBoxContainer/SnapPanelContainer/HBoxContainer/SnapCheckBox.set_pressed_no_signal(Globals.snapping)
	$MarginContainer/VBoxContainer/SnapPopupPanel/VBoxContainer/SnapFractionOptionButton.selected = Globals.snappingFraction - 1
	Globals.measureTool = 1 #line
	$MarginContainer/VBoxContainer/MeasurePopupPanel/VBoxContainer/HBoxContainer/MeasureAngleSpinBox.set_value_no_signal(Globals.measureAngle)
	$VBoxContainer/TextOptions/Panel/VBoxContainer/FontColorPickerButton.color = Globals.fontColor
	$VBoxContainer/TextOptions/Panel/VBoxContainer/FontSizeSpinBox.set_value_no_signal(Globals.fontSize)
	Globals.font = $VBoxContainer/TextOptions/Panel/VBoxContainer/FontOptionButton.get_item_text(0) #default
	$VBoxContainer/LineOptions/Panel/VBoxContainer/FillColorPickerButton.color = Globals.colorBack
	$VBoxContainer/LineOptions/Panel/VBoxContainer/LineColorPickerButton.color = Globals.colorLines
	$VBoxContainer/LineOptions/Panel/VBoxContainer/LineSpinBox.set_value_no_signal(Globals.lineWidth)
	
	
	

func select_tool_from_index(index: int):
	if index == 0:
		Globals.tool = "rect"
	elif index == 1:
		Globals.tool = "lines"
	elif index == 2:
		Globals.tool = "lines-straight"
	elif index == 3:
		Globals.tool = "circle"

func _on_draw_item_selected(index):
	Globals.tool_mode = "draw"
	select_tool_from_index(index)
	Globals.tool_bar = $MarginContainer/VBoxContainer/Draw


func _on_draw_pressed():
	Globals.tool_mode = "draw"
	var btn = $MarginContainer/VBoxContainer/Draw
	var index = btn.get_selected_id()
	select_tool_from_index(index)
	Globals.tool_bar = btn


func _on_draw_union_item_selected(index: int) -> void:
	Globals.tool_mode = "union"
	select_tool_from_index(index)
	Globals.tool_bar = $MarginContainer/VBoxContainer/Draw_Union


func _on_draw_union_pressed() -> void:
	Globals.tool_mode = "union"
	var btn = $MarginContainer/VBoxContainer/Draw_Union
	var index = btn.get_selected_id()
	select_tool_from_index(index)
	Globals.tool_bar = btn


func _on_draw_subtract_item_selected(index: int) -> void:
	Globals.tool_mode = "subtract"
	select_tool_from_index(index)
	Globals.tool_bar = $MarginContainer/VBoxContainer/Draw_Subtract


func _on_draw_subtract_pressed() -> void:
	Globals.tool_mode = "subtract"
	var btn = $MarginContainer/VBoxContainer/Draw_Subtract
	var index = btn.get_selected_id()
	select_tool_from_index(index)
	Globals.tool_bar = btn

func _on_margin_container_mouse_entered():
	Globals.mouseOverButton = true


func _on_margin_container_mouse_exited():
	Globals.mouseOverButton = false


func _on_select_pressed():
	Globals.tool = "select"
	Globals.tool_bar = $MarginContainer/VBoxContainer/Select


func _on_snap_options_pressed():
	$MarginContainer/VBoxContainer/SnapPopupPanel.visible = not $MarginContainer/VBoxContainer/SnapPopupPanel.visible
	$MarginContainer/VBoxContainer/SnapPanelContainer/HBoxContainer/SnapOptions.get_popup().visible = false


func _on_snap_check_box_toggled(button_pressed):
	Globals.snapping = not Globals.snapping


func _on_snap_fraction_option_button_item_selected(index):
	Globals.snappingFraction = index + 1
	print(Globals.snappingFraction)
	Globals.snappingNearestSize = Globals.new_map.grid_size / Globals.snappingFraction


func _on_measure_options_pressed():
	Globals.tool = "measure"
	$MarginContainer/VBoxContainer/MeasurePopupPanel.visible = not $MarginContainer/VBoxContainer/MeasurePopupPanel.visible
	$MarginContainer/VBoxContainer/HBoxContainer/MeasureOptions.get_popup().visible = false
	Globals.tool_bar = $MarginContainer/VBoxContainer/HBoxContainer/Measure


func _on_measure_pressed():
	Globals.tool = "measure"
	Globals.tool_bar = $MarginContainer/VBoxContainer/HBoxContainer/Measure

func _on_measure_line_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 1


func _on_measure_circle_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 2


func _on_measure_angle_radio_toggled(button_pressed):
	if button_pressed:
		Globals.measureTool = 3


func _on_measure_angle_spinbox_value_changed(value):
	Globals.measureAngle = value


func _on_text_pressed():
	Globals.tool = "text"
	Globals.tool_bar = $MarginContainer/VBoxContainer/Text


func _on_font_option_button_item_selected(index):
	Globals.font = $VBoxContainer/TextOptions/Panel/VBoxContainer/FontOptionButton.get_item_text(index)
	Globals.draw_comp.emit_signal("font_settings_changed", "f")


func _on_font_size_spin_box_value_changed(value):
	Globals.fontSize = value
	Globals.draw_comp.emit_signal("font_settings_changed", "fs")


func _on_font_color_picker_button_color_changed(color):
	Globals.fontColor = color
	Globals.draw_comp.emit_signal("font_settings_changed", "fc")

func _on_line_spin_box_value_changed(value):
	Globals.lineWidth = value
	Globals.draw_comp.emit_signal("line_settings_changed", "lw")


func _on_line_color_picker_button_color_changed(color):
	Globals.colorLines = color
	Globals.draw_comp.emit_signal("line_settings_changed", "lc")


func _on_fill_color_picker_button_color_changed(color):
	Globals.colorBack = color
	Globals.draw_comp.emit_signal("line_settings_changed", "bg")

#func _on_line_color_picker_button_focus_exited():
	#$VBoxContainer/LineOptions/Panel/VBoxContainer/LineColorPickerButton.get_popup().hide()


func _on_turn_order_pressed():
	if Globals.turn_order.visible:
		Globals.turn_order.hide()
	else:
		Globals.turn_order.popup()
