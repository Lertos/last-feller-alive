extends Node2D

var beam_width_scale: float = 1.5
var beam_width_active_scale: float = 10.0
var beam_damage: float = 18.0


func _ready():
	var rng = RandomNumberGenerator.new()
	
	var startup_time: float = 2.0
	var active_time: float = 0.1
	var disappear_time: float = 0.1
	
	var beam_length_scale : float = max(Config.arena_width, Config.arena_height)
	
	#Create a timer so we can check who the beam hit
	var timer = Timer.new()
	
	add_child(timer)
	
	timer.timeout.connect(on_active_beam)
	timer.wait_time = startup_time + active_time
	timer.start()
	
	#Set the original roitation randomly, and the scale so you can't see it's width
	rotation = rng.randf_range(0.0, 359.9)
	scale = Vector2(0, beam_length_scale)

	#Tween the different width increases/decreases
	var tween_scale = create_tween()
	tween_scale.tween_property(self, "scale", Vector2(beam_width_scale, beam_length_scale), startup_time)
	tween_scale.tween_property(self, "scale", Vector2(beam_width_active_scale, beam_length_scale), active_time)
	tween_scale.tween_property(self, "scale", Vector2(0, beam_length_scale), disappear_time)

	#Tween the color changes to emphasize when the beam actually goes off
	var tween_modulate = create_tween()
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#e50b00"), startup_time)
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#ffffff"), active_time)
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#740200"), disappear_time)


func on_active_beam():
	#Check for players inside the beam area
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			if not body.is_dashing and not body.is_dead:
				body.add_health(-beam_damage)
	
	queue_free()
