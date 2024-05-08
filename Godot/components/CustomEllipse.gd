#Author: Vladimír Horák
#Desc:
#Custom shape, elipse inscribed in control size rectangle

extends Control

class_name CustomEllipse

var polygon: PackedVector2Array

var angle_shift = 5:
	set(value):
		angle_shift = value
		angle_shift_rad = deg_to_rad(value)

var line_color = null
var back_color
var line_width

#do not modify
var angle_shift_rad = deg_to_rad(5)

# Called when the node enters the scene tree for the first time.
func _ready():
	if line_color == null:
		line_color = Globals.colorLines
		back_color = Globals.colorBack
		line_width = Globals.lineWidth

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
	var ab = self.size/2
	var seg = 360/angle_shift
	var angle = 0
	polygon.clear()
	polygon.append(Vector2(ab.x + ab.x, ab.y))
	for i in range(int(seg)):
		angle += angle_shift_rad
		polygon.append(Vector2(ab.x + ab.x * cos(angle), ab.y + ab.y * sin(angle)))
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, line_color, line_width, false)
		
		
	
	
	
