extends Node
class_name GameManager

## Main game manager that handles the overall game state and coordination
## between different systems in the hexagonal tile placement game

signal game_state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal level_completed(level: int)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

@export var starting_tiles: int = 5
@export var target_items_per_level: int = 10

var current_state: GameState = GameState.MENU
var current_score: int = 0
var current_level: int = 1
var items_delivered: int = 0

# References to game systems
var hex_grid: HexGrid
var tile_manager: TileManager
var item_system: ItemSystem
var central_receiver: CentralReceiver
var ui_manager: UIManager

func _ready():
	print("GameManager initialized")
	setup_game_systems()
	change_state(GameState.PLAYING)

func setup_game_systems():
	"""Initialize and connect all game systems"""
	# Find or create game system nodes
	hex_grid = get_node_or_null("HexGrid")
	tile_manager = get_node_or_null("TileManager") 
	item_system = get_node_or_null("ItemSystem")
	central_receiver = get_node_or_null("CentralReceiver")
	ui_manager = get_node_or_null("UIManager")
	
	# Connect signals between systems
	if central_receiver:
		central_receiver.item_received.connect(_on_item_received)
	
	if tile_manager:
		tile_manager.tile_placed.connect(_on_tile_placed)

func change_state(new_state: GameState):
	"""Change the current game state"""
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

func add_score(points: int):
	"""Add points to the current score"""
	current_score += points
	score_changed.emit(current_score)

func _on_item_received(item_type: String, value: int):
	"""Handle when an item is received by the central receiver"""
	items_delivered += 1
	add_score(value)
	
	print("Item received: ", item_type, " (Value: ", value, ")")
	
	# Check if level is complete
	if items_delivered >= target_items_per_level:
		complete_level()

func complete_level():
	"""Handle level completion"""
	current_level += 1
	items_delivered = 0
	target_items_per_level += 2  # Increase difficulty
	
	level_completed.emit(current_level - 1)
	print("Level ", current_level - 1, " completed! Starting level ", current_level)
	
	# Unlock new tiles or mechanics here
	if tile_manager:
		tile_manager.unlock_new_tiles(current_level)

func _on_tile_placed(tile_type: String, position: Vector2i):
	"""Handle when a tile is placed on the grid"""
	print("Tile placed: ", tile_type, " at ", position)

func pause_game():
	"""Pause the game"""
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true

func resume_game():
	"""Resume the game"""
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false

func restart_game():
	"""Restart the current game"""
	current_score = 0
	current_level = 1
	items_delivered = 0
	target_items_per_level = 10
	
	# Reset all systems
	if hex_grid:
		hex_grid.clear_grid()
	if tile_manager:
		tile_manager.reset_tiles()
	if item_system:
		item_system.clear_all_items()
	
	change_state(GameState.PLAYING)
	print("Game restarted")

func _input(event):
	"""Handle global input events"""
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()