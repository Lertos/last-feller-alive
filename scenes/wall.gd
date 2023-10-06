extends StaticBody2D

var rng = RandomNumberGenerator.new()

@export var is_static: bool = true
@export var min_size: int = 20
@export var max_size: int = 200
@export var grow_speed: int = 2

var grow_to_x_size: int
var grow_to_y_size: int


func _ready():
	if not is_static:
		grow_to_x_size = rng.randi_range(min_size, max_size)
		grow_to_y_size = rng.randi_range(min_size, max_size)
		
		$Timer.start()


func _on_timer_timeout():
	if scale.x >= grow_to_x_size and scale.y >= grow_to_y_size:
		$Timer.stop()
	else:
		if scale.x < grow_to_x_size:
			scale.x += grow_speed
		if scale.y < grow_to_y_size:
			scale.y += grow_speed
