class_name Map_res
extends Resource

var map_name = "Map Name"
var map_desc = "Description"
var size_x = 40
var size_y = 30
var grid_size = 70
var image = "res://images/Placeholder-1479066.png"
var saved_scene: PackedScene = null

func save(packed_scene: PackedScene):
	print("saving")
	saved_scene = packed_scene
	if saved_scene == null:
		print("saved scene is null")
