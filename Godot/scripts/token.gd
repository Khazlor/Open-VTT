#Author: Vladimír Horák
#Desc:
#Script controlling token component

extends Control

var character: Character
var token_polygon: Control
var bars: VBoxContainer
var attr_bubbles: VBoxContainer
var bar_bubbles: VBoxContainer
var fov: PointLight2D
var timer: Timer

var in_turn_order: PanelContainer

var edited_attr: String
var max_attr: String

# Called even before ready
func _enter_tree():
	token_polygon = $TokenPolygon
	token_polygon.character = character

# Called when the node enters the scene tree for the first time.
func _ready():
	bars = $UI/Bars
	attr_bubbles = $UI/AttrBubbles
	bar_bubbles = $UI/BarBubbles
	fov = $UI/FovLight
	timer = $UI/Timer
	timer.connect("timeout", timer_update)
	change_bars()
	change_attr_bubbles()
	character.connect("bars_changed", change_bars)
	character.connect("attr_updated", update_bars)
	character.connect("attr_bubbles_changed", change_attr_bubbles)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#sets correct positions of UI elements around token
func UI_set_position():
	var center = get_center_offset()
	#bars
	bars.size.x = token_polygon.size.x * abs(token_polygon.scale.x)
	bars.position = center + Vector2(-(token_polygon.size.x * abs(token_polygon.scale.x))/2, - bars.size.y - token_polygon.size.y/2 - 10)
	fov.position = center
	#attr_bubbles (right side)
	attr_bubbles.size.x = 0
	attr_bubbles.position = center + Vector2(-token_polygon.size.x * abs(token_polygon.scale.x)/2 - attr_bubbles.size.x, - token_polygon.size.y/2)
	#bar_bubbles (left side)
	bar_bubbles.position = center + Vector2(token_polygon.size.x * abs(token_polygon.scale.x)/2 + 10, - token_polygon.size.y/2)
	
	
func get_center_offset():
	var distance = Vector2(0,0).distance_to((token_polygon.size * token_polygon.scale)/2)
	var angle = Vector2(0,0).angle_to_point((token_polygon.size * token_polygon.scale)/2) + token_polygon.rotation
	var center = Vector2(distance * cos(angle), distance * sin(angle))
	return center
	
	
func change_bars():
	var flatstyle = StyleBoxFlat.new()
	for child in bars.get_children():
		child.queue_free()
	for child in bar_bubbles.get_children():
		child.queue_free()
	for bar_data in character.bars:
		var bar = ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		bar.use_parent_material = true
		bar.self_modulate = bar_data["color"]
		bar.custom_minimum_size.y = bar_data["size"]
		if character.attributes.has(bar_data["attr1"]):
			bar.value = character.attributes[bar_data["attr1"]][1].to_float()
		if character.attributes.has(bar_data["attr2"]):
			bar.max_value = character.attributes[bar_data["attr2"]][1].to_float()
		bar.show_percentage = false
		bars.add_child(bar)
		var text = Label.new()
		text.use_parent_material = true
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if character.attributes.has(bar_data["attr1"]):
			text.text = str(character.attributes[bar_data["attr1"]][1].to_float()) + "/" + str(bar.max_value)
		else:
			text.text = "0/" + str(bar.max_value)
		text.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		text.add_theme_font_size_override("t", bar.custom_minimum_size.y)
		bar.add_child(text)
		#bar bubble
		var le = LineEdit.new()
		le.set_meta("attr", bar_data["attr1"])
		le.set_meta("attr2", bar_data["attr2"])
		le.use_parent_material = true
		le.add_theme_constant_override("minimum_character_width", -1) #shrinks lineedit
		le.expand_to_text_length = true
		le.select_all_on_focus = true
		le.text = str(bar.value)
		le.connect("text_submitted", bar_bubble_submit)
		le.connect("focus_entered", on_le_focus_entered)
		le.add_theme_stylebox_override("normal", flatstyle)
		le.self_modulate = bar.self_modulate
		bar_bubbles.add_child(le)
	timer.start(0.01) # UI_set_position() after timer
	
func update_bars(attr: StringName):
	for i in range(character.bars.size()):
		var bar_data = character.bars[i]
		if bar_data["attr2"] == attr:
			var bar = bars.get_child(i)
			bar.max_value = character.attributes[attr][1].to_float()
			bar.get_child(0).text = str(character.attributes[attr][1].to_float()) + "/" + str(bar.max_value) #label
		if bar_data["attr1"] == attr:
			var bar = bars.get_child(i)
			bar.value = character.attributes[attr][1].to_float()
			bar.get_child(0).text = str(character.attributes[attr][1].to_float()) + "/" + str(bar.max_value) #label
			bar_bubbles.get_child(i).text = str(character.attributes[attr][1].to_float())
	for i in range(character.attr_bubbles.size()):
		var attr_bubble = character.attr_bubbles[i]
		if attr_bubble["name"] == attr:
			attr_bubbles.get_child(i).get_meta("text").text = character.attributes[attr][1]
	#update initiative
	if attr == "initiative":
		if in_turn_order == null:
			in_turn_order = Globals.turn_order.create_item(self)
		else:
			in_turn_order.update() #TODO
			
