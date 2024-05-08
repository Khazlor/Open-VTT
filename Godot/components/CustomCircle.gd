#Author: Vladimír Horák
#Desc:
#Custom shape, circle based on center and radius

extends Control

class_name CustomCircle

var center: Vector2 = Vector2(0,0):
	set(value):
		center = value
		self.queue_redraw()
var radius = 0:
	set(value):
		radius = value
		self.calc_size()
		self.queue_redraw()
var polygon: PackedVector2Array
var back_color = Globals.colorBack

# Called when the node enters the scene tree for the first time.
func _ready():
	calc_size()
	
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
	position = Vector2(center.x - radius, center.y - radius)
	
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, Globals.colorLines, Globals.lineWidth, false)
	
func calc_size():
	custom_minimum_size = Vector2(2*radius, 2*radius)
	pivot_offset = Vector2(radius, radius)
	var angle = 0
	var angle_shift_rad = deg_to_rad(4)
	polygon.clear()
	polygon.append(Vector2(2*radius, radius))
	for i in range(90):
		angle += angle_shift_rad
		polygon.append(Vector2(radius * cos(angle) + radius, radius * sin(angle) + radius))
