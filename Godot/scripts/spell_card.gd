extends PanelContainer

@onready var collapse_button = $VBoxContainer/SpellCard/Collapse
@onready var content = $VBoxContainer/CardContent
@onready var context_menu = spellbook.get_node("ContextMenu")
var spellbook


var spell_dict = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_spell_card(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_collapse_toggled(toggled_on: bool) -> void:
	if toggled_on:
		collapse_button.icon = Globals.icon_opened
		content.visible = true
	else:
		collapse_button.icon = Globals.icon_folded
		content.visible = false


func _on_left_mouse_button_pressed() -> void:
	print("left")
	if content.visible:
		collapse_button.icon = Globals.icon_folded
		content.visible = false
	else:
		collapse_button.icon = Globals.icon_opened
		content.visible = true


func _on_right_mouse_button_pressed() -> void:
	print("right")
	context_menu.position = Vector2(get_window().position) + get_global_mouse_position()
	context_menu.show()

func _on_middle_mouse_button_pressed() -> void:
	print("middle")
	spellbook.character_sheet.character.add_spell_to_prepared(spell_dict, null, spellbook.spellbook_name)


func _get_drag_data(at_position: Vector2) -> Variant:
	print("get dragged spell")
	return spell_dict
	

func load_spell_card(spell_card_id):
	#TODO instantiate loaded from spellcard_comp_dict 
	
	var card_dict = Globals.spell_database.get_spellcard_from_db(spell_card_id)
	
	var card_comp_array = str_to_var(card_dict["spellcard_component_array"])
	
	$VBoxContainer/SpellCard/Title.text = spell_dict["spell_name"]
	
	print("card_arr: ", card_comp_array)
	if card_comp_array == null:
		return
	content.custom_minimum_size = Vector2(400, 300)
	content.set_meta("cust_size", card_comp_array[0])
	#self.get_theme_stylebox("panel").bg_color = card_comp_array[1]
	#$VBoxContainer/SpellCard/Title.modulate = card_comp_array[2]
	#$VBoxContainer/SpellCard/Collapse.modulate = card_comp_array[2]
	#for dict in card_comp_array[3]:
		#var type = dict["type"]
		#if type == "label":
			#load_label_from_dict(dict)
		#elif type == "input":
			#load_input_from_dict(dict)
		#elif type == "polygon":
			#load_polygon_from_dict(dict)
		#elif type == "image":
			#load_image_from_dict(dict)
	#apply_zoom()
#
func load_label_from_dict(dict):
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = dict["pos"]
	label.size = dict["size"]
	label.clip_text = true
	content.add_child(label)
	label.add_theme_color_override("font_color", dict["fcolor"])
	label.text = dict["text"]
	var style = StyleBoxFlat.new()
	style.bg_color = dict["BGcolor"]
	style.border_color = dict["lcolor"]
	style.set_border_width_all(dict["width"])
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_font_size_override("font_size", dict["fsize"])
	label.vertical_alignment = dict["valign"]
	label.horizontal_alignment = dict["halign"]
	label.set_meta("dict", dict)
	label.z_index = 1
	return label
	
func load_input_from_dict(dict):
	var scroll = ScrollContainer.new()
	scroll.position = dict["pos"]
	scroll.size = dict["size"]
	
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.add_theme_color_override("font_color", dict["fcolor"])
	label.text = dict["text"]
	var style = StyleBoxFlat.new()
	style.bg_color = dict["BGcolor"]
	style.border_color = dict["lcolor"]
	style.set_border_width_all(dict["width"])
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_font_size_override("font_size", dict["fsize"])
	label.vertical_alignment = dict["valign"]
	label.horizontal_alignment = dict["halign"]
	scroll.set_meta("dict", dict)
	scroll.z_index = 1
	
	scroll.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(scroll)
	
	return scroll
	
func load_polygon_from_dict(dict):
	var polygon = CustomPolygon.new()
	polygon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(polygon)
	polygon.position = dict["pos"]
	polygon.size = dict["size"]
	polygon.points = dict["points"]
	polygon.colorLines = dict["lcolor"]
	polygon.lineWidth = dict["width"]
	polygon.colorBG = dict["BGcolor"]
	polygon.queue_redraw()
	polygon.set_meta("dict", dict)
	return polygon
	
func load_image_from_dict(dict):
	var image = TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	image.position = dict["pos"]
	image.size = dict["size"]
	image.set_meta("dict", dict)
	#TODO load image
	var texture: ImageTexture
	var img: Image = Image.new()
	img.load_jpg_from_buffer(dict["texture"])
	texture.create_from_image(image)
	#if texture = bi:
		#texture = load(character.char_sheet_path + "/" + dict["image"]) 
	#if texture == null:
		#texture = load(Globals.base_dir_path + "/images/Placeholder-1479066.png")
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	
	return image
