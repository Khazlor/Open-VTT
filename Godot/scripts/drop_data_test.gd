#Author: Vladimír Horák
#Desc:
#Script for drag and drop debug component

extends Node

func _can_drop_data(at_position, data):
	print("======= test ==========", data, data.has_meta("item_dict"))
	return false
