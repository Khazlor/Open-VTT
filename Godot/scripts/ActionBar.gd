#Author: Vladimír Horák
#Desc:
#Script for character Macro Action Bar

extends FlowContainer

var characters = []
var macros_in_bar = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.action_bar = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#disconnect character signals on clear 
func disconnect_character_signals():
	for character in characters:
		if character != null:
			character.disconnect("macro_bar_changed", on_macro_bar_changed)
			print("disconnected character ", character)
	characters.clear()

#fills action bar with macros of all selected tokens
func fill_action_bar(selected_tokens = [], reconnect = true):
	print("fill action bar: ", macros_in_bar)
	clear()
	if reconnect:
		macros_in_bar = {}
		disconnect_character_signals()
		for token in selected_tokens: #create list of all macros in bar of selected tokens
			token.character.connect("macro_bar_changed", on_macro_bar_changed)
			print("connected character ", token.character)
			characters.append(token.character)
			macros_in_bar.merge(token.character.macros_in_bar)
	for macro_key in macros_in_bar: #generate buttons for each macro in bar
		var macro = macros_in_bar[macro_key]
		var stylebox = StyleBoxFlat.new()
		var colors = macro["colors"]
		stylebox.bg_color = colors[0]
		stylebox.border_color = colors[1]
		stylebox.set_corner_radius_all(5)
		stylebox.set_border_width_all(macro["border"])
		stylebox.border_blend = true
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", stylebox)
		
		var label = Label.new()
		label.text = macro["b_text"]
		label.add_theme_color_override("font_color", colors[2])
		label.add_theme_color_override("font_outline_color", colors[3])
		label.add_theme_constant_override("outline_size", macro["text_border"])
		label.add_theme_font_override("font", load("res://fonts/Seagram tfb.ttf"))
		label.add_theme_font_size_override("font_size", macro["b_text_size"])
		
		var i = macro["b_icon"] # icon alignment
		if i == 0: # 0 == none
			panel.add_child(label)
		else:
			var tr = TextureRect.new() #icon
			tr.texture = Globals.load_texture(macro["icon"])
			tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size.y = macro["b_icon_size"]
			tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if i == 1: # 1 == left
				var hb = HBoxContainer.new()
				hb.add_child(tr)
				hb.add_child(label)
				panel.add_child(hb)
			elif i == 2: # 2 == center
				tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
				tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
				panel.add_child(tr)
				panel.add_child(label)
			elif i == 3: # 3 == right
				var hb = HBoxContainer.new()
				hb.add_child(label)
				hb.add_child(tr)
				panel.add_child(hb)
		var button = Button.new()
		button.flat = true
		button.connect("pressed", button_pressed.bindv([selected_tokens, macro_key]))
#		button.connect("pressed", button_pressed)
		panel.add_child(button)
		self.add_child(panel)
	
func on_macro_bar_changed():
	print("is server: ",Globals.lobby.check_is_server())
	print("macro_bar_changed")
	fill_action_bar(null, false)
	
func clear():
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
		
#macro in action bar pressed
func button_pressed(selected_tokens = [], macro_key = ""):
	print("pressed")
	for token in selected_tokens:
		print("token")
		if token.character.macros.has(macro_key):
			print("token is executing macro: ", token, " - ", macro_key)
			Globals.roll_panel.execute_macro(token.character.macros[macro_key]["text"], token.character)
