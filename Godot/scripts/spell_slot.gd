extends PanelContainer

@onready var spellbook = $"../../../../../.."
var spell_slot_index = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	print(data)
	if data is Dictionary and data.has("spell_name"):
		print("is spell")
		return true
	return false
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	print("spell dropped")
	spellbook.char_sheet.character.add_spell_to_prepared(data, spell_slot_index, spellbook.spellbook_name)