func change_attr_bubbles():
	for child in attr_bubbles.get_children():
		child.queue_free()
	for attr_data in character.attr_bubbles:
		if character.attributes.has(attr_data["name"]): #if not in attributes - do not add
			if attr_data["edit"]: #editable - lineedit
				var le = LineEdit.new()
				le.set_meta("attr", attr_data["name"])
				le.use_parent_material = true
				le.add_theme_constant_override("minimum_character_width", -1) #shrinks lineedit
				le.expand_to_text_length = true
				le.flat = true
				le.text = character.attributes[attr_data["name"]][1]
				var image = load(attr_data["icon"])
				if image != null:
					le.right_icon = load(attr_data["icon"])
				image = load(attr_data["image"])
				if image != null:
					var c = PanelContainer.new()
					c.use_parent_material = true
					var s = StyleBoxTexture.new()
					s.texture = image
					c.add_theme_stylebox_override("panel", s)
					c.add_child(le)
					c.set_meta("text", le)
					attr_bubbles.add_child(c)
				else:
					le.set_meta("text", le)
					attr_bubbles.add_child(le)
			else: #not editable - label -- disabled lineedit grays out icon (did not find theme override for disabled icons)
				var hb = HBoxContainer.new()
				hb.use_parent_material = true
				var label = Label.new()
				label.use_parent_material = true
				label.text = character.attributes[attr_data["name"]][1]
				hb.add_child(label)
				var image = load(attr_data["icon"])
				if image != null:
					var icon = TextureRect.new()
					icon.use_parent_material = true
					icon.texture = image
					icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
					icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
					hb.add_child(icon)
				image = load(attr_data["image"])
				if image != null:
					var c = PanelContainer.new()
					c.use_parent_material = true
					var s = StyleBoxTexture.new()
					s.texture = image
					c.add_theme_stylebox_override("panel", s)
					c.add_child(hb)
					c.set_meta("text", label)
					attr_bubbles.add_child(c)
				else:
					hb.set_meta("text", label)
					attr_bubbles.add_child(hb)
			
	timer.start(0.01) # UI_set_position() after timer


func bar_bubble_submit(new_text):
	if character.attributes.has(edited_attr):
		var s = character.attributes[edited_attr][1]
		if new_text[0] == '+': #add to attribute
			if new_text[1] == '+': #ignore max
				character.attributes[edited_attr][1] = str(s.to_float() + new_text.erase(0,1).to_float())
			else:
				if max_attr.is_empty() or not character.attributes.has(max_attr): # no max
					character.attributes[edited_attr][1] = str(s.to_float() + new_text.to_float())
				else:
					var max = character.attributes[max_attr][1].to_float()
					var n = s.to_float() + new_text.to_float()
					if n > max:
						character.attributes[edited_attr][1] = str(max)
					else:
						character.attributes[edited_attr][1] = str(n)
		elif new_text[0] == '-': #subtract from attribute
			character.attributes[edited_attr][1] = str(s.to_float() + new_text.to_float())
		elif new_text[0] == '*': #multiply attribute
			if new_text[1] == '*': #ignore max
				character.attributes[edited_attr][1] = str(s.to_float() * new_text.erase(0,2).to_float())
			else:
				if max_attr.is_empty() or not character.attributes.has(max_attr): # no max
					character.attributes[edited_attr][1] = str(s.to_float() * new_text.erase(0,1).to_float())
				else:
					var max = character.attributes[max_attr][1].to_float()
					var n = s.to_float() * new_text.erase(0,1).to_float()
					if n > max:
						character.attributes[edited_attr][1] = str(max)
					else:
						character.attributes[edited_attr][1] = str(n)
		elif new_text[0] == '/': #divide attribute
			character.attributes[edited_attr][1] = str(s.to_float() / new_text.erase(0,1).to_float())
		else: #set attribute
			character.attributes[edited_attr][1] = new_text
		character.emit_signal("attr_updated", edited_attr)
			
			
func on_le_focus_entered():
	var le = get_viewport().gui_get_focus_owner()
	edited_attr = le.get_meta("attr")
	if le.has_meta("attr2"):
		max_attr = le.get_meta("attr2")
	else:
		max_attr = ""
	
#update position after timer has run out
func timer_update():
	UI_set_position()
	
#set fov opacity and UI visibility for selected token
func select():
	bars.use_parent_material = true
	fov.color.a = 1.0
	attr_bubbles.visible = true
	bar_bubbles.visible = true
	
#set fov opacity and UI visibility for unselected token
func unselect():
	bars.use_parent_material = false
	fov.color.a = Globals.map.fov_opacity
	attr_bubbles.visible = false
	bar_bubbles.visible = false
