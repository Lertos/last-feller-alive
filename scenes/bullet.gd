extends Node2D

var vel = 0
var speed = 400
var is_active = false


func _process(delta):
	if is_active:
		translate(vel * delta)


func activate(position_to_target: Vector2):
	var direction = global_position.direction_to(position_to_target)
	vel = direction * speed
	
	is_active = true


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if not body.is_dashing:
			queue_free()
