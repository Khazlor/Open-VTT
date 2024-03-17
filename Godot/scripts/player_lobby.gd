extends Node2D

var map_comp = preload("res://scenes/map.tscn")
var map
var tcp_server_comp = preload("res://components/tcp_server.tscn")
var tcp_server
var tcp_client_comp = preload("res://components/tcp_client.tscn")
var tcp_client

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.spawner = $MultiplayerSpawner
	#multiplayer.allow_object_decoding = true
	if multiplayer.is_server(): #server
		#start tcp server for file transfer:
		tcp_server = tcp_server_comp.instantiate()
		add_child(tcp_server)
		
		map = map_comp.instantiate()
		add_child(map)
		#set all connected peers to this map
		var file_buffer = FileAccess.get_file_as_bytes("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name)
		var file_buffer_size = file_buffer.size()
		file_buffer = file_buffer.compress()
		client_set_map.rpc(file_buffer, file_buffer_size)
		
	else:
		tcp_client = tcp_client_comp.instantiate()
		add_child(tcp_client)
		
		server_get_map.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


@rpc("any_peer", "call_remote", "reliable")
func server_get_map():
	if multiplayer.is_server(): #just to be sure
		var sender_id = multiplayer.get_remote_sender_id()
		print("returtning", map)
		var layers = $Map/Draw/Layers
		if layers != null:
			Globals.new_map.save_map(layers)
			#var file = FileAccess.open("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name, FileAccess.READ)
			#var file_buffer = file.get_buffer(file.get_length())
			var file_buffer = FileAccess.get_file_as_bytes("res://saves/Campaigns/" + Globals.campaign.campaign_name + "/maps/" + Globals.new_map.map_name)
			var file_buffer_size = file_buffer.size()
			file_buffer = file_buffer.compress()
			call_rpc_client_set_map(sender_id, file_buffer, file_buffer_size)
			
func call_rpc_client_set_map(sender_id, file_buffer, file_buffer_size):
	client_set_map.rpc_id(sender_id, file_buffer, file_buffer_size)
		
@rpc("authority", "call_remote", "reliable")
func client_set_map(server_map_file_buffer, file_buffer_size):
	if map != null: #free old map
		map.queue_free()
	print(multiplayer.get_unique_id(), " client set map")
	server_map_file_buffer = server_map_file_buffer.decompress(file_buffer_size)
	var file = FileAccess.open("res://temp.file", FileAccess.WRITE_READ)
	file.store_var(server_map_file_buffer)
	file.flush()
	print("set ", file.get_length())
	file.seek(12)#skip buffer header created by FileAccess get_file_as_bytes or get_buffer
	Globals.new_map = Map_res.new()
	Globals.map = Globals.new_map
	map = map_comp.instantiate()
	Globals.draw_layer = map.get_node("Draw/Layers")
	Globals.new_map.load_map("", true, file)
	add_child(map)

@rpc("any_peer", "call_remote", "reliable")
func tcp_send_file(path):
	pass


func _on_button_pressed():
	if tcp_client != null:
		tcp_client.send_image_test()
