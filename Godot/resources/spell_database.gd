extends Resource
class_name SpellDB

var database: SQLite

static func get_spellDB_path():
	if Globals.lobby == null or Globals.lobby.check_is_server():
		if Globals.settings == null: #should never happen, just in case
			Globals.settings = Settings_res.new()
			Globals.settings.load_settings()
			Globals.settings.apply_settings()
		return Globals.base_dir_path + "/" + Globals.settings.settings_dict["spellDB"]
	else:
		return Globals.base_dir_path + "/multiplayer_spells.db"

func test_db():
	create_spell_db()
	
	add_spell_to_db({"spell_name" = "magic missile","spell_level" = 1}, ["dnd2e", "invocation", "wizard"])
	add_spell_to_db({"spell_name" = "fireball","spell_level" = 3}, ["dnd2e", "invocation", "wizard"])
	add_spell_to_db({"spell_name" = "lesser invisibility","spell_level" = 1}, ["dnd2e", "illusion", "wizard"])
	add_spell_to_db({"spell_name" = "monster summoning","spell_level" = 3}, ["dnd2e", "conjuration", "wizard"])
	add_spell_to_db({"spell_name" = "create water","spell_level" = 1}, ["dnd2e", "enchant", "priest"])
	add_spell_to_db({"spell_name" = "sun scorch","spell_level" = 1}, ["dnd2e", "invocation", "priest"])
	
	add_color_to_keyword_in_db("wizard", Color.BLACK, 1)
	add_color_to_keyword_in_db("invocation", Color.RED, 2)
	add_color_to_keyword_in_db("enchant", Color.FOREST_GREEN, 2)
	
	get_spells_from_database([], [])
	get_spells_from_database(["dnd2e", "wizard"], [])
	get_spells_from_database(["dnd2e", "wizard"], ["invocation"])
	get_spells_from_database(["dnd2e", "wizard"], ["invocation", "illusion"])
	get_spells_from_database(["wizard"], [])
	get_spells_from_database([], ["conjuration"])
	
	
	#database.query("
	#SELECT * FROM
		#(SELECT s.spell_id, s.spell_name, s.spell_icon, s.spell_level, s.spell_attributes, s.spellcard_name, k.keyword_name, k.keyword_color
		#FROM spells s
		#INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
		#INNER JOIN keywords k ON sk.keyword_name = k.keyword_name
		#WHERE s.spell_id IN
			#(SELECT s.spell_id FROM spells s
			#INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
			#WHERE (sk.keyword_name = 'dnd2e'
			#OR sk.keyword_name = 'wizard')
			#GROUP BY s.spell_id
			#HAVING COUNT(s.spell_id) = 2
			#INTERSECT	
			#SELECT s.spell_id FROM spells s
			#INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
			#WHERE (sk.keyword_name = 'invocation'
			#OR sk.keyword_name = 'illusion')
			#GROUP BY s.spell_id)
		#ORDER BY k.keyword_color_priority DESC) filtered
	#GROUP BY filtered.spell_id
	#") 
	#print("\n\nspecial querry result: ", database.query_result, "\n\n")
	
	database.close_db()
	
	

func open_spell_db():
	if database != null:
		database.close_db()
	if FileAccess.file_exists(get_spellDB_path()):
		database = SQLite.new()
		database.path = get_spellDB_path()
		database.foreign_keys = true
		database.open_db()
		
	else:
		create_spell_db()

