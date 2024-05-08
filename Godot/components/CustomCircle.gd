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
	

func _draw():
	position = Vector2(center.x - radius, center.y - radius)
	
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, Globals.colorLines, Globals.lineWidth, false)
	
func calc_size():
	custom_minimum_size = Vector2(2*radius, 2*radius)
	pivot_offset = Vector2(radius, radius)
	var angle = 0 #start angle
	var angle_change_rad = deg_to_rad(4) #change in angle between points - every 4 degrees
	polygon.clear()
	polygon.append(Vector2(2*radius, radius)) #starting point - right side
	for i in range(90): # make 90 points (360 every 4 degrees)
		angle += angle_change_rad
		polygon.append(Vector2(radius * cos(angle) + radius, radius * sin(angle) + radius))
