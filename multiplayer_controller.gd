extends Control

@export var address = "localhost"
@export var port = 8910

var peer
var compression_type = ENetConnection.COMPRESS_RANGE_CODER

""" RPC breakdown
any_peer - sends on ALL connected peers (everyone will call that function locally)
authority - only when the authority calls the function, will it go out for everyone else to call it
call_local - when I call that RPC, I will also call that function on my end
call_remote - when I call that RPC, only remote peers will call it
reliable - uses TCP; slower but reliable
unreliable - uses UDP; fast but unreliable
unreliable_ordered - same as unreliable - but each piece of data comes in the correct order
"""

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	pass


#Gets called on the server and clients when someone connects
func peer_connected(id):
	print("Peer connected: " + str(id))


#Gets called on the server and clients when someone disconnects
func peer_disconnected(id):
	print("Peer disconnected: " + str(id))


#Gets called only from client-side
func connected_to_server():
	print("Connected to server")


#Gets called only from client-side
func connection_failed():
	print("Connection failed")


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_server(port, 8)
	
	if error != OK:
		print("Server creation failed: " + error)
		return
	
	#Makes bandwidth usage a little more efficient
	peer.get_host().compress(compression_type)
	
	#Use the host connection as the local peer
	multiplayer.set_multiplayer_peer(peer)
	
	print("Server has been created. Waiting for players")


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
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