func create_spell_db():
	DirAccess.remove_absolute(get_spellDB_path())
	
	database = SQLite.new()
	database.path = get_spellDB_path()
	database.foreign_keys = true
	database.open_db()
	
	#spell table
	var table_dict = {}
	table_dict["spell_id"] = {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true}
	table_dict["spell_name"] = {"data_type":"text", "not_null": true}
	table_dict["spell_icon"] = {"data_type":"blob"}
	table_dict["spell_level"] = {"data_type":"int"}
	table_dict["spell_attributes"] = {"data_type":"text"}
	table_dict["spellcard_name"] = {"data_type":"text", "foreign_key": "spellcards.spellcard_name"}
	
	database.create_table("spells", table_dict)
	
	#keyword table
	table_dict = {}
	#table_dict["id"] = {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true}
	table_dict["keyword_name"] = {"data_type":"text", "not_null": true, "primary_key": true, "unique": true}
	table_dict["keyword_color"] = {"data_type":"text"}
	table_dict["keyword_color_priority"] = {"data_type":"int"}

	database.create_table("keywords", table_dict)
	
	#spell_keyword connection table
	table_dict = {}
	table_dict["spell_keyword_id"] = {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true}
	table_dict["spell_id"] = {"data_type":"int", "foreign_key": "spells.spell_id", "not_null": true}
	table_dict["keyword_name"] = {"data_type":"text", "foreign_key": "keywords.keyword_name", "not_null": true}

	database.create_table("spell_keywords", table_dict)
	
	#spellcard table
	table_dict = {}
	table_dict["spellcard_name"] = {"data_type":"text", "primary_key": true, "not_null": true}
	table_dict["spellcard_component_array"] = {"data_type":"text"}

	database.create_table("spellcards", table_dict)
	
	#search presets table
	table_dict = {}
	table_dict["preset_name"] = {"data_type":"text", "primary_key": true, "not_null": true}
	table_dict["preset_query"] = {"data_type":"text"} #contains full query expressiong - in case of custom query commands

	database.create_table("presets", table_dict)

func add_spell_to_db(spell_dict: Dictionary, keyword_array):
	print("add spell: ", spell_dict, " " ,keyword_array)
	if database == null:
		print("no spell database opened")
		return
	var spell_id
	if spell_dict.has("spell_id"):
		print("spell_exists")
		spell_id = spell_dict["spell_id"]
		edit_spell_in_db(spell_id, spell_dict)
		remove_all_spell_keywords_from_db(spell_id)
	else:
		database.insert_row("spells" ,spell_dict)
		spell_id = database.last_insert_rowid
	for keyword in keyword_array:
		add_spell_keyword_to_db(spell_id, keyword)
		
func edit_spell_in_db(spell_db_id, spell_dict):
	var success = database.update_rows("spells", "spell_id = " + str(spell_db_id), spell_dict)
	print("replace successful: ", success)

func add_spell_keyword_to_db(spell_db_id, keyword):
	if not has_keyword_in_db(keyword):
		database.insert_row("keywords", {"keyword_name": keyword})
	database.insert_row("spell_keywords", {"spell_id": spell_db_id, "keyword_name": keyword})
	
func has_keyword_in_db(keyword):
	var result_array = database.select_rows("keywords", "keyword_name = '" + keyword + "'", ["*"])
	print(result_array, keyword)
	if result_array.is_empty():
		return false
	return true
	
func remove_spell_keyword_from_db(spell_db_id, keyword):
	database.delete_rows("spell_keywords", "spell_id = " + str(spell_db_id) + " and keyword_name == \'" + keyword + "\'")
	
func remove_all_spell_keywords_from_db(spell_db_id):
	database.delete_rows("spell_keywords", "spell_id = " + str(spell_db_id))

func add_color_to_keyword_in_db(keyword, color: Color, priority: int = 0):
	if not has_keyword_in_db(keyword):
		database.insert_row("keywords", {"keyword_name": keyword, "keyword_color": var_to_str(color), "keyword_color_priority": priority})
	else:
		database.update_rows("keywords", "keyword_name = \'" + keyword + "\'", {"keyword_color": var_to_str(color), "keyword_color_priority": priority})
	
func add_spellcard_to_db(spellcard_name, component_array):
	database.insert_row("spellcards", {"spellcard_name": spellcard_name, "spellcard_component_array": var_to_str(component_array)})
	return database.last_insert_rowid
	
func edit_spellcard_in_db(spellcard_name, component_array):
	database.update_rows("spellcards", "spellcard_name = \'" + spellcard_name + "\'", {"spellcard_component_array": var_to_str(component_array)})

	
func get_spellcard_from_db(spellcard_name):
	var result_array = database.select_rows("spellcards", "spellcard_name = \'" + spellcard_name + "\'", ["*"])
	if result_array.is_empty():
		return null
	return result_array[0]
	
