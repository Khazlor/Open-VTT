#Author: Vladimír Horák
#Desc:
#Script for drag and drop debug component

extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position, data):
	print("======= test ==========", data, data.has_meta("item_dict"))
	return false
