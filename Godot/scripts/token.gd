#Author: Vladimír Horák
#Desc:
#Script controlling token component

extends Control

var character: Character
var token_polygon: Control
var bars: VBoxContainer
var fov: PointLight2D

# Called even before ready
func _enter_tree():
	token_polygon = $TokenPolygon
	print(token_polygon.size)
	token_polygon.character = character

# Called when the node enters the scene tree for the first time.
func _ready():
	bars = $UI/Bars
	fov = $UI/FovLight
	UI_set_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#sets correct positions of UI elements around token
func UI_set_position():
	var center = get_center_offset()
	var distance = Vector2(0,0).distance_to((token_polygon.size * token_polygon.scale)/2)
	#bars
	
	bars.size.x = token_polygon.size.x * abs(token_polygon.scale.x)
	bars.position = center + Vector2(-(token_polygon.size.x * abs(token_polygon.scale.x))/2, -distance - bars.size.y)
	fov.position = center
	
func get_center_offset():
	var distance = Vector2(0,0).distance_to((token_polygon.size * token_polygon.scale)/2)
	var angle = Vector2(0,0).angle_to_point((token_polygon.size * token_polygon.scale)/2) + token_polygon.rotation
	var center = Vector2(distance * cos(angle), distance * sin(angle))
	return center
