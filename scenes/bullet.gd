extends Node2D

var vel = 0
var speed = 400
var is_active = false
var bullet_damage: float = 7.0


func _process(delta):
	if is_active:
		translate(vel * delta)


func activate(position_to_target: Vector2):
	var direction = global_position.direction_to(position_to_target)
	vel = direction * speed
	
	$Area2D/CollisionShape2D.disabled = false
	
	is_active = true


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if not body.is_dashing and not body.is_dead:
			body.add_health(-bullet_damage)
			queue_free()
