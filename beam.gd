extends Node2D

var beam_width_scale: float = 1.5
var beam_width_active_scale: float = 10.0


func _ready():
	var rng = RandomNumberGenerator.new()
	
	var startup_time: float = 2.0
	var active_time: float = 0.1
	var disappear_time: float = 0.1
	
	var beam_length_scale : float = max(Config.arena_width, Config.arena_height) / 2
	
	rotation = rng.randf_range(0.0, 359.9)
	scale = Vector2(0, beam_length_scale)

	var tween_scale = create_tween()
	tween_scale.tween_property(self, "scale", Vector2(beam_width_scale, beam_length_scale), startup_time)
	tween_scale.tween_property(self, "scale", Vector2(beam_width_active_scale, beam_length_scale), active_time)
	tween_scale.tween_property(self, "scale", Vector2(0, beam_length_scale), disappear_time)

	var tween_modulate = create_tween()
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#e50b00"), startup_time)
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#ffffff"), active_time)
	tween_modulate.tween_property($Sprite2D, "modulate", Color.html("#740200"), disappear_time)
