#Author: Vladimír Horák
#Desc:
#Script controlling Object settings tab in Toolpanel

extends MarginContainer

signal object_change(index, value)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
# ========================= emiting signals on value changed ========================

#transform
func _on_pos_x_spin_box_value_changed(value):
	emit_signal("object_change", 0, value)
	
	
func _on_pos_y_spin_box_value_changed(value):
	emit_signal("object_change", 1, value)


func _on_size_x_spin_box_value_changed(value):
	emit_signal("object_change", 2, value)


func _on_size_y_spin_box_value_changed(value):
	emit_signal("object_change", 3, value)


func _on_scale_x_spin_box_value_changed(value):
	emit_signal("object_change", 4, value)


func _on_scale_y_spin_box_value_changed(value):
	emit_signal("object_change", 5, value)


func _on_rot_spin_box_value_changed(value):
	emit_signal("object_change", 6, value)

#light
func _on_cast_light_toggled(button_pressed):
	emit_signal("object_change", 10, button_pressed)
	
	
func _on_offset_x_spin_box_value_changed(value):
	emit_signal("object_change", 11, value)


func _on_offset_y_spin_box_value_changed(value):
	emit_signal("object_change", 12, value)


func _on_resolution_spin_box_value_changed(value):
	emit_signal("object_change", 13, value)


func _on_radius_spin_box_value_changed(value):
	emit_signal("object_change", 14, value)


func _on_color_picker_button_color_changed(color):
	emit_signal("object_change", 15, color)


func _on_energy_spin_box_value_changed(value):
	emit_signal("object_change", 16, value)
	
#shadows
func _on_cast_shadow_toggled(button_pressed):
	emit_signal("object_change", 20, button_pressed)


func _on_one_sided_toggled(button_pressed):
	emit_signal("object_change", 21, button_pressed)


func _on_flip_sides_toggled(button_pressed):
	emit_signal("object_change", 22, button_pressed)
	
# ============================== reading values =================================
#transform
func get_position_x():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Position X/PosXSpinBox".value
	
func get_position_y():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Position Y/PosYSpinBox".value
	
func get_size_x():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Size X/SizeXSpinBox".value
	
func get_size_y():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Size Y/SizeYSpinBox".value
	
func get_scale_x():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Scale X/ScaleXSpinBox".value
	
func get_scale_y():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Scale Y/ScaleYSpinBox".value
	
func get_rotation():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer/Container/TransformContainer/Rotation/RotSpinBox.value
	
#light
func get_cast_light():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/CastLight.button_pressed
	
func get_light_offset_x():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Offset X/OffsetXSpinBox".value
	
func get_light_offset_y():
	return $"ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Offset Y/OffsetYSpinBox".value
	
func get_light_resolution():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Resolution/ResolutionSpinBox.value
	
func get_light_radius():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Radius/RadiusSpinBox.value
	
func get_light_color():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Color/ColorPickerButton.color
	
func get_light_energy():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer2/Container/LightContainer/Energy/EnergySpinBox.value
	
#shadow
func get_cast_shadow():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/ShadowContainer/CastShadow.button_pressed
	
func get_shadow_one_sided():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/ShadowContainer/OneSided.button_pressed
	
func get_shadow_flipped():
	return $ScrollContainer/VBoxContainer/CollapsibleContainer3/Container/ShadowContainer/FlipSides.button_pressed
	

