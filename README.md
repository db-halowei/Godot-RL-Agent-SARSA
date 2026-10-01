# SARSA Reinforcement Learning — 2D Platform Collector

A reinforcement learning implementation that trains an agent to play a **2D Platform Collector Game** developed in Godot. The project applies the **SARSA (State–Action–Reward–State–Action)** algorithm to learn action-selection policies through repeated interaction with the game environment.

The RL agent communicates with the Godot game through a TCP connection, receives the current game state and reward, selects an action using an ε-greedy policy, and updates its Q-table based on the observed transition.

## 🚀 Key Engineering Features

* **SARSA Reinforcement Learning** — Implements an on-policy temporal-difference learning algorithm.
* **Q-Table Learning** — Stores action-value estimates for discrete game states.
* **ε-Greedy Policy** — Balances exploration of new actions with exploitation of learned actions.
* **State Representation** — Encodes apple collection status, apple direction, vertical state, grounded status, and nearby snail danger.
* **Action Space** — Supports left, right, and jump actions.
* **Reward-Based Learning** — Uses positive rewards for collecting apples and penalties for time progression and enemy encounters.
* **Godot–Python Communication** — Uses TCP and JSON messages to exchange states, actions, rewards, and game status.
* **Training & Testing Modes** — Supports separate training and evaluation using the learned Q-table.
* **Performance Analysis** — Records training performance for evaluating learning behavior.

## 🛠️ Technical Stack

* **Python 3**
* **Godot 4**
* **SARSA**
* **Q-Table**
* **TCP / JSON Communication**
* **NumPy / Matplotlib**
* **PyCharm**
* **Git / GitHub**

## 🧠 SARSA Learning Architecture

The project follows the SARSA interaction cycle:

**State → Action → Reward → Next State → Next Action → Q-Table Update**

At each step, the agent observes the current state of the Godot environment and selects an action using an ε-greedy policy. After receiving the resulting reward and next state, the agent selects the next action and updates the Q-value using the SARSA update rule.

The main learning parameters are:

* **Learning Rate (α):** 0.1
* **Discount Factor (γ):** 0.9
* **Exploration Rate (ε):** 0.2
* **Actions:** Left, Right, Jump

## 🎮 Game Environment

The Godot environment contains:

* Player character
* Platforms
* Apples as collectible rewards
* Snail enemies
* Falling / unsafe areas
* Level boundaries

The agent's state representation includes information such as:

* Number of apples collected
* Horizontal direction toward the nearest apple
* Vertical direction toward the nearest apple
* Player vertical state
* Whether the player is grounded
* Nearby snail danger

This compact state representation allows the SARSA agent to learn a discrete policy without requiring a neural network.

## 🔄 Godot–Python Interaction

The system is divided into two main components:

**Godot Environment**

* Runs the platform game.
* Tracks the player, apples, and snail enemies.
* Generates the current state.
* Calculates rewards.
* Receives and executes agent actions.

**Python SARSA Agent**

* Connects to Godot through TCP.
* Receives state information.
* Selects actions using ε-greedy exploration.
* Updates the Q-table.
* Saves and loads the learned policy.
* Supports training and testing modes.

Communication is handled using **JSON messages over a local TCP connection**.

## 📊 Training & Evaluation

The agent is trained through repeated episodes of interaction with the Godot environment. During training, the Q-table is progressively updated as the agent experiences different states and actions.

Performance can be evaluated using metrics such as:

* Total reward per episode
* Apples collected
* Game score
* Enemy encounters
* Episode performance
* Learning curve
* Training time

Training results are visualized to examine whether the agent improves its gameplay behavior over time.

## 💻 Project Structure

```text
project/
├── godot/
│   ├── environment.gd
│   ├── player.gd
│   ├── apple.gd
│   ├── snail.gd
│   └── main.gd
│
├── sarsa.py
├── q_table.json
├── training_results/
└── README.md
```

## 🎯 Learning Outcomes

This project demonstrates practical experience with:

* Reinforcement learning
* SARSA and temporal-difference learning
* Q-table implementation
* Exploration vs. exploitation
* State, action, and reward design
* Game-agent interaction
* TCP client-server communication
* JSON-based data exchange
* Training and evaluation of RL agents
* Performance visualization and analysis

## 📌 Project Context

**Project:** 2D Platform Collector Game
**Reinforcement Learning Technique:** SARSA
**Environment:** Godot 4
**Agent:** Python 3
**Development Environment:** PyCharm + Godot
