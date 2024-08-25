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

#do not modify - change by using angle_shift
var angle_shift_rad = deg_to_rad(5)

# Called when the node enters the scene tree for the first time.
func _ready():
	if line_color == null:
		line_color = Globals.colorLines
		back_color = Globals.colorBack
		line_width = Globals.lineWidth
	
func _draw():
	var center = self.size/2
	var angle = 0
	polygon.clear()
	polygon.append(Vector2(self.size.x, center.y)) #starting point- right side middle
	for i in range(int(360/angle_shift)):
		angle += angle_shift_rad
		polygon.append(center + Vector2(center.x * cos(angle), center.y * sin(angle)))#cast point by angle from center
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, line_color, line_width, false)
		
		
	
	
	
