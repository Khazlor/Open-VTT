#Author: Vladimír Horák
#Desc:
#Custom shape, draws arc of angle_size degrees from center to radius in angle_direction



extends Control

class_name CustomArc

var center: Vector2
var radius = 0:
	set(value):
		radius = value
		self.queue_redraw()
var angle_direction = 0
var angle_size = 0

#do not modify

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #elipse aproximation algorithm from https://www.geeksforgeeks.org/how-to-discretize-an-ellipse-or-circle-to-a-polygon-using-c-graphics/
	var angle = angle_direction-deg_to_rad(angle_size)/2
	var angle_shift_rad = deg_to_rad(4)
	var pointArray: PackedVector2Array
	pointArray.append(Vector2(0,0))
	pointArray.append(Vector2(radius * cos(angle), radius * sin(angle)))
	for i in range(angle_size/4):
		angle += angle_shift_rad
		pointArray.append(Vector2(radius * cos(angle), radius * sin(angle)))
	angle = angle_direction+deg_to_rad(angle_size)/2
	pointArray.append(Vector2(radius * cos(angle), radius * sin(angle)))
	pointArray.append(Vector2(0,0))
	draw_colored_polygon(pointArray, Globals.colorBack)
	draw_polyline(pointArray, Globals.colorLines, Globals.lineWidth, false)
	
