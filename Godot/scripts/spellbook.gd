extends Control

@onready var character_sheet = $"../.."
@onready var character: Character = character_sheet.character
@onready var spell_libraries_container = $"HSplitContainer/KnownSpells"
@onready var spells_prepared = $"HSplitContainer/SidePanel/ScrollContainer/Prepared"

var spell_libraries = []

var spell_card_comp = preload("res://components/spell_card.tscn")
var spell_level_comp = preload("res://components/spell_level.tscn")
var spell_level_library_comp = preload("res://components/spell_level_library.tscn")
var spell_library_comp = preload("res://UI/spell_library.tscn")
var custom_popup_comp = preload("res://components/custom_pop_up.tscn")
var spell_slot_comp = preload("res://components/spell_slot.tscn")

var popup_items = ["Prepare Spell (middle mouse button)", "Cast Spell", "Print Spell"]

var current_spellcard

var spellbook_name

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name = spellbook_name
	var max_level = -1
	var spell_array
	if not character.spellbooks.has(spellbook_name):
		print("ERROR spellbook not in character !")
		return
	var spellbook_dict = character.spellbooks[spellbook_name]
	if spellbook_dict["know_all_spells"]:
		spell_array = Globals.spell_database.get_spells_from_database(spellbook_dict["allowed_spell_categories_all"], spellbook_dict["allowed_spell_categories_one"], self)
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
	character.connect("spell_slots_changed", _on_spell_slots_changed)
	character.connect("spellbook_spells_changed", _on_spellbook_spells_changed)
	load_spell_slots()
	
func load_spell_slots():
	var spellbook_dict = character_sheet.character.spellbooks[spellbook_name]
	if spellbook_dict.has("spell_slots"):
		var spell_level = 1
		for spell_slot_level in spellbook_dict["spell_slots"]:
			var new_spell_level = spell_level_comp.instantiate()
			new_spell_level.spell_level = spell_level
			spell_level += 1
			new_spell_level.spellbook = self
			spells_prepared.add_child(new_spell_level)
		

func _on_level_more_pressed() -> void:
	character_sheet.character.add_spell_slot_level(spellbook_name)


func _on_level_less_pressed() -> void:
	if spells_prepared.get_child_count() > 1:
		character_sheet.character.remove_spell_slot_level(spellbook_name)


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
		character.add_spell_to_prepared(current_spellcard.spell_dict, spellbook_name)
		#character.call_character_function_on_remote_peers_through_token("add_spell_to_prepared", current_spellcard.spell_dict, spellbook_name)
	elif item_index == 1: #cast
		character.cast_spell(spellbook_name, null, null, current_spellcard.spell_dict)
	else: #print
		if current_spellcard == null:
			return
		Globals.roll_panel.print_spell(current_spellcard.spell_dict)

func _on_spell_slots_changed(signal_spellbook_name, spell_slot_level, status = Character.SPELLSLOT_OTHER):
	if status == Character.SPELLSLOT_LEVEL_ADD and signal_spellbook_name == self.spellbook_name:
		#create new spell_slot level
		if spell_slot_level == spells_prepared.get_child_count(): #check if we are missing only one
			print("just one")
			var new_spell_level = spell_level_comp.instantiate()
			new_spell_level.spell_level = spell_slot_level
			new_spell_level.spellbook = self
			spells_prepared.add_child(new_spell_level)
		else: #numbers do not add up, some error - recreate all
			print("recreate")
			var skip_first = true
			for child in spells_prepared.get_children():
				if skip_first:
					skip_first = false
				else:
					child.queue_free()
			load_spell_slots()

func _on_spellbook_spells_changed(signal_spellbook_name, spell_dict, status):
	if signal_spellbook_name == self.spellbook_name:
		if spell_dict == null:
			return
		if status == Character.SPELL_ADD:
			var max_level = spell_libraries.size() - 1
			var spell_level = spell_dict["spell_level"]
			if spell_level > max_level: #create spell library containers
				for i in range(max_level, spell_level):
					print("GENERATING SPELLBOOK LEVEL " , i + 1)
					var new_spell_level_library = spell_level_library_comp.instantiate()
					new_spell_level_library.spell_level = i + 1
					new_spell_level_library.spellbook = self
					new_spell_level_library.name = "Lvl " + str(i + 1)
					spell_libraries_container.add_child(new_spell_level_library)
					spell_libraries.append(new_spell_level_library)
			spell_libraries[spell_level].add_spell_to_library(spell_dict)
		if status == Character.SPELL_REMOVE:
			var max_level = spell_libraries.size()
			var spell_level = spell_dict["spell_level"]
			if max_level < spell_level:
				return
			spell_libraries[spell_level].remove_spell_from_library(spell_dict)

func _on_rest_btn_pressed() -> void:
	character.rest_spells(spellbook_name)
