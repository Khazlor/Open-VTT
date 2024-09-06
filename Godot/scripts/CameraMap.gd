#Author: Vladimír Horák
#Desc:
#Script for controlling camera in map scene

extends Camera2D

#settings for map camera navigation
var zoomSpd: float = 0.05
var minZoom: float = 0.001
var maxZoom: float = 2.0
var dragSen: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.camera = self

#handles user input
func _unhandled_input(event):
	#movement
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position -= event.relative * dragSen / zoom
		
	#zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoomSpd, zoomSpd)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoomSpd, zoomSpd)
		else:
			return
		zoom = clamp(zoom, Vector2(minZoom, minZoom), Vector2(maxZoom, maxZoom))
		#resize selection box handles
		if $"../Draw/Select".get_child_count() == 1:
			var handles = $"../Draw/Select".get_child(0).get_children()
			for handle in handles:
				handle.scale = Vector2(1/zoom.x,1/zoom.y)
