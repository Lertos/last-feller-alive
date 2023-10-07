extends Control

""" RPC breakdown
any_peer - sends on ALL connected peers (everyone will call that function locally)
authority - only when the authority calls the function, will it go out for everyone else to call it
call_local - when I call that RPC, I will also call that function on my end
call_remote - when I call that RPC, only remote peers will call it
reliable - uses TCP; slower but reliable
unreliable - uses UDP; fast but unreliable
unreliable_ordered - same as unreliable - but each piece of data comes in the correct order
"""

var address
var port
var player_name

var peer
var compression_type = ENetConnection.COMPRESS_RANGE_CODER


func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


#Gets called on the server and clients when someone connects
func peer_connected(id):
	print("Peer connected: " + str(id))


#Gets called on the server and clients when someone disconnects
func peer_disconnected(id):
	print("Peer disconnected: " + str(id))


#Gets called only from client-side
func connected_to_server():
	send_player_info.rpc_id(1, $VB/PlayerName.text, multiplayer.get_unique_id())
	
	print("Connected to server")


#Gets called only from client-side
func connection_failed():
	print("Connection failed")


#Sends info to all players when connected
@rpc("any_peer")
func send_player_info(name, id):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": name,
			"id": id
		}
	
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i)


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()

	if not is_valid_address_and_port():
		return
		
	if not is_name_empty():
		return

	var error = peer.create_server(port, 8)
	
	if error != OK:
		print("Server creation failed: " + str(error))
		return
	
	#Makes bandwidth usage a little more efficient
	peer.get_host().compress(compression_type)
	
	#Use the host connection as the local peer
	multiplayer.set_multiplayer_peer(peer)
	
	print("Server has been created. Waiting for players")
	
	send_player_info($VB/PlayerName.text, multiplayer.get_unique_id())


func is_valid_address_and_port() -> bool:
	#Get IP address and port, or assign defaults if debugging
	address = $VB/ServerIP.text
	port = $VB/Port.text
	
	if address == "":
		address = "localhost"
	if port == "":
		port = "8910"
		
	#Check that the port is a valid integer or show an error
	if not port.is_valid_int():
		$AcceptDialog.dialog_text = "Well, THAT doesn't seem like a valid port feller"
		$AcceptDialog.ok_button_text = "Get Me Out"
		$AcceptDialog.popup_centered()
		return false
	
	port = port.to_int()
	return true


func is_name_empty() -> bool:
	player_name = $VB/PlayerName.text
	
	if player_name == "":
		$AcceptDialog.dialog_text = "No nameless people here"
		$AcceptDialog.ok_button_text = "Accept Oppression"
		$AcceptDialog.popup_centered()
		return false

	return true


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	
	if not is_valid_address_and_port():
		return
	
	if not is_name_empty():
		return
		
	peer.create_client(address, port)
	peer.get_host().compress(compression_type)
	
	multiplayer.set_multiplayer_peer(peer)
	
	print("Server has been created. Waiting for players")


func _on_start_button_down():
	start_game.rpc()


@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://main.tscn").instantiate()
	
	get_tree().root.add_child(scene)
	self.hide()


func _on_accept_dialog_visibility_changed():
	$PopupHelper.visible = $AcceptDialog.visible
