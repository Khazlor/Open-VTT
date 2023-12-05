extends Control


var character: Character

# Called when the node enters the scene tree for the first time.
func _ready():
	UI_set_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#sets correct positions of UI elements around token
func UI_set_position():
	var panel = $Panel
	var center = get_center_offset(panel)
	var distance = Vector2(0,0).distance_to((panel.size * panel.scale)/2)
	#bars
	var bars = $UI/Bars
	bars.size.x = panel.size.x * abs(panel.scale.x)
	bars.position = center + Vector2(-(panel.size.x * abs(panel.scale.x))/2, -distance - bars.size.y)
	
func get_center_offset(panel: Panel):
	var distance = Vector2(0,0).distance_to((panel.size * panel.scale)/2)
	var angle = Vector2(0,0).angle_to_point((panel.size * panel.scale)/2) + panel.rotation
	var center = Vector2(distance * cos(angle), distance * sin(angle))
	return center
