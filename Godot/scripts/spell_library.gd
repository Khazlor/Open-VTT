extends Window

var is_main_spell_library = true # to detect if window is spell library - for spellcards options on rightclick

var spell_card_comp = preload("res://components/spell_card.tscn")
var spell_level_library_comp = preload("res://components/spell_level_library.tscn")
var custom_popup_comp = preload("res://components/custom_pop_up.tscn")
var popup_items = ["Learn Spell", "Print Spell", "Cast Spell"]

@onready var spell_libraries_container = $"VBoxContainer/SpellLevelLibs"

var spell_libraries = []

var character: Character = null #for learning spells
var spellbook_name = ""
var spells_all_arr = []
var spells_one_arr = []

var current_spell_dict

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/HBoxContainer/AllowedSpellsAll.text = var_to_str(spells_all_arr)
	$VBoxContainer/HBoxContainer/AllowedSpellsOne.text = var_to_str(spells_one_arr)
	fill_spell_library()


func _on_search_button_pressed() -> void:
	#check validity of AllowedSpellsAll and AllowedSpellsOne inputs
	var spell_list_all = []
	var spell_list_one = []
	if $SpellBookSettingsWindow/SpellbookSettings/AllowedSpellsAll.text != "":
		spell_list_all = str_to_var($SpellBookSettingsWindow/SpellbookSettings/AllowedSpellsAll.text)
		if spell_list_all == null or not spell_list_all is Array :
			$AcceptDialog.dialog_text = "Aborting Search - Spell Filter not Array"
			$AcceptDialog.popup()
			return
		for string in spell_list_all:
			if not string is String or string == "":
				$AcceptDialog.dialog_text = "Aborting Search - " + str(string) + " not String"
				$AcceptDialog.popup()
				return
	if $SpellBookSettingsWindow/SpellbookSettings/AllowedSpellsOne.text != "":
		spell_list_one = str_to_var($SpellBookSettingsWindow/SpellbookSettings/AllowedSpellsOne.text)
		if spell_list_one == null or not spell_list_one is Array :
			$AcceptDialog.dialog_text = "Aborting Search - Spell Search not Array"
			$AcceptDialog.popup()
			return
		for string in spell_list_one:
			if not string is String or string == "":
				$AcceptDialog.dialog_text = "Aborting Search - " + str(string) + " not String"
				$AcceptDialog.popup()
				return
	#inputs are fine, apply changes
	spells_all_arr = spell_list_all
	spells_one_arr = spell_list_one
	clear_spell_library()
	fill_spell_library()
	
	
func fill_spell_library():
	var max_level = -1
	var spell_array = Globals.spell_database.get_spells_from_database(spells_all_arr, spells_one_arr)
	for spell in spell_array:
		var spell_level = spell["spell_level"]
		if spell_level > max_level: #create spell library containers
			for i in range(max_level + 1, spell_level + 1):
				print("GENERATING SPELLBOOK LEVEL " , i)
				var new_spell_level_library = spell_level_library_comp.instantiate()
				new_spell_level_library.spell_level = i
				new_spell_level_library.spellbook = self
				new_spell_level_library.name = "Lvl " + str(i)
				spell_libraries_container.add_child(new_spell_level_library)
				spell_libraries.append(new_spell_level_library)
			max_level = spell_level
				
		spell_libraries[spell_level].add_spell_to_library(spell)
	
func clear_spell_library():
	for child in spell_libraries_container:
		child.queue_free()


func _on_pop_up_button_pressed() -> void:
	self.hide()
	self.force_native = not self.force_native
	if self.force_native:
		self.content_scale_factor = Globals.main_window.content_scale_factor
		self.size = self.size * self.content_scale_factor
	self.popup()


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()


func _on_context_menu_item_pressed(item_index: Variant) -> void:
	if item_index == 0: #learn spell
		if character != null:
			character.add_spell_to_spellbook(current_spell_dict, spellbook_name)
	elif item_index == 1: #print spell TODO
		pass
	else: #cast spell TODO
		pass
