extends StaticBody2D

var rng = RandomNumberGenerator.new()

@export var is_static: bool = true
@export var min_size: int
@export var max_size: int
@export var min_grow_speed: float
@export var max_grow_speed: float

var grow_direction: Enum.GROW_DIRECTION
var grow_speed: float
var size_to_grow_to: int
var is_growing: bool = false
var is_initially_growing: bool = true


func setup_wall(dir: Enum.GROW_DIRECTION, is_static: bool):
	if is_static:
		return
	
	grow_direction = dir
	
	#Find the max size this wall can stick out
	size_to_grow_to = rng.randi_range(min_size, max_size)
	
	#Calculate the growth speed
	grow_speed = rng.randf_range(min_grow_speed, max_grow_speed)

	#Set the wall size of the axis not growing
	if grow_direction == Enum.GROW_DIRECTION.HORIZONTAL:
		scale.y = Config.wall_width
	elif grow_direction == Enum.GROW_DIRECTION.VERTICAL:
		scale.x = Config.wall_width

	$Timer.start()


func _process(delta):
	if is_growing:
		#Calculate the growth speed based on the size and how long it should take
		var delta_growth = size_to_grow_to * (grow_speed * delta)
		
		if grow_direction == Enum.GROW_DIRECTION.HORIZONTAL:
			if is_initially_growing:
				if scale.x < size_to_grow_to:
					scale.x += delta_growth
				else:
					scale.x = size_to_grow_to
					is_initially_growing = false
			else:
				if scale.x > 0:
					scale.x -= delta_growth
				else:
					scale.x = 0
					is_growing = false
					is_initially_growing = true
		elif grow_direction == Enum.GROW_DIRECTION.VERTICAL:
			if is_initially_growing:
				if scale.y < size_to_grow_to:
					scale.y += delta_growth
				else:
					scale.y = size_to_grow_to
					is_initially_growing = false
			else:
				if scale.y > 0:
					scale.y -= delta_growth
				else:
					scale.y = 0
					is_growing = false
					is_initially_growing = true


func _on_timer_timeout():
	is_growing = true
	return
	if grow_direction == Enum.GROW_DIRECTION.HORIZONTAL:
		scale.x += size_to_grow_to
	elif grow_direction == Enum.GROW_DIRECTION.VERTICAL:
		scale.y += size_to_grow_to
