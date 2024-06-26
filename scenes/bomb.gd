extends Node2D

var bomb_damage: float = 24.0


func _ready():
	var prime_loop_anim_time: float = 1.2
	var prime_count_before_explode: int = 3

	var min_bomb_scale: float = 1.8
	var max_bomb_scale: float = 2.3
	var max_circle_scale: float = 4
	
	var time_to_explode = prime_loop_anim_time * prime_count_before_explode
	var half_prime_anim_time = prime_loop_anim_time / 2.0
	var timer = Timer.new()
	
	add_child(timer)
	
	timer.timeout.connect(on_explosion)
	timer.wait_time = time_to_explode
	timer.start()
	
	var tween_circle_scale = $Circle.create_tween()
	tween_circle_scale.tween_property($Circle, "scale", Vector2(max_circle_scale, max_circle_scale),time_to_explode)

	var tween_circle_modulate = $Circle.create_tween()
	tween_circle_modulate.tween_property($Circle/Circle, "modulate", Color.html("#ffffff8c"), time_to_explode)

	var tween_bomb_scale = $Bomb.create_tween().set_loops()
	tween_bomb_scale.tween_property($Bomb, "scale", Vector2(max_bomb_scale, max_bomb_scale), half_prime_anim_time)
	tween_bomb_scale.tween_property($Bomb, "scale", Vector2(min_bomb_scale, min_bomb_scale), half_prime_anim_time)
	
	var tween_bomb_modulate = $Bomb.create_tween().set_loops()
	tween_bomb_modulate.tween_property($Bomb, "modulate", Color.html("#d72400"), half_prime_anim_time)
	tween_bomb_modulate.tween_property($Bomb, "modulate", Color.html("#ffffff"), half_prime_anim_time)
	
	await get_tree().create_timer(time_to_explode).timeout
	get_tree().get_root().get_node("Arena").play_sound(Enum.SOUND.BOMB)


func on_explosion():
	#Hide the current sprites
	$Circle.visible = false
	$Bomb.visible = false
	
	#Check for players inside the blast area
	for body in $Circle.get_overlapping_bodies():
		if body.is_in_group("player"):
			if not body.is_dashing and not body.is_dead:
				body.add_health(-bomb_damage)
	
	#Handle the explosion
	var explosion = $Explosion
	
	explosion.visible = true
	explosion.get_node("AnimationPlayer").play("explode")
