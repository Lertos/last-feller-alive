extends CharacterBody2D

var speed = 400
var is_active = false
var direction: Vector2


func _process(delta):
	if is_active:
		velocity = direction * speed
		
		if move_and_slide():
			queue_free()


func activate(position_to_target: Vector2):
	direction = global_position.direction_to(position_to_target)

	is_active = true
