extends Node2D

var rot_angle: float
var start_scale: float = 0
var beam_length_scale : float
var beam_width_scale: float = 1.5
var beam_width_active_scale: float = 10.0


func _ready():
	var rng = RandomNumberGenerator.new()
	
	rot_angle = rng.randf_range(0.0, 359.9)
	beam_length_scale = max(Config.arena_width, Config.arena_height) / 2
	
	rotation = rot_angle
	scale = Vector2(0, beam_length_scale)

	var tween_scale = create_tween()
	tween_scale.tween_property(self, "scale", Vector2(beam_width_scale, beam_length_scale), 2.0)
	tween_scale.tween_property(self, "scale", Vector2(beam_width_active_scale, beam_length_scale), 0.1)
	tween_scale.tween_property(self, "scale", Vector2(0, beam_length_scale), 0.1)
