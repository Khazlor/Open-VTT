#Author: Vladimír Horák
#Desc:
#Script controlling token component

extends Control

var character: Character
var token_polygon: Control
var bars: VBoxContainer
var fov: PointLight2D

# Called even before ready
func _enter_tree():
	token_polygon = $TokenPolygon
	print(token_polygon.size)
	token_polygon.character = character

# Called when the node enters the scene tree for the first time.
func _ready():
	bars = $UI/Bars
	fov = $UI/FovLight
	change_bars()
	character.connect("bars_changed", change_bars)
	character.connect("attr_updated", update_bars)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#sets correct positions of UI elements around token
func UI_set_position():
	var center = get_center_offset()
#	var distance = Vector2(0,0).distance_to((token_polygon.size * token_polygon.scale)/2)
	#bars
	
	bars.size.x = token_polygon.size.x * abs(token_polygon.scale.x)
	bars.position = center + Vector2(-(token_polygon.size.x * abs(token_polygon.scale.x))/2, - bars.size.y - token_polygon.size.y/2 - 10)
	fov.position = center
	
func get_center_offset():
	var distance = Vector2(0,0).distance_to((token_polygon.size * token_polygon.scale)/2)
	var angle = Vector2(0,0).angle_to_point((token_polygon.size * token_polygon.scale)/2) + token_polygon.rotation
	var center = Vector2(distance * cos(angle), distance * sin(angle))
	return center
	
func change_bars():
	for child in bars.get_children():
		child.queue_free()
	for bar_data in character.bars:
		var bar = ProgressBar.new()
		bar.self_modulate = bar_data["color"]
		bar.custom_minimum_size.y = bar_data["size"]
		if character.attributes.has(bar_data["attr1"]):
			bar.value = character.attributes[bar_data["attr1"]].to_float()
		if character.attributes.has(bar_data["attr2"]):
			bar.max_value = character.attributes[bar_data["attr2"]].to_float()
		bar.show_percentage = false
		bars.add_child(bar)
		var text = Label.new()
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.text = str(bar.value) + "/" + str(bar.max_value)
		text.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		text.add_theme_font_size_override("t", bar.custom_minimum_size.y)
		bar.add_child(text)
	UI_set_position()
	
func update_bars(attr: StringName):
	for i in range(character.bars.size()):
		var bar = character.bars[i]
		if bar["attr1"] == attr:
			bars.get_child(i).value = character.attributes[attr].to_float()
			print("value changed: ", attr, character.attributes[attr].to_float())
		if bar["attr2"] == attr:
			bars.get_child(i).max_value = character.attributes[attr].to_float()
			print("max changed: ", attr, character.attributes[attr].to_float())
