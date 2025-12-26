extends Window

#popup menu is broken in non-embedded subwindows - grabs focus of main window on popup(), show(), visible() - seems related to https://github.com/godotengine/godot/issues/100192
#this is a workaround component

#problem with consuming the input when clicking outside

# WARNING: When child of native window - must be freed before the window closes - otherwise program will freeze - hence popup ini _ready

@export var items: PackedStringArray

signal item_pressed(item_index)

func _ready() -> void:
	if items == null:
		items = []
	self.content_scale_factor = Globals.main_window.content_scale_factor
	var i = 0
	for item in items:
		var new_button = Button.new()
		new_button.text = "    " + item + "    "
		new_button.connect("pressed", on_item_pressed.bind(i))
		i += 1
		$VBoxContainer.add_child(new_button)
	self.popup()
	self.hide() #need to repopup - otherwise black
	self.popup()
	

func _on_close_requested() -> void:
	self.hide()
	self.queue_free()
	

func on_item_pressed(item_index: int):
	emit_signal("item_pressed", item_index)
	self.hide()
	self.queue_free()

func update_size():
	print("updating size")
	self.size = $VBoxContainer.size * self.content_scale_factor
