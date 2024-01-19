#Author: Vladimír Horák
#Desc:
#Custom shape, draws polygon of shape based on normalized mapping, scaled to control size
#Used for drawing character tokens

extends Control
#class_name CustomPolygon #unfortunately saving custom class inside scene breaks loading

var character: Character

var shapePointArray: PackedVector2Array
var ScaledPointArray: PackedVector2Array
var colorLines: Color
var lineWidth: float


# Called when the node enters the scene tree for the first time.
func _ready():
	shapePointArray.append(Vector2(0,0))
	shapePointArray.append(Vector2(1,0))
	shapePointArray.append(Vector2(1,0.8))
	shapePointArray.append(Vector2(0.5,1))
	shapePointArray.append(Vector2(0,0.8))
	if size == Vector2(0,0): #new
		update_token()
	else:
		scale_shape_to_size()
	character.token_changed.connect(update_token)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #draw polygon and polyline
	draw_colored_polygon(ScaledPointArray, Globals.colorBack)
	draw_polyline(ScaledPointArray + PackedVector2Array([ScaledPointArray[0]]), Globals.colorLines, Globals.lineWidth, false)
	

#updates sizes of polygon based on token
func update_token():
	custom_minimum_size = character.token_size
	size = character.token_size
	scale = character.token_scale
	scale_shape_to_size()
	
func scale_shape_to_size():
	print("scaling custom polygon token")
	ScaledPointArray.clear()
	for point in shapePointArray:
		ScaledPointArray.append(point * size)
