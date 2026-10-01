extends Node

# ===============================
# TCP Configuration
# ===============================

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var host := "127.0.0.1"
var port := 9999
var stream_buffer := "" # Buffer to hold incoming raw TCP stream

# ===============================
# RL Variables
# ===============================

var player: CharacterBody2D = null
var initial_player_pos: Vector2

var current_reward := 0.0
var is_done := false

var apples_collected := 0
var total_apples := 0 # Calculated dynamically on start

var has_started := false

# ===============================
# Initialization
# ===============================

func _ready():
	print("==========================")
	print("Environment Started")
	print("==========================")

	add_to_group("environment")

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")

	if player:
		initial_player_pos = player.global_position
		print("Player found: ", player.name)
		print("Initial Position: ", initial_player_pos)
	else:
		push_error("Player NOT found!")
		return

	# Hardcode total apples to match the 2 apples present in the scene
	total_apples = 2
	print("Total Apples Registered: ", total_apples)

	connect_to_server()

func connect_to_server():
	print("Connecting to RL Server...")
	var err = tcp_client.connect_to_host(host, port)
	if err != OK:
		push_error("Connection failed: " + str(err))

# ===============================
# Main Loop
# ===============================

func _process(_delta):
	tcp_client.poll()

	if tcp_client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	if !has_started:
		has_started = true
		send_environment_reset()

	# Read all available bytes into buffer
	var bytes_available = tcp_client.get_available_bytes()
	if bytes_available > 0:
		stream_buffer += tcp_client.get_utf8_string(bytes_available)
		_process_stream_buffer()

# Helper to process frame-delimited JSON commands cleanly
func _process_stream_buffer():
	while stream_buffer.contains("\n"):
		var parts = stream_buffer.split("\n", true, 1)
		var line = parts[0].strip_edges()
		stream_buffer = parts[1] if parts.size() > 1 else ""
		
		if not line.is_empty():
			receive_action(line)

# ===============================
# State Computation
# ===============================

func get_discrete_state() -> String:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return "0_0_0_0_0_0"

	var apple_direction_x = 0
	var apple_direction_y = 0

	var target = get_nearest_apple()
	if target:
		apple_direction_x = sign(target.global_position.x - player.global_position.x)
		apple_direction_y = sign(target.global_position.y - player.global_position.y)

	var vertical_state = 0
	if player.velocity.y < -50:
		vertical_state = 1
	elif player.velocity.y > 50:
		vertical_state = -1

	var grounded = 1 if player.is_on_floor() else 0

	var snail_danger = 0
	for snail in get_tree().get_nodes_in_group("snails"):
		if abs(snail.global_position.x - player.global_position.x) < 150:
			snail_danger = 1
			break

	return "%d_%d_%d_%d_%d_%d" % [
		apples_collected,
		apple_direction_x,
		apple_direction_y,
		vertical_state,
		grounded,
		snail_danger
	]

func get_nearest_apple():
	var closest = null
	var best_distance = INF

	for apple in get_tree().get_nodes_in_group("apples"):
		# Only evaluate visible/active apples
		if apple.is_visible_in_tree():
			var d = player.global_position.distance_to(apple.global_position)
			if d < best_distance:
				best_distance = d
				closest = apple

	return closest

# ===============================
# Communication & Logic Flow
# ===============================

func send_data(message: String):
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var data = (message + "\n").to_utf8_buffer()
		tcp_client.put_data(data)

func send_environment_step():
	var packet = {
		"type": "step",
		"state": get_discrete_state(),
		"reward": current_reward,
		"done": is_done
	}
	send_data(JSON.stringify(packet))
	
	# Reset step reward counter after sending
	current_reward = 0.0

func send_environment_reset():
	if player:
		player.global_position = initial_player_pos
		player.velocity = Vector2.ZERO
		if player.has_method("reset"):
			player.reset()

	reset_apples()
	reset_snails()

	apples_collected = 0
	current_reward = 0.0
	is_done = false

	var packet = {
		"type": "reset",
		"state": get_discrete_state()
	}

	send_data(JSON.stringify(packet))

func reset_snails():
	for snail in get_tree().get_nodes_in_group("snails"):
		if snail.has_method("reset"):
			snail.reset()

func receive_action(raw_json: String):
	var data = JSON.parse_string(raw_json)
	if data == null or not (data is Dictionary):
		push_error("Failed to parse JSON action: " + raw_json)
		return

	var action = int(data.get("action", -1))

	# Action -1 is the acknowledgment from Python to reset the environment
	if action == -1:
		send_environment_reset()
		return

	# Apply step time penalty
	current_reward -= 0.05
	
	if player and player.has_method("execute_rl_action"):
		player.execute_rl_action(action)
	
	# Wait for physics simulation frame
	await get_tree().create_timer(0.1).timeout
	
	send_environment_step()

# ===============================
# Rewards & Triggers
# ===============================

func apple_collected():
	apples_collected += 1
	print("Apple Collected! Current: ", apples_collected, "/", total_apples)
	
	# ONLY set is_done to true when ALL apples are collected
	if apples_collected >= total_apples:
		current_reward += 200.0
		is_done = true
		print("ALL APPLES COLLECTED - Episode Marked Done!")
	else:
		current_reward += 50.0
		is_done = false  # Explicitly ensure episode continues

func snail_hit():
	current_reward -= 100.0
	is_done = true
	print("SNAIL HIT - Episode Marked Done!")

func reset_apples():
	for apple in get_tree().get_nodes_in_group("apples"):
		if apple.has_method("reset"):
			apple.reset()
