extends PanelContainer

@onready var collapse_button = $VBoxContainer/SpellCard/Collapse
@onready var content = $VBoxContainer/CardContent
var spellbook

var print = false # indicates spellcard is going to be printed in roll_panel - remove some functionality
var cast = false # indicates spellcard is going to be casted in roll_panel - remove some functionality and roll macros

var spell_dict = {}
var card_comp_array = null
var content_loaded = false

var macro_nodes = []
var macros_not_in_card = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_spell_card()
	if print or cast:
		self.get_child(0).free() #remove buttons
		_on_left_mouse_button_pressed()
		collapse_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_left_mouse_button_pressed() -> void:
	print("left")
	if content.visible:
		collapse_button.icon = Globals.icon_folded
		content.visible = false
	else:
		collapse_button.icon = Globals.icon_opened
		if not content_loaded:
			load_spell_card_content()
		content.visible = true


func _on_right_mouse_button_pressed() -> void:
	print("right")
	var popup = spellbook.custom_popup_comp.instantiate()
	popup.items = spellbook.popup_items
	popup.position = DisplayServer.mouse_get_position()
	popup.connect("item_pressed", spellbook._on_context_menu_item_pressed)
	spellbook.current_spellcard = self
	spellbook.add_child(popup)
	

func _on_middle_mouse_button_pressed() -> void:
	print("middle")
	spellbook.character.add_spell_to_prepared(spell_dict, spellbook.spellbook_name)
	#spellbook.character.call_character_function_on_remote_peers_through_token("add_spell_to_prepared", spell_dict, spellbook.spellbook_name)


func _get_drag_data(at_position: Vector2) -> Variant:
	print("get dragged spell")
	return spell_dict
	

func load_spell_card():
	if not spell_dict.has("spellcard_name"):
		return
	var card_dict = Globals.spell_database.get_spellcard_from_db(spell_dict["spellcard_name"])
	
	card_comp_array = str_to_var(card_dict["spellcard_component_array"])
	
	$VBoxContainer/SpellCard/Title.text = spell_dict["spell_name"]
	
	#print("card_arr: ", card_comp_array)
	if card_comp_array == null:
		return
	content.get_parent().custom_minimum_size.x = card_comp_array[0].x
	content.custom_minimum_size = card_comp_array[0]
	content.set_meta("cust_size", card_comp_array[0])
	var style = self.get_theme_stylebox("panel").duplicate()
	self.add_theme_stylebox_override("panel", style) 
	style.bg_color = card_comp_array[1]
	var brightness = 0.2126 * card_comp_array[1][0] +0.7152 * card_comp_array[1][1]+0.0722 * card_comp_array[1][2] #set to be more global, no need to recalculate on each spellcard
	if brightness >= 0.5: # bright bg
		$VBoxContainer/SpellCard/Title.modulate = Color.BLACK
		$VBoxContainer/SpellCard/Collapse.modulate = Color.BLACK
	else: #dark bg
		$VBoxContainer/SpellCard/Title.modulate = Color.WHITE
		$VBoxContainer/SpellCard/Collapse.modulate = Color.WHITE
	#keyword color
	if spell_dict.has("keyword_color") and spell_dict["keyword_color"] != null:
		style.border_color = str_to_var(spell_dict["keyword_color"])
		print(spell_dict["spell_name"], spell_dict["keyword_name"], spell_dict["keyword_color"], self.get_theme_stylebox("panel").border_color, card_comp_array[1])

func load_spell_card_content():
	content_loaded = true
	for dict in card_comp_array[2]:
		var type = dict["type"]
		if type == "label":
			load_label_from_dict(dict)
		elif type == "input":
			load_input_from_dict(dict)
		elif type == "polygon":
			load_polygon_from_dict(dict)
		elif type == "image":
			load_image_from_dict(dict)
	card_comp_array.clear()

func replace_attributes_in_text(text):
	var last_index = text.find('@')
	while last_index != -1:
		#found occurance of @ - replace word with attribute
		var word_len = 0
		for i in range( last_index + 1, text.length()): #find word
			if text[i] == " " or text[i] == "\n" or text[i] == "@":
				break #found end
			word_len += 1
		if word_len > 0:
			var word = text.substr(last_index + 1, word_len)
			text = text.erase(last_index, word_len + 1)
			if spell_dict["spell_attributes"].has(word):
				text = text.insert(last_index, spell_dict["spell_attributes"][word])
				last_index = last_index + spell_dict["spell_attributes"][word].length()#ignore recursive @
			else:
				last_index += word_len
		else:
			last_index += word_len
		last_index = text.find('@',last_index)
	return text
	
func replace_text_by_macro(text):
	print("replacing text by macro:", text)
	print(spell_dict["spell_attributes"])
	if spell_dict["spell_attributes"].has(text):
		return spell_dict["spell_attributes"][text]
	else:
		print("macro not found:", text)
		return ""

func load_label_from_dict(dict):
	var label = Label.new()
	var text: String = dict["text"]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text.begins_with("##"): #macro that gets rolled in new rollpanel item
		text = replace_text_by_macro(text.substr(2))
		macros_not_in_card.append(text)
		label.queue_free() # delete this label
		return
	if text.begins_with("#"): #macro that gets rolled in card
		if cast:
			label.queue_free()
			label = Roll_Panel_Item_Result.new()
			label.fit_content = true
			label.scroll_active = false
			label.bbcode_enabled = true
			label.mouse_filter = Control.MOUSE_FILTER_PASS
		text = replace_text_by_macro(text.substr(1))
		if text != "":
			macro_nodes.append(label)
		label.text = text
	else:
		text = replace_attributes_in_text(text)
		label.text = text
	label.position = dict["pos"]
	label.size = dict["size"]
	if label is Label:
		label.clip_text = true
	content.add_child(label)
	label.add_theme_color_override("font_color", dict["fcolor"])
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
	var textedit = TextEdit.new()
	textedit.position = dict["pos"]
	textedit.size = dict["size"]
	textedit.editable = false
	textedit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var text: String = dict["attr"]
	text = replace_attributes_in_text(text)
	textedit.text = text
	var style = StyleBoxFlat.new()
	style.bg_color = dict["BGcolor"]
	style.border_color = dict["lcolor"]
	style.set_border_width_all(dict["width"])
	textedit.add_theme_stylebox_override("read_only", style)
	textedit.add_theme_stylebox_override("normal", style)
	textedit.add_theme_font_size_override("font_size", dict["fsize"])
	textedit.add_theme_color_override("font_readonly_color", dict["fcolor"])
	textedit.set_meta("dict", dict)
	textedit.z_index = 10
	
	content.add_child(textedit)
	
	return textedit
	
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
	texture.create_from_image(img)
	#if texture = bi:
		#texture = load(character.char_sheet_path + "/" + dict["image"]) 
	#if texture == null:
		#texture = load(Globals.base_dir_path + "/images/Placeholder-1479066.png")
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	
	return image
