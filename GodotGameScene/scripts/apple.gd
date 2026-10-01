extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1. Safely disable monitoring using set_deferred
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# 2. Hide the apple visually
		hide()
		
		# 3. Notify environment node that apple was collected
		var env = get_tree().get_first_node_in_group("environment")
		if env and env.has_method("apple_collected"):
			env.apple_collected()

# Function called when resetting the episode
func reset():
	# Safely re-enable monitoring using set_deferred
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	show()
