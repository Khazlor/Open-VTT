#Author: Vladimír Horák
#Desc:
#Custom shape, draws arc of angle_size degrees from center to radius in angle_direction



extends Control

class_name CustomArc

var center: Vector2:
	set(value):
		center = value
		self.queue_redraw()
var radius = 0:
	set(value):
		radius = value
		self.queue_redraw()
var angle_direction = 0
var angle_size = 0
var polygon: PackedVector2Array
var back_color = Globals.colorBack

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#elipse aproximation algorithm inspired by algorithm from
#https://www.geeksforgeeks.org/how-to-discretize-an-ellipse-or-circle-to-a-polygon-using-c-graphics/
#and rewritten for GDScript
#Author and Publisher: geeksforgeeks.org
#Last revision: 17 Jan, 2020
#Title: How to discretize an Ellipse or Circle to a Polygon using C++ Graphics?
func _draw():
	var angle = angle_direction-deg_to_rad(angle_size)/2
	var angle_shift_rad = deg_to_rad(4)
	polygon.clear()
	polygon.append(Vector2(0,0))
	polygon.append(Vector2(radius * cos(angle), radius * sin(angle)))
	for i in range(angle_size/4):
		angle += angle_shift_rad
		polygon.append(Vector2(radius * cos(angle), radius * sin(angle)))
	angle = angle_direction+deg_to_rad(angle_size)/2
	polygon.append(Vector2(radius * cos(angle), radius * sin(angle)))
	polygon.append(Vector2(0,0))
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, Globals.colorLines, Globals.lineWidth, false)
	
