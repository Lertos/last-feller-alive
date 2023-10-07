extends CharacterBody2D

enum DIRECTION {LEFT, RIGHT}

var dir: DIRECTION = DIRECTION.RIGHT
var is_jumping: bool = false
var is_dead: bool = false
var is_hurt: bool = false

@export var speed = 500


func _ready():
	#Set the authority so we can do checks on if this is the local players object
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	$AnimationPlayer.play("idle")


func get_input():
	#If this player object is NOT our player, then simply return
	if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	if is_jumping or is_dead or is_hurt:
		return
	
	if Input.is_action_just_pressed("jump"):
		is_jumping = true
		$AnimationPlayer.play("jump")
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
	velocity = input_direction * speed
	
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


func stop_jumping():
	is_jumping = false


func stop_hurting():
	is_hurt = false


func _physics_process(delta):
	if is_dead:
		return
		
	get_input()
	move_and_slide()