func add_preset_to_db(preset_name, query):
	database.insert_row("presets", {"preset_name": preset_name, "preset_query": query})
	
func edit_preset_in_db(preset_name, query):
	database.update_rows("presets", "preset_name = \'" + preset_name + "\'", {"preset_query": query})
	
func get_preset_from_db(preset_name):
	var result_array = database.select_rows("presets", "preset_name = \'" + preset_name + "\'", ["*"])
	if result_array.is_empty():
		return null
	return result_array[0]
	
func get_all_presets_from_db():
	var result_array = database.select_rows("presets", "", ["preset_name"])
	if result_array.is_empty():
		return null
	return result_array
	
func get_spells_from_database(must_have_all_keywords_array, must_have_one_keyword_array, calling_object = null):
	var query = construct_query(must_have_all_keywords_array, must_have_one_keyword_array)
	print(must_have_all_keywords_array, must_have_one_keyword_array)
	print("query: ", query)
	database.query(query)
	var result = database.query_result
	for spell in result:
		spell["spell_attributes"] = str_to_var(spell["spell_attributes"])
	if calling_object != null:
		calling_object.last_database_query = query
	return result
	
func get_all_keywords_of_spell(spell_id):
	return database.select_rows("spell_keywords", "spell_id = " + str(spell_id), ["keyword_name"])
	
func custom_select_query(query, calling_object = null):
	database.query(query)
	var result = database.query_result
	for spell in result:
		spell["spell_attributes"] = str_to_var(spell["spell_attributes"])
	if calling_object != null:
		calling_object.last_database_query = query
	return result
	
func custom_database_query(query):
	if query == "":
		return false
	return database.query(query)
	
func construct_query(must_have_all_keywords_array, must_have_one_keyword_array):
	var must_have_keywords_string = ""
	if must_have_all_keywords_array.size() > 0:
		must_have_keywords_string = "
			SELECT s.spell_id FROM spells s
			INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
			WHERE ("
		var first = true
		for keyword in must_have_all_keywords_array:
			if first:
				must_have_keywords_string += "sk.keyword_name = '" + keyword + "'"
				first = false
			else:
				must_have_keywords_string += "\n			OR sk.keyword_name = '" + keyword + "'"
		must_have_keywords_string += ")
			GROUP BY s.spell_id
			HAVING COUNT(s.spell_id) = " + str(must_have_all_keywords_array.size())
		if must_have_one_keyword_array.size() > 0: #has both - intersect
			must_have_keywords_string += "\n			INTERSECT"
	if must_have_one_keyword_array.size() > 0:
		must_have_keywords_string += "
			SELECT s.spell_id FROM spells s
			INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
			WHERE ("
		var first = true
		for keyword in must_have_one_keyword_array:
			if first:
				must_have_keywords_string += "sk.keyword_name = '" + keyword + "'"
				first = false
			else:
				must_have_keywords_string += "\n			OR sk.keyword_name = '" + keyword + "'"
		must_have_keywords_string += ")
			GROUP BY s.spell_id"
	if not must_have_keywords_string.is_empty():
		var query = "
	SELECT * FROM
		(SELECT s.spell_id, s.spell_name, s.spell_icon, s.spell_level, s.spell_attributes, s.spellcard_name, k.keyword_name, k.keyword_color
		FROM spells s
		INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
		INNER JOIN keywords k ON sk.keyword_name = k.keyword_name
		WHERE s.spell_id IN (" + must_have_keywords_string + ")
		ORDER BY k.keyword_color_priority DESC) filtered
	GROUP BY filtered.spell_id"
		return query
	else:
		var query = "
	SELECT * FROM
		(SELECT s.spell_id, s.spell_name, s.spell_icon, s.spell_level, s.spell_attributes, s.spellcard_name, k.keyword_name, k.keyword_color
		FROM spells s
		INNER JOIN spell_keywords sk ON s.spell_id = sk.spell_id
		INNER JOIN keywords k ON sk.keyword_name = k.keyword_name
		ORDER BY k.keyword_color_priority DESC) filtered
	GROUP BY filtered.spell_id"
		return query
