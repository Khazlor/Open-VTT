extends TextEdit
class_name CharSheetInput

var character = null

func _on_input_selected():
	var column = self.get_caret_column()
	var line = self.get_caret_line()
	self.text = character.attributes[self.get_meta("dict")["attr"]][0]
	self.set_caret_column(column)
	self.set_caret_line(line)
	
func _on_input_deselected():
	self.text = character.attributes[self.get_meta("dict")["attr"]][1]
	
func _on_input_changed():
	var attr = self.get_meta("dict")["attr"]
	character.attributes[attr][0] = self.text
	character.apply_modifiers_to_attr(attr)
	character.emit_signal("attr_updated", attr, false)

func _input_on_attr_changed(attr, tooltip):
	if attr == self.get_meta("dict")["attr"]:
		self.tooltip_text = attr + ": " + tooltip
		if not self.has_focus():
			self.text = character.attributes[attr][1]
		
