extends MarginContainer

var spell_level
var spellbook
@onready var spell_card_container = $ScrollContainer/FlowContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func add_spell_to_library(spell_dict: Dictionary):
	var spellcard = spellbook.spell_card_comp.instantiate()
	spellcard.spell_dict = spell_dict
	spellcard.spellbook = spellbook
	spell_card_container.add_child(spellcard)
	
func remove_spell_from_library(spell_dict: Dictionary):
	for spellcard in spell_card_container.get_children():
		if spellcard.spell_dict == spell_dict:
			spellcard.queue_free()
	
func clear_library():
	for child in spell_card_container.get_children():
		child.queue_free()
