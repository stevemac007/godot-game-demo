extends Node
class_name MathGameManager

## Math Game Manager - handles math game specific logic
## Manages speed boosts, producer/transformer coordination, and game progression

signal speed_boost_applied(tile_type: String, boost_amount: float)
signal producers_spawned(producer_count: int)
signal game_setup_complete()

@export var speed_boost_percentage: float = 5.0  # 5% speed increase per boost

var central_receiver: CentralReceiver
var hex_grid: HexGrid
var tile_manager: TileManager

# Speed boost tracking
var producer_speed_boost: float = 1.0
var transformer_speed_boost: float = 1.0

# Initial producers for numbers 1, 2, 3, 5, 7
var initial_producer_numbers: Array[int] = [1, 2, 3, 5, 7]
var spawned_producers: Array[Producer] = []
var spawned_transformers: Array[Transformer] = []

func _ready():
	print("MathGameManager initialized")
	# Wait for other systems to be ready
	call_deferred("setup_math_game")

func setup_math_game():
	"""Setup the initial math game state"""
	find_game_components()
	connect_signals()
	spawn_initial_producers()
	spawn_initial_transformers()
	game_setup_complete.emit()
	print("Math game setup complete!")

func find_game_components():
	"""Find references to game components"""
	central_receiver = get_node_or_null("../CentralReceiver")
	hex_grid = get_node_or_null("../HexGrid")
	tile_manager = get_node_or_null("../TileManager")
	
	if not central_receiver:
		print("Warning: CentralReceiver not found")
	if not hex_grid:
		print("Warning: HexGrid not found")
	if not tile_manager:
		print("Warning: TileManager not found")

func connect_signals():
	"""Connect to relevant game signals"""
	if central_receiver:
		central_receiver.speed_boost_available.connect(_on_speed_boost_available)
		central_receiver.game_completed.connect(_on_game_completed)
		central_receiver.set_completed.connect(_on_set_completed)

func spawn_initial_producers():
	"""Spawn producers for numbers 1, 2, 3, 5, 7"""
	if not hex_grid:
		print("Cannot spawn producers: HexGrid not found")
		return
	
	var spawn_positions = get_producer_spawn_positions()
	
	for i in range(min(initial_producer_numbers.size(), spawn_positions.size())):
		var number = initial_producer_numbers[i]
		var position = spawn_positions[i]
		
		var producer = create_number_producer(number)
		if producer and hex_grid.place_tile_at_position(producer, position):
			spawned_producers.append(producer)
			print("Spawned producer for number ", number, " at position ", position)
	
	producers_spawned.emit(spawned_producers.size())

func spawn_initial_transformers():
	"""Spawn addition and subtraction transformers"""
	if not hex_grid:
		print("Cannot spawn transformers: HexGrid not found")
		return
	
	var transformer_positions = get_transformer_spawn_positions()
	
	# Spawn addition transformer
	if transformer_positions.size() > 0:
		var addition_transformer = create_math_transformer("addition")
		if addition_transformer and hex_grid.place_tile_at_position(addition_transformer, transformer_positions[0]):
			spawned_transformers.append(addition_transformer)
			print("Spawned addition transformer at position ", transformer_positions[0])
	
	# Spawn subtraction transformer
	if transformer_positions.size() > 1:
		var subtraction_transformer = create_math_transformer("subtraction")
		if subtraction_transformer and hex_grid.place_tile_at_position(subtraction_transformer, transformer_positions[1]):
			spawned_transformers.append(subtraction_transformer)
			print("Spawned subtraction transformer at position ", transformer_positions[1])

func create_number_producer(number: int) -> Producer:
	"""Create a producer configured for a specific number"""
	var producer = Producer.new()
	producer.configure_for_number(number)
	return producer

func create_math_transformer(operation: String) -> Transformer:
	"""Create a transformer configured for a math operation"""
	var transformer = Transformer.new()
	transformer.configure_for_operation(operation)
	return transformer

