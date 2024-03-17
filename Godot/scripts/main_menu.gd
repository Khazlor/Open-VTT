#Author: Vladimír Horák
#Desc:
#Script controlling main menu scene

extends Control
var maplist

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_campaign_browser_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/Campaigns.tscn")


func _on_host_game_btn_pressed():
	$HostGameDialog.popup()


func _on_join_game_btn_pressed():
	$JoinGameDialog.popup()


func _on_host_game_dialog_confirmed():
	var port = $HostGameDialog/VBoxContainer/HBoxContainer/PortSpinBox.value
	var max_players = $HostGameDialog/VBoxContainer/HBoxContainer2/MaxPlayersSpinBox.value
	Globals.enet_peer = ENetMultiplayerPeer.new()
	var err = Globals.enet_peer.create_server(port, max_players)
	if err:
		print(err)
		return
	multiplayer.multiplayer_peer = Globals.enet_peer
	multiplayer.peer_connected.connect(server_on_connect)
	get_tree().change_scene_to_file("res://scenes/Campaigns.tscn")
	
	

func _on_join_game_dialog_confirmed():
	var ip: String = $JoinGameDialog/VBoxContainer/HBoxContainer/IPLineEdit.text
	if ip.is_empty():
		ip = "127.0.0.1"
	if not ip.is_valid_ip_address():
		return
	var port = $JoinGameDialog/VBoxContainer/HBoxContainer2/PortSpinBox.value
	var max_players = $HostGameDialog/VBoxContainer/HBoxContainer2/MaxPlayersSpinBox.value
	Globals.enet_peer = ENetMultiplayerPeer.new()
	var err = Globals.enet_peer.create_client(ip, port)
	if err:
		print(err)
		return
	multiplayer.connected_to_server.connect(client_on_connect)
	multiplayer.multiplayer_peer = Globals.enet_peer


func _on_multiplayer_synchronizer_synchronized():
	print("synch")


func _on_multiplayer_synchronizer_delta_synchronized():
	print("synch")

func server_on_connect():
	print("client connected") # new player connected to server

func client_on_connect():
	get_tree().change_scene_to_file("res://scenes/player_lobby.tscn")
