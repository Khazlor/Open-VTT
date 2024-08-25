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

	
func _draw():
	var angle = angle_direction-deg_to_rad(angle_size)/2 #start angle in rad
	var angle_change_rad = deg_to_rad(4) #angle change between points - every 4 degrees
	polygon.clear()
	polygon.append(Vector2(0,0)) #emission point of arc
	polygon.append(Vector2(radius * cos(angle), radius * sin(angle))) #first_point
	for i in range(angle_size/4): #make point every 4 degrees over anle_size degrees
		angle += angle_change_rad
		polygon.append(Vector2(radius * cos(angle), radius * sin(angle)))
	angle = angle_direction+deg_to_rad(angle_size)/2
	polygon.append(Vector2(radius * cos(angle), radius * sin(angle))) #add one last point at final angle
	polygon.append(Vector2(0,0)) #return back to emiting point
	
	draw_colored_polygon(polygon, back_color)
	draw_polyline(polygon, Globals.colorLines, Globals.lineWidth, false)
	
