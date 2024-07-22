#Author: Vladimír Horák
#Desc:
#Custom shape, draws polygon of shape based on normalized mapping, scaled to control size

extends Control
class_name CustomPolygon


var points: PackedVector2Array
var colorLines: Color
var colorBG: Color
var lineWidth: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #draw polygon and polyline
	draw_polygon(points, [colorBG])
	draw_polyline(points, colorLines, lineWidth, false)
	
