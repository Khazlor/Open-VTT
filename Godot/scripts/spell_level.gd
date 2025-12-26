extends VBoxContainer

var spell_level = 0
var spellbook

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer2/Label.text = "Lvl. " + str(spell_level)
	load_spell_slots()
	

func load_spell_slots():
	create_spell_slots()
	spellbook.character.connect("spell_slots_changed", _on_spell_slots_changed)

func create_spell_slots():
	if spellbook != null and spellbook.character != null and spellbook.character.spellbooks.has(spellbook.spellbook_name) and spellbook.character.spellbooks[spellbook.spellbook_name].has("spell_slots"):
		var spell_slots = spellbook.character.spellbooks[spellbook.spellbook_name]["spell_slots"]
		if spell_slots.size() >= spell_level:
			var spell_slot_index = 0
			for spell_slot in spell_slots[spell_level - 1]:
				var new_slot = spellbook.spell_slot_comp.instantiate()
				new_slot.spellbook = spellbook
				new_slot.spell_level = spell_level
				new_slot.spell_slot_index = spell_slot_index
				new_slot.spell_dict_and_state_arr = spell_slot
				spell_slot_index += 1
				$HFlowContainer.add_child(new_slot)

func _on_slot_more_pressed() -> void:
	spellbook.character.add_spell_slot(spellbook.spellbook_name, spell_level)


func _on_slot_less_pressed() -> void:
	spellbook.character.remove_spell_slot(spellbook.spellbook_name, spell_level)

func _on_spell_slots_changed(spellbook_name, spell_slot_level, status = Character.SPELLSLOT_OTHER):
	if spellbook_name == spellbook.spellbook_name and spell_slot_level == spell_level:
		if status == Character.SPELLSLOT_LEVEL_REMOVE:
			self.queue_free()
			return
		elif status == Character.SPELLSLOT_OTHER:
			#this spell_level was changed - recreate
			for child in $HFlowContainer.get_children():
				child.queue_free()
			create_spell_slots()
		#else add new - handled in parent
	
