extends PanelContainer

var spellbook
var spell_slot_index = 0
var spell_level
var spell_dict_and_state_arr # [spell_dict, already_cast_bool]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spellbook.character.connect("spell_slot_changed", _on_spell_slot_changed)
	var stylebox = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(10)
	self.add_theme_stylebox_override("panel", stylebox)
	self.reload_spellslot()
	
func reload_spellslot():
	var spell_dict = spell_dict_and_state_arr[Character.SPELL_SLOT_DICT]
	var stylebox = self.get_theme_stylebox("panel")
	stylebox.bg_color = Color(0.3, 0.3, 0.3, 1)
	if spell_dict != null:
		if spell_dict.has("keyword_color") and spell_dict["keyword_color"] != null:
			stylebox.bg_color = str_to_var(spell_dict["keyword_color"])
		if spell_dict.has("spell_name") and spell_dict["spell_name"] != null:
			print("spell_slot_spell: ", spell_dict["spell_name"])
			$Label.text = spell_dict["spell_name"]
	else:
		$Label.text = ""
	var brightness = 0.2126*stylebox.bg_color.r + 0.7152*stylebox.bg_color.g + 0.0722*stylebox.bg_color.b
	if brightness > 0.5:
		$Label.add_theme_color_override("font_color", Color.BLACK)
	else:
		$Label.add_theme_color_override("font_color", Color.WHITE)
	if spell_dict_and_state_arr[Character.SPELL_SLOT_CAST]:
		self.modulate.a = 0.3
	else:
		self.modulate.a = 1.0

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.has("spell_name"):
		print("is spell")
		return true
	return false
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	print("spell dropped")
	if not (data["spell_level"] == spell_level or ( spellbook.character.spellbooks[spellbook.spellbook_name]["allow_spells_in_higher_slots"] and data["spell_level"] < spell_level)): #spell cannot be placed in slot
		print("invalid spellslot for dropped spell")
		return
	spellbook.character.add_spell_to_prepared(data, spellbook.spellbook_name, spell_level, spell_slot_index)
	#spellbook.character.call_character_function_on_remote_peers_through_token("add_spell_to_prepared", data, spellbook.spellbook_name, spell_level, spell_slot_index)

func _on_spell_slot_changed(spellbook_name, signal_spell_level, signal_spell_slot_index):
	if spellbook_name == spellbook.spellbook_name and signal_spell_level == spell_level and signal_spell_slot_index == spell_slot_index:
		#this is the right slot
		self.reload_spellslot()
		#spell_dict_and_state_arr = spellbook.character.spellbooks[spellbook.spellbook_name]["spell_slots"][signal_spell_level-1][signal_spell_slot_index]


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_action_released("mouseleft"):
			spellbook.character.cast_spell(spellbook.spellbook_name, spell_level, spell_slot_index)
			
		if event.is_action_released("mousemiddle"):
			spellbook.character.remove_spell_from_spellslot(spellbook.spellbook_name, spell_level, spell_slot_index)
			
		if event.is_action_released("mouseright"):
			spellbook.character.mark_spell_as_cast_or_not_cast(spellbook.spellbook_name, spell_level, spell_slot_index)
