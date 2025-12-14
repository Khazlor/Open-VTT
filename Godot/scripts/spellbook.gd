extends Control

@onready var character_sheet = $"../.."
@onready var character = character_sheet.character
@onready var spell_libraries_container = $"HSplitContainer/KnownSpells"
@onready var spells_prepared = $"HSplitContainer/SidePanel/ScrollContainer/Prepared"

var spell_libraries = []

var spell_card_comp = preload("res://components/spell_card.tscn")
var spell_level_comp = preload("res://components/spell_level.tscn")
var spell_level_library_comp = preload("res://components/spell_level_library.tscn")
var spell_library_comp = preload("res://UI/spell_library.tscn")
var custom_popup_comp = preload("res://components/custom_pop_up.tscn")
var popup_items = ["Prepare Spell (middle mouse button)", "Cast Spell", "Print Spell"]

var current_spellcard

var spellbook_name

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = spellbook_name
	var max_level = -1
	var spell_array
	if not character_sheet.character.spellbooks.has(spellbook_name):
		print("ERROR spellbook not in character !")
		return
	var spellbook_dict = character_sheet.character.spellbooks[spellbook_name]
	if spellbook_dict["know_all_spells"]:
		spell_array = Globals.spell_database.get_spells_from_database(spellbook_dict["allowed_spell_categories_all"], spellbook_dict["allowed_spell_categories_one"])
		spell_array.append_array(spellbook_dict["spells"])
	else:
		spell_array = spellbook_dict["spells"]
		
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
	

func load_spell_slots():
	var spellbook_dict = character_sheet.character.spellbooks[spellbook_name]
	for spell_slot_level in spellbook_dict["spell_slots"]:
		var new_spell_level = spell_level_comp.instantiate()
		new_spell_level.spell_level = spells_prepared.get_child_count() - 1
		new_spell_level.spellbook = self
		spells_prepared.add_child(new_spell_level)
		



func _on_level_more_pressed() -> void:
	var new_spell_level = spell_level_comp.instantiate()
	new_spell_level.spell_level = spells_prepared.get_child_count() - 1
	new_spell_level.spellbook = self
	spells_prepared.add_child(new_spell_level)


func _on_level_less_pressed() -> void:
	pass # Replace with function body.


func _on_open_spell_lib_btn_pressed() -> void:
	var spell_lib = spell_library_comp.instantiate()
	spell_lib.character = character_sheet.character #for learning spells
	if character_sheet.character.spellbooks.has(spellbook_name):
		var spellbook_dict = character_sheet.character.spellbooks[spellbook_name]
		spell_lib.spells_all_arr = spellbook_dict["allowed_spell_categories_all"]
		spell_lib.spells_one_arr = spellbook_dict["allowed_spell_categories_one"]
		spell_lib.spellbook_name = spellbook_name
	self.add_child(spell_lib)


func _on_context_menu_item_pressed(item_index: Variant) -> void:
	if item_index == 0: #prepare spell
		pass
	elif item_index == 1: #cast spell TODO
		pass
	else:
		if current_spellcard == null:
			return
		var print_spellcard = spell_card_comp.instantiate()
		print_spellcard.print = true
		print_spellcard.spell_dict = current_spellcard.spell_dict
		Globals.roll_panel.add_node_to_rollpanel(print_spellcard)
