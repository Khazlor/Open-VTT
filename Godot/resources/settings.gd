#Resource for saving user preferences
class_name Settings_res
extends Resource

var settings_dict = {
#VISUAL
	"ui_scale" = 1.0,
	#max_lights = 32,
	#max_lights_per_object = 8,
#MULTIPLAYER
	"player_name" = "user",
}

func save_settings():
	var save_FA = FileAccess.open(Globals.base_dir_path + "/settings.json", FileAccess.WRITE)
	if save_FA == null:
		print("file open error - settings.json - aborting" + Globals.base_dir_path + "/settings.json")
		return
	
	save_FA.store_line(JSON.stringify(settings_dict))
	save_FA.close()
	print("settings.json saved successfully" + Globals.base_dir_path + "/settings.json")

func load_settings():
	if FileAccess.file_exists(Globals.base_dir_path + "/settings.json"):
		var save_FA = FileAccess.open(Globals.base_dir_path + "/settings.json", FileAccess.READ)
		if save_FA == null:
			print("file open error - settings.json - aborting")
			return
		var json = JSON.new()
		var error = json.parse(save_FA.get_line())
		if error == OK and typeof(json.data) == TYPE_DICTIONARY:
			settings_dict = json.data
			print("settings.json loaded successfully")
		else:
			print("settings.json - cointains unexpected data")
		save_FA.close()
	else:
		print("settings.json - does not exist")
		
func apply_settings():
	Globals.main_window.wrap_controls = true
	Globals.main_window.content_scale_factor = settings_dict["ui_scale"]
	Globals.main_window.child_controls_changed()
	
