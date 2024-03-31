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
var texture

# Called when the node enters the scene tree for the first time.
func _ready():
	update_token(true)
	character.token_changed.connect(update_token)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw(): #draw polygon and polyline
	var texture_uvs: PackedVector2Array = PackedVector2Array([])
	var texture_offset = Vector2(0.5, 0.5) + character.token_texture_offset / character.token_size #no need co calculate for every point
	for i in range(shapePointArray.size()):
		texture_uvs.append((shapePointArray[i] - Vector2(0.5, 0.5)) / character.token_texture_scale + texture_offset)
	
	draw_colored_polygon(ScaledPointArray, Globals.colorBack, texture_uvs, texture)
	draw_polyline(ScaledPointArray + PackedVector2Array([ScaledPointArray[0]]), character.token_outline_color, character.token_outline_width, false)
	

func _set(property, value):
	if property == "size":
		size = value
		custom_minimum_size = value
		scale_shape_to_size()
		queue_redraw()
		return true
	return false

#updates sizes of polygon based on token
func update_token(shape: bool):
	if FileAccess.file_exists(character.token_texture):
		texture = Globals.load_texture(character.token_texture)
	elif character.token_texture != "": #check file on server
		texture = Texture2D.new()
		texture.resource_path = character.token_texture
		var file_name = character.token_texture.get_file()
		Globals.lobby.add_to_objects_waiting_for_file(file_name, get_parent())
		if not multiplayer.is_server():
			Globals.lobby.tcp_client.send_file_request(file_name)
	if shape:
		if Globals.tokenShapeDict.has(character.token_shape):
			shapePointArray = Globals.tokenShapeDict[character.token_shape]
		else:
			shapePointArray.clear()
			shapePointArray.append(Vector2(0,0))
			shapePointArray.append(Vector2(1,0))
			shapePointArray.append(Vector2(1,1))
			shapePointArray.append(Vector2(0,1))
	custom_minimum_size = character.token_size
	size = character.token_size
	scale = character.token_scale
	scale_shape_to_size()
	queue_redraw()
	
func scale_shape_to_size():
	ScaledPointArray.clear()
	for point in shapePointArray:
		ScaledPointArray.append(point * size)
