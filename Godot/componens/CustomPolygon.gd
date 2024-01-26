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
	if Globals.tokenShapeDict.has(character.token_shape):
		shapePointArray = Globals.tokenShapeDict[character.token_shape]
	else:
		shapePointArray.append(Vector2(0,0))
		shapePointArray.append(Vector2(1,0))
		shapePointArray.append(Vector2(1,1))
		shapePointArray.append(Vector2(0,1))
	if size == Vector2(0,0): #new
		update_token()
	else:
		scale_shape_to_size()
	character.token_changed.connect(update_token)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #draw polygon and polyline
	var texture_uvs: PackedVector2Array = PackedVector2Array([])
	var texture_offset = Vector2(0.5, 0.5) + character.token_texture_offset / character.token_size #no need co calculate for every point
	for i in range(shapePointArray.size()):
		texture_uvs.append((shapePointArray[i] - Vector2(0.5, 0.5)) / character.token_texture_scale + texture_offset)
	draw_colored_polygon(ScaledPointArray, Globals.colorBack, texture_uvs, character.token_texture)
	draw_polyline(ScaledPointArray + PackedVector2Array([ScaledPointArray[0]]), character.token_outline_color, character.token_outline_width, false)
	

#updates sizes of polygon based on token
func update_token():
	custom_minimum_size = character.token_size
	size = character.token_size
	scale = character.token_scale
	scale_shape_to_size()
	queue_redraw()
	
func scale_shape_to_size():
	print("scaling custom polygon token")
	ScaledPointArray.clear()
	for point in shapePointArray:
		ScaledPointArray.append(point * size)
