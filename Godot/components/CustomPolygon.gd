#Author: Vladimír Horák
#Desc:
#Custom shape, draws polygon of shape based on normalized mapping, scaled to control size

extends Control
class_name CustomPolygon


var points: PackedVector2Array
var colorLines: Color
var colorBG: Color
var lineWidth: float

	
func _draw(): #draw polygon and polyline
	draw_polygon(points, [colorBG])
	if points.size() > 2:
		draw_polyline(points + PackedVector2Array([points[0]]), colorLines, lineWidth, false)
	else:
		draw_polyline(points, colorLines, lineWidth, false)
	
