extends PanelContainer

var token

# Called when the node enters the scene tree for the first time.
func _ready():
	if token != null:
		$HBoxContainer/TextureRect.texture = token.character.token_texture
		$HBoxContainer/NameLabel.text = token.character.name
		$HBoxContainer/InitiativeLabel.text = token.character.attributes["initiative"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_button_pressed():
	if Globals.turn_order.selected != null:
		Globals.turn_order.selected.unselect()
	Globals.turn_order.selected = self
	$Button.flat = false
	#select token
	Globals.turn_order.emit_signal("token_turn_selected", token)
	
func unselect():
	$Button.flat = true

func update():
	$HBoxContainer/InitiativeLabel.text = token.character.attributes["initiative"]
