#Author: Vladimír Horák
#Desc:
#Custom shape, circle based on center and radius

extends Control

class_name CustomCircle

var center: Vector2
var radius = 0:
	set(value):
		radius = value
		self.queue_redraw()

#do not modify

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #elipse aproximation algorithm from https://www.geeksforgeeks.org/how-to-discretize-an-ellipse-or-circle-to-a-polygon-using-c-graphics/
	self.set_position(Vector2(center.x - radius, center.y - radius))
	self.set_size(Vector2(2*radius, 2*radius))
	var angle = 0
	var angle_shift_rad = deg_to_rad(4)
	var pointArray: PackedVector2Array
	pointArray.append(Vector2(2*radius, radius))
	for i in range(90):
		angle += angle_shift_rad
		pointArray.append(Vector2(radius * cos(angle) + radius, radius * sin(angle) + radius))
	draw_colored_polygon(pointArray, Globals.colorBack)
	draw_polyline(pointArray, Globals.colorLines, Globals.lineWidth, false)
	
