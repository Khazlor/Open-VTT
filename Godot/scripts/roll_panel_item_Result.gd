extends RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#custom tooltip for rolls - using RichTextLabel to allow BBCode formatting
func _make_custom_tooltip(for_text):
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	var text_without_tags = regex.sub(for_text, "", true)
	
	var tooltip = RichTextLabel.new()
	tooltip.bbcode_enabled = true
	tooltip.fit_content = true
	tooltip.text = for_text
	var size:Vector2 = tooltip.get_theme_font("normal_font").get_string_size(text_without_tags) # calculating size - fit content not working - probably godot bug - TODO: update after godot fix 
	tooltip.custom_minimum_size = size
	print("width: " + str(tooltip.get_content_width()))
	return tooltip
