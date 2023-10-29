extends StaticBody2D

@onready var bullet_list = get_parent().get_parent().get_node("Bullets")
@onready var player_list = get_parent().get_parent().get_node("Players")

var targeted_player = null
var cannon_level: int = 1
var max_cannon_level: int = 5
var fire_rates: Array[float] = [1.0, 0.8, 0.6, 0.4, 0.2]


func _ready():
	set_fire_rate()
	
	var player_target_timer = Timer.new()
	
	player_target_timer.wait_time = 0.5
	player_target_timer.timeout.connect(find_closest_player)
	
	add_child(player_target_timer)
	
	player_target_timer.start()


func _process(delta):
	if targeted_player == null:
		return
		
	look_at(targeted_player.position)


func find_closest_player():
	var min_dist = 9999
	var closest_player = null
	
	for player in player_list.get_children():
		var dist_to_player = position.distance_to(player.position)
		
		if dist_to_player < min_dist:
			min_dist = dist_to_player
			closest_player = player
		
	targeted_player = closest_player


func _on_timer_timeout():
	if targeted_player == null:
		return
		
	var bullet_node = $Bullet.duplicate()
	
	bullet_list.add_child(bullet_node)
	
	bullet_node.position = position
	bullet_node.rotation = rotation
	bullet_node.visible = true
	
	bullet_node.activate(targeted_player.position)


func set_fire_rate():
	$Timer.stop()
	$Timer.wait_time = fire_rates[cannon_level - 1]
	$Timer.start()


func upgrade_cannon():
	if cannon_level + 1 > max_cannon_level:
		return
		
	cannon_level += 1
	
	switch_cannon_asset()
	set_fire_rate()


func switch_cannon_asset():
	$Sprite2D.texture = load("res://assets/cannon" + str(cannon_level) + ".png")
