extends Control
var maplist

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_campaign_browser_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/Maps.tscn")
