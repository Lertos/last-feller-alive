extends Control

const SCENE_LOBBY_PLAYER_OTHER = preload("res://scenes/lobby/lobby_player_other.tscn")
const MAX_PLAYERS = 8
const SPACE_BETWEEN = 16


func _ready():
	setup_player_spots()
	

func setup_player_spots():
	var players_to_setup = MAX_PLAYERS - 1
	var space_per_player = SCENE_LOBBY_PLAYER_OTHER.instantiate().get_node("Sprite2D").texture.get_size().x + SPACE_BETWEEN
	
	for i in range(0, players_to_setup):
		var new_player = SCENE_LOBBY_PLAYER_OTHER.instantiate()
		
		$VB/Others/Players.add_child(new_player)
		
		new_player.set_player_name("Player " + str(i))
		
		if i % 2 == 0:
			new_player.position.x = (i / 2) * space_per_player
		elif i % 2 != 0:
			new_player.position.x -= (floor(i / 2) + 1) * space_per_player
