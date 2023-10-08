extends Control

const SCENE_LOBBY_PLAYER_OTHER = preload("res://scenes/lobby/lobby_player_other.tscn")
const MAX_PLAYERS = 8
const SPACE_BETWEEN = 16


func _ready():
	$VB/StartButton.visible = multiplayer.is_server()
	
	setup_player_spots()
	set_players_to_spots.rpc()
	

func setup_player_spots():
	var players_to_setup = MAX_PLAYERS - 1
	var space_per_player = SCENE_LOBBY_PLAYER_OTHER.instantiate().get_node("Sprite2D").texture.get_size().x + SPACE_BETWEEN
	
	for i in range(0, players_to_setup):
		var new_player = SCENE_LOBBY_PLAYER_OTHER.instantiate()
		
		new_player.visible = false
		
		$VB/Others/Players.add_child(new_player)
		
		if i % 2 == 0:
			new_player.position.x = (i / 2) * space_per_player
		elif i % 2 != 0:
			new_player.position.x -= (floor(i / 2) + 1) * space_per_player


@rpc("any_peer", "call_local")
func set_players_to_spots():
	var filled_spots = 0

	for i in GameManager.players:
		if GameManager.players[i].id != multiplayer.get_unique_id():
			var player_spot = $VB/Others/Players.get_child(filled_spots)
			
			player_spot.set_player_name(GameManager.players[i].name)
			player_spot.change_skin(GameManager.players[i].skin_index)
			player_spot.visible = true
			
			filled_spots += 1


@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://main.tscn").instantiate()
	
	get_tree().root.add_child(scene)
	self.hide()


func _on_start_button_pressed():
	start_game.rpc()
