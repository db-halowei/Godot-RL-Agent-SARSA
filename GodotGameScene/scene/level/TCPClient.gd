extends Node

# --- Node References ---
@onready var player = $player   # Adjust paths to match your Scene Tree
@onready var apple = $apple
@onready var snail = $snail

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var host: String = "127.0.0.1"
var port: int = 9999

var current_reward: float = 0.0
var is_done: bool = false
var initial_player_pos: Vector2

func _ready() -> void:
	if player:
		initial_player_pos = player.global_position
	connect_to_server()

func connect_to_server() -> void:
	print("Attempting to connect to %s:%d..." % [host, port])
	var err = tcp_client.connect_to_host(host, port)
	if err != OK:
		print("Error initializing connection: ", err)

func _process(_delta: float) -> void:
	tcp_client.poll()
	var status = tcp_client.get_status()
	
	if status == StreamPeerTCP.STATUS_CONNECTED:
		if tcp_client.get_available_bytes() > 0:
			var data = tcp_client.get_utf8_string(tcp_client.get_available_bytes())
			_on_action_received(data)
			
func _physics_process(_delta: float) -> void:
	# Continuous small step penalty to encourage reaching the goal quickly
	current_reward -= 0.1 

# --- RL Helper Functions ---

# Convert continuous coordinates into a discrete string key for SARSA
func get_discrete_state() -> String:
	if not player or not apple:
		return "0_0"
	# Grid discretization (group positions into 32x32 pixel cells)
	var rel_x = int((apple.global_position.x - player.global_position.x) / 32.0)
	var rel_y = int((apple.global_position.y - player.global_position.y) / 32.0)
	return "%d_%d" % [rel_x, rel_y]

func send_environment_step():
	var packet = {
		"type": "step",
		"state": get_discrete_state(),
		"reward": current_reward,
		"done": is_done
	}
	send_data(JSON.stringify(packet))
	# Reset step reward tracker
	current_reward = 0.0 

func send_environment_reset():
	# Reset game objects to start positions
	if player:
		player.global_position = initial_player_pos
	is_done = false
	current_reward = 0.0
	
	var packet = {
		"type": "reset",
		"state": get_discrete_state()
	}
	send_data(JSON.stringify(packet))

func send_data(message: String) -> void:
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		tcp_client.put_utf8_string(message)

func _on_action_received(raw_json: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(raw_json)
	if parse_result == OK:
		var data = json.get_data()
		var action = int(data.get("action", -1))
		
		if action == -1:
			# Server commanded episode reset
			send_environment_reset()
		else:
			# Apply action to player: 0 = Left, 1 = Right, 2 = Jump
			if player.has_method("execute_rl_action"):
				player.execute_rl_action(action)
			
			# Step simulation state back to PyCharm
			send_environment_step()

# --- Collision Signals (Call these when player hits objects) ---
func _on_apple_collected():
	current_reward += 100.0  # Big reward for reaching goal
	is_done = true

func _on_snail_hit():
	current_reward -= 100.0  # Big penalty for dying
	is_done = true
