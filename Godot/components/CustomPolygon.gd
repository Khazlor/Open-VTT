#Author: Vladimír Horák
#Desc:
#Custom shape, draws polygon of shape based on normalized mapping, scaled to control size

extends Node2D
class_name CustomPolygon

var points: PackedVector2Array
var colorLines: Color
var colorBG: Color
var lineWidth: float
var closed: bool

var angle_shift = 5:
	set(value):
		angle_shift = value
		angle_shift_rad = deg_to_rad(value)
#do not modify - change by using angle_shift
var angle_shift_rad = deg_to_rad(5)

#implementing control functionality
var size: Vector2 = Vector2(0,0)

func set_begin(begin: Vector2):
	position = begin
	
func set_end(end: Vector2):
	size = end-position
	
func get_begin():
	return position
	
func get_end():
	return position+size
	
func get_end_scaled():
	return position+(size*scale)

func add_point(point: Vector2):
	points.append(point - self.position)
	queue_redraw()

func shift_points(shift: Vector2):
	for i in range(points.size()):
		points[i] += shift
	queue_redraw()

func fill_points_with_rect():
	closed = true
	points.clear()
	points.append(Vector2(0, 0))
	points.append(Vector2(0, self.size.y))
	points.append(Vector2(self.size.x, self.size.y))
	points.append(Vector2(self.size.x, 0))
	queue_redraw()

func update_shadow():
	if self.has_meta("shadow"):
		var shadow: LightOccluder2D = Globals.draw_comp.get_object_shadow(self)
		shadow.occluder.polygon = points

func fill_points_with_ellipse():
	closed = true
	var center = self.size/2
	var angle = 0
	points.clear()
	points.append(Vector2(self.size.x, center.y)) #starting point- right side middle
	for i in range(int(360/angle_shift)):
		angle += angle_shift_rad
		points.append(center + Vector2(center.x * cos(angle), center.y * sin(angle)))#cast point by angle from center
	queue_redraw()
	
func _ready() -> void:
	queue_redraw()

func _draw(): #draw polygon and polyline
	if points.size() > 1:
		if closed and points.size() > 2:
			draw_polygon(points, [colorBG])
			draw_polyline(points + PackedVector2Array([points[0]]), colorLines, lineWidth, false)
		else:
			draw_polyline(points, colorLines, lineWidth, false)