func get_producer_spawn_positions() -> Array[Vector2]:
	"""Get positions around the central receiver for producers"""
	var positions: Array[Vector2] = []
	var center = Vector2.ZERO  # Assuming central receiver is at origin
	var radius = 3  # Distance from center
	
	# Create a ring of positions around the center
	for i in range(initial_producer_numbers.size()):
		var angle = (i * 2 * PI) / initial_producer_numbers.size()
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		positions.append(pos)
	
	return positions

func get_transformer_spawn_positions() -> Array[Vector2]:
	"""Get positions for transformers"""
	var positions: Array[Vector2] = []
	var center = Vector2.ZERO
	var radius = 2
	
	# Place transformers closer to center
	positions.append(center + Vector2(radius, 0))  # Addition transformer
	positions.append(center + Vector2(-radius, 0))  # Subtraction transformer
	
	return positions

func _on_speed_boost_available():
	"""Handle when a speed boost becomes available"""
	print("Speed boost available! Player can choose to boost producers or transformers.")
	# This would typically trigger UI for player choice
	# For now, we'll implement a simple alternating system
	apply_next_speed_boost()

func apply_next_speed_boost():
	"""Apply speed boost alternating between producers and transformers"""
	if not central_receiver or not central_receiver.use_speed_boost():
		return
	
	var boost_multiplier = 1.0 + (speed_boost_percentage / 100.0)
	
	# Alternate between boosting producers and transformers
	if spawned_producers.size() > 0 and spawned_transformers.size() > 0:
		if producer_speed_boost <= transformer_speed_boost:
			apply_producer_speed_boost(boost_multiplier)
		else:
			apply_transformer_speed_boost(boost_multiplier)
	elif spawned_producers.size() > 0:
		apply_producer_speed_boost(boost_multiplier)
	elif spawned_transformers.size() > 0:
		apply_transformer_speed_boost(boost_multiplier)

func apply_producer_speed_boost(boost_multiplier: float):
	"""Apply speed boost to all producers"""
	producer_speed_boost *= boost_multiplier
	
	for producer in spawned_producers:
		if producer and is_instance_valid(producer):
			producer.apply_speed_boost(producer_speed_boost)
	
	speed_boost_applied.emit("producers", producer_speed_boost)
	print("Speed boost applied to producers: ", producer_speed_boost, "x")

func apply_transformer_speed_boost(boost_multiplier: float):
	"""Apply speed boost to all transformers"""
	transformer_speed_boost *= boost_multiplier
	
	for transformer in spawned_transformers:
		if transformer and is_instance_valid(transformer):
			transformer.apply_speed_boost(transformer_speed_boost)
	
	speed_boost_applied.emit("transformers", transformer_speed_boost)
	print("Speed boost applied to transformers: ", transformer_speed_boost, "x")

func _on_set_completed(set_number: int):
	"""Handle when a set of 10 numbers is completed"""
	print("Set ", set_number, " completed! Speed boost will be available.")

func _on_game_completed():
	"""Handle game completion"""
	print("MATH GAME COMPLETED! 10 of number 10 collected!")
	# Could trigger victory screen, statistics, etc.

func get_game_status() -> Dictionary:
	"""Get current game status"""
	return {
		"producer_speed_boost": producer_speed_boost,
		"transformer_speed_boost": transformer_speed_boost,
		"spawned_producers": spawned_producers.size(),
		"spawned_transformers": spawned_transformers.size(),
		"available_boosts": central_receiver.available_speed_boosts if central_receiver else 0,
		"completed_sets": central_receiver.completed_sets.size() if central_receiver else 0
	}

func reset_game():
	"""Reset the math game to initial state"""
	producer_speed_boost = 1.0
	transformer_speed_boost = 1.0
	
	# Clean up spawned tiles
	for producer in spawned_producers:
		if producer and is_instance_valid(producer):
			producer.queue_free()
	
	for transformer in spawned_transformers:
		if transformer and is_instance_valid(transformer):
			transformer.queue_free()
	
	spawned_producers.clear()
	spawned_transformers.clear()
	
	print("Math game reset")