extends VBoxContainer

var spell_level = 0
var spellbook

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer2/Label.text = "Lvl. " + str(spell_level)
	
