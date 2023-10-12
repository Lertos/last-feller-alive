extends Node2D

@export var prime_loop_anim_time: float = 1.2
@export var prime_count_before_explode: int = 3

@export var min_scale: float = 2.0
@export var max_scale: float = 2.3


func _ready():
	var time_to_explode = prime_loop_anim_time * prime_count_before_explode
	var half_prime_anim_time = prime_loop_anim_time / 2.0
	var timer = Timer.new()
	
	add_child(timer)
	
	timer.timeout.connect(on_explosion)
	timer.wait_time = time_to_explode
	timer.start()
	
	var tween_circle_scale = $Circle.create_tween()
	tween_circle_scale.tween_property($Circle, "scale", Vector2(max_scale, max_scale),time_to_explode)

	var tween_circle_modulate = $Circle.create_tween()
	tween_circle_modulate.tween_property($Circle, "modulate", Color.html("#ffffff8c"), time_to_explode)

	var tween_bomb_scale = $Bomb.create_tween().set_loops()
	tween_bomb_scale.tween_property($Bomb, "scale", Vector2(max_scale, max_scale), half_prime_anim_time)
	tween_bomb_scale.tween_property($Bomb, "scale", Vector2(min_scale, min_scale), half_prime_anim_time)
	
	var tween_bomb_modulate = $Bomb.create_tween().set_loops()
	tween_bomb_modulate.tween_property($Bomb, "modulate", Color.html("#d72400"), half_prime_anim_time)
	tween_bomb_modulate.tween_property($Bomb, "modulate", Color.html("#ffffff"), half_prime_anim_time)


func on_explosion():
	#Hide the current sprites
	$Circle.visible = false
	$Bomb.visible = false
	
	#Handle the explosion
	var explosion = $Explosion
	
	explosion.visible = true
	explosion.get_node("AnimationPlayer").play("explode")
