extends Node

var peer = StreamPeerTCP.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	var ip = multiplayer.multiplayer_peer.get_peer(1).get_remote_address()
	var error = peer.connect_to_host(ip, 8080)
	if error == OK:
		print("TCP Connected successfully!")
		peer.poll()
		print(peer.get_status())
	else:
		print("TCP Failed to connect.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if peer.get_available_bytes() > 0:
			var data: PackedByteArray = peer.get_data(peer.get_available_bytes())
			print("Received data: ", data)
			var file_name = data.decode_var(0)
			var len = data.decode_var_size(0)
			data = data.slice(len)
			var file = FileAccess.open("res://images/" + file_name, FileAccess.WRITE)
			file.store_buffer(data)


func send_image_test():
	var data: PackedByteArray = []
	data.resize(256)
	data.encode_var(0, ["put", "sent_image.png"])
	var len = data.decode_var_size(0)
	if len < 4:
		print("name too long")
		return
	data.resize(data.decode_var_size(0))
	print("data header :", data)
	data.append_array(FileAccess.get_file_as_bytes("res://images/grid.png"))
	send_data(data)


func send_data(data: PackedByteArray):
	print("sending data :", data)
	var err = peer.put_data(data)
	print("send err = ", err)
