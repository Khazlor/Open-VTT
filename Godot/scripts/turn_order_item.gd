#Author: Vladimír Horák
#Desc:
#Script for items representing tokens in turn_order

extends PanelContainer

var token

# Called when the node enters the scene tree for the first time.
func _ready():
	if token != null:
		var texture = Globals.load_texture(token.character.token_texture)
		if texture != null:
			$HBoxContainer/TextureRect.texture = texture
		$HBoxContainer/NameLabel.text = token.character.name
		$HBoxContainer/InitiativeLabel.text = token.character.attributes["initiative"][1]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#click on item - select token
func _on_button_pressed():
	if Globals.turn_order.selected != null:
		Globals.turn_order.selected.unselect()
	Globals.turn_order.selected = self
	$Button.flat = false
	#select token
	Globals.turn_order.emit_signal("token_turn_selected", token)
	Globals.turn_order.lose_focus()
	
func unselect():
	$Button.flat = true

func update():
	$HBoxContainer/InitiativeLabel.text = token.character.attributes["initiative"][1]
