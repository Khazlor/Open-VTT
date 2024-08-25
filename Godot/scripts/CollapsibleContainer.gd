#Author: Vladimír Horák
#Desc:
#Simple Script for creating collapsible containers

#USAGE:
#use on VboxContainer

#requires "Button" and "Container" children

#pressing Button toggles Container Visibility

@tool
extends VBoxContainer

var icon_opened = preload("res://icons/Collapse.svg")
var icon_folded = preload("res://icons/Forward.svg")
@onready var button = $Button
@onready var container = $Container


# Called when the node enters the scene tree for the first time.
func _ready():
	button.icon = icon_opened
	button.connect("pressed", _on_button_pressed)


func _on_button_pressed(): #flip visibility and icon
	container.visible = not container.visible
	if container.visible:
		button.icon = icon_opened
	else:
		button.icon = icon_folded
