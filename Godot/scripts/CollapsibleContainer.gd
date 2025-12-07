#Author: Vladimír Horák
#Desc:
#Simple Script for creating collapsible containers

#USAGE:
#use on VboxContainer

#requires "Button" and "Container" children

#pressing Button toggles Container Visibility

extends VBoxContainer

@onready var button = $Button
@onready var container = $Container


# Called when the node enters the scene tree for the first time.
func _ready():
	button.icon = Globals.icon_opened
	button.connect("pressed", _on_button_pressed)


func _on_button_pressed(): #flip visibility and icon
	container.visible = not container.visible
	if container.visible:
		button.icon = Globals.icon_opened
	else:
		button.icon = Globals.icon_folded
