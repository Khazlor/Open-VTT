#Author: Vladimír Horák
#Desc:
#Script controlling Map settings tab in Toolpanel

extends MarginContainer

#grid object
@onready var grid = $"../../../../../../ParallaxBackground/ParallaxLayer/Sprite2D"
@onready var darkness = $"../../../../../../Darkness"
@onready var layers = $"../../../../../../CanvasLayer/Layers"
@onready var fov = $"../../../../../../FovCanvasLayer/FovColorRect"

var world

signal fov_opacity_changed(value)

# Called when the node enters the scene tree for the first time.
func _ready(token_fov = true):
	#load map settings
	#grid
	grid.visible = Globals.new_map.grid_enable
	grid.texture.gradient.set_offset(1, 1 - Globals.new_map.grid_thickness)
	grid.texture.gradient.set_color(1, Globals.new_map.grid_color)
	grid.texture.height = Globals.new_map.grid_size
	grid.texture.width = Globals.new_map.grid_size
	
	#darkness and fov
	darkness.visible = Globals.new_map.darkness_enable
	Globals.BG_ColorRect.color = Globals.new_map.background_color
	fov.visible = Globals.new_map.fov_enable
	print(token_fov)
	if token_fov:
		emit_signal("fov_opacity_changed", Globals.new_map.fov_opacity)
	if not Globals.lobby.check_is_server():  #client
		darkness.color = Globals.new_map.darkness_color
		if darkness.visible:
			Globals.BG_ColorRect.color = Globals.new_map.darkness_color
		return
	else:
		darkness.color = Globals.new_map.DM_darkness_color
		if darkness.visible:
			Globals.BG_ColorRect.color = Globals.new_map.DM_darkness_color
	$ScrollContainer/VBoxContainer/BackgroundColor/BackgroundColorPickerButton.color = Globals.new_map.background_color
	$ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/GridEnable.button_pressed = grid.visible
	$ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/Thickness/HSlider.value = 1 - grid.texture.gradient.get_offset(1)
	$ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/Color/GridColorPickerButton.color = grid.texture.gradient.get_color(1)
	$"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/Grid Size px/GridSizePxSpinBox".value = Globals.new_map.grid_size
	$"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/Grid Size Units/GridSizeUnitSpinBox".value = Globals.new_map.unit_size
	$ScrollContainer/VBoxContainer/CollapsibleContainer/Container/GridContainer/Units/LineEdit.text = Globals.new_map.unit
	
	$"ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/Light and Shadow/Darkness Enable".button_pressed = Globals.new_map.darkness_enable
	$"ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/Light and Shadow/Darkness Color/DarknessColorPickerButton".color = Globals.new_map.darkness_color
	$"ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/Light and Shadow/DM Darkness Color/DmDarknessColorPickerButton".color = Globals.new_map.DM_darkness_color
	$ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/FovContainer/FovEnable.button_pressed = Globals.new_map.fov_enable
	$ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/FovContainer/Opacity/OpacityHSlider.value = Globals.new_map.fov_opacity
	$ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/FovContainer/Color/FovColorPickerButton.color = Globals.new_map.fov_color

@rpc("authority", "call_remote", "reliable")
func set_map_setting_on_other_peers(property, value):
	Globals.new_map.set(property, value) #set property
	print("property set: ", property)
	if property == "fov_opacity":
		_ready() #apply properties and set token fov opacity
	else:
		_ready(false) #apply properties
	

func _on_background_color_picker_button_color_changed(color):
	if not Globals.new_map.darkness_enable:
		Globals.BG_ColorRect.color = color
	Globals.new_map.background_color = color
	set_map_setting_on_other_peers.rpc("background_color", color)

func _on_grid_enable_toggled(button_pressed):
	grid.visible = button_pressed
	Globals.new_map.grid_enable = button_pressed
	set_map_setting_on_other_peers.rpc("grid_enable", button_pressed)
	

func _on_h_slider_value_changed(value):
	grid.texture.gradient.set_offset(1, 1 - value)
	Globals.new_map.grid_thickness = value
	set_map_setting_on_other_peers.rpc("grid_thickness", value)


func _on_grid_color_picker_button_color_changed(color):
	grid.texture.gradient.set_color(1, color)
	Globals.new_map.grid_color = color
	set_map_setting_on_other_peers.rpc("grid_color", color)


func _on_grid_size_px_spin_box_value_changed(value):
	grid.texture.height = value
	grid.texture.width = value
	Globals.new_map.grid_size = value
	set_map_setting_on_other_peers.rpc("grid_size", value)


func _on_grid_size_unit_spin_box_value_changed(value):
	Globals.new_map.unit_size = value
	set_map_setting_on_other_peers.rpc("unit_size", value)


func _on_line_edit_text_submitted(new_text):
	Globals.new_map.unit = new_text
	set_map_setting_on_other_peers.rpc("unit", new_text)


func _on_darkness_enable_toggled(button_pressed):
	Globals.new_map.darkness_enable = button_pressed
	darkness.visible = button_pressed
	if button_pressed: #set backgroud color to darkness
		if Globals.lobby.check_is_server():
			Globals.BG_ColorRect.color = Globals.new_map.DM_darkness_color
		else:
			Globals.BG_ColorRect.color = Globals.new_map.darkness_color
	else:
		Globals.BG_ColorRect.color = Globals.new_map.background_color
	set_map_setting_on_other_peers.rpc("darkness_enable", button_pressed)

func _on_darkness_color_picker_button_color_changed(color):
	if not Globals.lobby.check_is_server():
		darkness.color = color
		if Globals.new_map.darkness_enable: #backgroud color is darkness
			Globals.BG_ColorRect.color = color
	Globals.new_map.darkness_color = color
	set_map_setting_on_other_peers.rpc("darkness_color", color)

func _on_dm_darkness_color_picker_button_color_changed(color):
	if Globals.lobby.check_is_server():
		darkness.color = color
		if Globals.new_map.darkness_enable: #backgroud color is darkness
			Globals.BG_ColorRect.color = color
	Globals.new_map.DM_darkness_color = color
	set_map_setting_on_other_peers.rpc("DM_darkness_color", color)


func _on_fov_enable_toggled(button_pressed):
	Globals.new_map.fov_enable = button_pressed
	fov.visible = button_pressed
	if button_pressed:
		layers.set_layers_visibility.rpc()
	else:
		layers.reset_layers_visibility.rpc()
	layers.set_token_visibility.rpc()
	set_map_setting_on_other_peers.rpc("fov_enable", button_pressed)
	

func _on_opacity_h_slider_value_changed(value):
	Globals.new_map.fov_opacity = value
	emit_signal("fov_opacity_changed", value)
	set_map_setting_on_other_peers.rpc("fov_opacity", value)
	

func _on_fov_color_picker_button_color_changed(color):
	fov.color = color
	Globals.new_map.fov_color = color
	set_map_setting_on_other_peers.rpc("fov_color", color)

