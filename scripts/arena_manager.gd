extends Node2D

enum DIFFICULTY {EASY, MEDIUM, HARD}

#Objects to spawn
const SCENE_PLAYER = preload("res://scenes/player.tscn")
const SCENE_WALL = preload("res://scenes/wall.tscn")
const SCENE_BEAM = preload("res://scenes/beam.tscn")
const SCENE_BOMB = preload("res://scenes/bomb.tscn")
const SCENE_CANNON = preload("res://scenes/cannon.tscn")
const SCENE_GRAVITY_FIELD = preload("res://scenes/gravity_field.tscn")
const SCENE_PULL_FIELD = preload("res://scenes/pull_field.tscn")

#Used to dynamically grab the correct settings for the difficulty
var difficulty_settings = {
	DIFFICULTY.EASY: {
		"initial_spawn_time": 8.0,
		"time_decrease_per_cannon": 0.5,
		"events_before_cannon": 6,
		"special_events_per_cannon": 1
	}
	#TODO: Fill this out for other difficulties
}

#Arena configuration variables
var chosen_difficulty: DIFFICULTY = DIFFICULTY.EASY
var distance_from_walls = Config.wall_width * 2

#Variables to keep track of game state
var total_events_since_cannon: int = 0
var special_events_since_cannon: int = 0

var rng = RandomNumberGenerator.new()


func _ready():
	#Set the initial time for spawning to start
	$SpawnerTimer.wait_time = difficulty_settings[chosen_difficulty]["initial_spawn_time"]
	$SpawnerTimer.timeout.connect(spawn_object)
	
	setup_arena_walls()
	setup_players()
	
	$SpawnerTimer.start()


func spawn_object():
	#If the counter is at 0, spawn a cannon. This is so we can keep count and just reset easily
	if total_events_since_cannon == 0:
		spawn_cannon()
	else:
		#TODO: Spawn random object
		pass

	if total_events_since_cannon > difficulty_settings[chosen_difficulty]["events_before_cannon"]:
		total_events_since_cannon = 0
	else:
		total_events_since_cannon += 1


func spawn_cannon():
	#TODO logic to spawn cannon
	
	$SpawnerTimer.stop()
	$SpawnerTimer.wait_time = max($SpawnerTimer.wait_time - difficulty_settings[chosen_difficulty]["time_decrease_per_cannon"], 1.0)
	$SpawnerTimer.start()


func setup_arena_walls():
	create_wall(
		$WallLeft, 
		-Config.wall_width / 2, 
		Config.arena_height / 2, 
		Config.wall_width, 
		Config.arena_height
	)
	create_wall(
		$WallRight, 
		Config.arena_width + Config.wall_width / 2, 
		Config.arena_height / 2, 
		Config.wall_width, 
		Config.arena_height
	)
	create_wall(
		$WallTop, 
		Config.arena_width / 2, 
		-Config.wall_width / 2, 
		Config.arena_width, 
		Config.wall_width
	)
	create_wall(
		$WallBottom, 
		Config.arena_width / 2, 
		Config.arena_height + Config.wall_width / 2, 
		Config.arena_width, 
		Config.wall_width
	)


func setup_players():
	var center_pos = Vector2(Config.arena_width / 2, Config.arena_height / 2)
	var player_size = SCENE_PLAYER.instantiate().get_node("Sprite2D").texture.get_size()
	
	var spot_index = 0
	
	for i in GameManager.players:
		var current_player = SCENE_PLAYER.instantiate()
		
		#Set the player objects name as the peer id so we can use this for authority reasons
		current_player.name = str(GameManager.players[i].id)
		current_player.get_node("Name").text = str(GameManager.players[i].name)
		
		$Players.add_child(current_player)
		
		match spot_index:
			0:
				current_player.position = center_pos + Vector2(-player_size.x, 0)
			1:
				current_player.position = center_pos + Vector2(-player_size.x, -player_size.y)
			2:
				current_player.position = center_pos + Vector2(0, -player_size.y)
			3:
				current_player.position = center_pos + Vector2(player_size.x, -player_size.y)
			4:
				current_player.position = center_pos + Vector2(player_size.x, 0)
			5:
				current_player.position = center_pos + Vector2(player_size.x, player_size.y)
			6:
				current_player.position = center_pos + Vector2(0, player_size.y)
			7:
				current_player.position = center_pos + Vector2(-player_size.x, player_size.y)
		
		spot_index += 1


func create_wall(wall_node: Node, posx: int, posy: int, scalex: int, scaley: int):
	wall_node.position.x = posx
	wall_node.position.y = posy
	
	wall_node.scale.x = scalex
	wall_node.scale.y = scaley
