extends CharacterBody2D

enum DIRECTION {LEFT, RIGHT}

var dir: DIRECTION = DIRECTION.RIGHT
var is_dashing: bool = false
var is_dead: bool = false
var is_hurt: bool = false

@export var normal_speed = 500
@export var dashing_speed = 900


func _ready():
	#Set the authority so we can do checks on if this is the local players object
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	$AnimationPlayer.play("idle")


func get_input():
	#If this player object is NOT our player, then simply return
	if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	if is_dashing or is_dead or is_hurt:
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("idle")
		return
	
	if Input.is_action_just_pressed("death"):
		is_dead = true
		$AnimationPlayer.play("death")
		return
		
	if Input.is_action_just_pressed("hurt"):
		is_hurt = true
		$AnimationPlayer.play("hurt")
		return
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("dash"):
		is_dashing = true
		
		velocity = input_direction * dashing_speed
		
		$AnimationPlayer.play("dash")
		return
	
	velocity = input_direction * normal_speed
	
	if input_direction == Vector2.ZERO:
		$AnimationPlayer.play("idle")
	else:
		if input_direction.x > 0 and dir == DIRECTION.LEFT:
			$Sprite2D.scale.x *= -1
			dir = DIRECTION.RIGHT
		elif input_direction.x < 0 and dir == DIRECTION.RIGHT:
			$Sprite2D.scale.x *= -1
			dir = DIRECTION.LEFT
		$AnimationPlayer.play("run")


func reset_state():
	is_dashing = false
	is_hurt = false


func _physics_process(delta):
	if is_dead:
		return
		
	get_input()
	move_and_slide()
