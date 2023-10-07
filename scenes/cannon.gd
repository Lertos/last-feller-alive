extends StaticBody2D

@onready var bullet_list = get_parent().get_parent().get_node("Bullets")

var targeted_player = null


func _ready():
	pass


func _on_timer_timeout():
	if targeted_player == null:
		return
		
	var bullet_node = $Bullet.duplicate()
	
	bullet_list.add_child(bullet_node)
	
	bullet_node.position = position
	bullet_node.rotation = rotation
	bullet_node.visible = true
	
	bullet_node.activate(targeted_player.position)


func set_target(player: Node):
	targeted_player = player
