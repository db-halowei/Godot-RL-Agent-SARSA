extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $jumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
var alive = true

# Set this to true during RL training to disable keyboard controls
@export var rl_controlled: bool = true 

func _ready() -> void:
	add_to_group("player")
	print("player.gd loaded: ", name)

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Apply gravity constantly regardless of input source
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jumping"

	# Manual Keyboard Control (only if NOT running RL)
	if not rl_controlled:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Execute Physics Engine Step
	move_and_slide()

	# Handle Visual Animations & Sprite Flipping
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			animated_sprite_2d.animation = "running"
		else:
			animated_sprite_2d.animation = "idle"

	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x < 0:
		animated_sprite_2d.flip_h = true

func execute_rl_action(action: int) -> void:
	if not alive:
		return

	match action:
		0: # Idle
			velocity.x = 0
		1: # Move Left
			velocity.x = -SPEED
		2: # Move Right
			velocity.x = SPEED
		3: # Jump
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				jump_sound.play()
		4: # Jump Right
			velocity.x = SPEED
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				jump_sound.play()
		5: # Jump Left
			velocity.x = -SPEED
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				jump_sound.play()

func die() -> void:
	if not alive:
		return
	alive = false
	death_sound.play()
	animated_sprite_2d.animation = "dying"
	
	# Notify the RL Environment of snail hit
	var env = get_tree().get_first_node_in_group("environment")
	if env and env.has_method("snail_hit"):
		env.snail_hit()

func reset() -> void:
	alive = true
	velocity = Vector2.ZERO
	animated_sprite_2d.animation = "idle"
