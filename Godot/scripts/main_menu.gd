#Author: Vladimír Horák
#Desc:
#Script controlling main menu scene

extends Control
var maplist

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.multiplayer_peer = null #end multiplayer if multiplayer was in progress
	Globals.client = false
	#set base path for all files
	if OS.is_debug_build():
		Globals.base_dir_path = "res:/" #project folder in debug - not working in export
	else:
		Globals.base_dir_path = OS.get_executable_path().get_base_dir() #executable file in export
		#can be changed to user:// to use default user application folder based on OS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_campaign_browser_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/Campaigns.tscn")


func _on_host_game_btn_pressed():
	$HostGameDialog/VBoxContainer/HBoxContainer/PortSpinBox.value = Globals.port
	$HostGameDialog.popup()


func _on_join_game_btn_pressed():
	$JoinGameDialog/VBoxContainer/HBoxContainer/IPLineEdit.text = Globals.ip
	$JoinGameDialog/VBoxContainer/HBoxContainer2/PortSpinBox.value = Globals.port
	$JoinGameDialog.popup()


func _on_host_game_dialog_confirmed():
	Globals.port = $HostGameDialog/VBoxContainer/HBoxContainer/PortSpinBox.value
	var max_players = $HostGameDialog/VBoxContainer/HBoxContainer2/MaxPlayersSpinBox.value
	Globals.enet_peer = ENetMultiplayerPeer.new()
	var err = Globals.enet_peer.create_server(Globals.port, max_players)
	if err:
		print(err)
		return
	multiplayer.multiplayer_peer = Globals.enet_peer
	#multiplayer.peer_connected.connect(server_on_connect)
	get_tree().change_scene_to_file("res://scenes/Campaigns.tscn")
	
	

func _on_join_game_dialog_confirmed():
	Globals.ip = $JoinGameDialog/VBoxContainer/HBoxContainer/IPLineEdit.text
	if Globals.ip.is_empty():
		Globals.ip = "127.0.0.1"
	if not Globals.ip.is_valid_ip_address():
		return
	Globals.port = $JoinGameDialog/VBoxContainer/HBoxContainer2/PortSpinBox.value
	Globals.enet_peer = ENetMultiplayerPeer.new()
	var err = Globals.enet_peer.create_client(Globals.ip, Globals.port)
	if err:
		print(err)
		return
	multiplayer.connected_to_server.connect(client_on_connect)
	multiplayer.server_disconnected.connect(Globals.on_server_disconnected)
	multiplayer.multiplayer_peer = Globals.enet_peer

#func server_on_connect():
	#print("client connected") # new player connected to server

func client_on_connect():
	get_tree().change_scene_to_file("res://scenes/player_lobby.tscn")
	

