extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 100.0
var direction = -1.0
var start_position: Vector2
var initial_direction = -1.0

signal player_died

func _ready() -> void:
	start_position = global_position
	add_to_group("snails")

func _process(delta: float) -> void:
	position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		var environment = get_tree().get_first_node_in_group("environment")
		if environment:
			environment.snail_hit()

		emit_signal("player_died", body)

# Reset method called during episode reset
func reset() -> void:
	global_position = start_position
	direction = initial_direction
	if animated_sprite_2d:
		animated_sprite_2d.flip_h = false
