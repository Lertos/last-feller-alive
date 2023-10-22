extends StaticBody2D

@onready var bullet_list = get_parent().get_parent().get_node("Bullets")

var targeted_player = null
var cannon_level: int = 1
var max_cannon_level: int = 5
var fire_rates: Array[float] = [1.0, 0.8, 0.6, 0.4, 0.2]


func _ready():
	set_fire_rate()


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


func set_target(player: Node):
	targeted_player = player
	

func upgrade_cannon():
	if cannon_level + 1 > max_cannon_level:
		return
		
	cannon_level += 1
	
	switch_cannon_asset()
	set_fire_rate()


func switch_cannon_asset():
	$Sprite2D.texture = load("res://assets/cannon" + str(cannon_level) + ".png")
