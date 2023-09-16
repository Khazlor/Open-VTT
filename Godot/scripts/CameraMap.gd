extends Camera2D

var zoomSpd: float = 0.05
var minZoom: float = 0.001
var maxZoom: float = 2.0
var dragSen: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position -= event.relative * dragSen / zoom
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoomSpd, zoomSpd)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoomSpd, zoomSpd)
		zoom = clamp(zoom, Vector2(minZoom, minZoom), Vector2(maxZoom, maxZoom))
