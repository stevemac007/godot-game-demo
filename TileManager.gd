extends Node
class_name TileManager

## Manages tile placement, removal, and availability
## Handles tile unlocking and inventory management

signal tile_placed(tile_type: String, position: Vector2i)
signal tile_removed(tile_type: String, position: Vector2i)
signal tile_unlocked(tile_type: String)
signal inventory_changed()

@export var starting_tiles: Dictionary = {
	"Producer": 3,
	"ConveyorBelt": 5,
	"Transformer": 1
}

var available_tiles: Dictionary = {}
var unlocked_tiles: Array[String] = []
var tile_costs: Dictionary = {}
var tile_scenes: Dictionary = {}
var hex_grid: HexGrid
var selected_tile_type: String = ""

# Tile unlock progression
var unlock_requirements: Dictionary = {}

func _ready():
	print("TileManager initialized")
	setup_tile_costs()
	setup_tile_scenes()
	setup_unlock_requirements()
	initialize_starting_tiles()

func setup_tile_costs():
	"""Setup the cost for each tile type"""
	tile_costs = {
		"Producer": 10,
		"Transformer": 25,
		"ConveyorBelt": 5,
		"CentralReceiver": 0  # Cannot be purchased
	}

func setup_tile_scenes():
	"""Setup references to tile scene classes"""
	tile_scenes = {
		"Producer": Producer,
		"Transformer": Transformer,
		"ConveyorBelt": ConveyorBelt,
		"CentralReceiver": CentralReceiver
	}

func setup_unlock_requirements():
	"""Setup requirements for unlocking new tiles"""
	unlock_requirements = {
		"Producer": {"level": 1},
		"ConveyorBelt": {"level": 1},
		"Transformer": {"level": 2},
		"AdvancedProducer": {"level": 3, "items_delivered": 50},
		"FastConveyor": {"level": 3, "total_value": 500},
		"MultiTransformer": {"level": 4, "items_delivered": 100},
		"PowerGenerator": {"level": 4, "total_value": 1000}
	}

func initialize_starting_tiles():
	"""Initialize the starting tile inventory"""
	available_tiles = starting_tiles.duplicate()
	
	# Unlock basic tiles
	for tile_type in starting_tiles.keys():
		if tile_type not in unlocked_tiles:
			unlocked_tiles.append(tile_type)
			tile_unlocked.emit(tile_type)
	
	inventory_changed.emit()
	print("Starting tiles initialized: ", available_tiles)

func set_hex_grid(grid: HexGrid):
	"""Set the reference to the hex grid"""
	hex_grid = grid
	if hex_grid:
		hex_grid.hex_clicked.connect(_on_hex_clicked)

func _on_hex_clicked(hex_coord: Vector2i):
	"""Handle hex grid clicks for tile placement"""
	if selected_tile_type == "":
		# No tile selected, try to remove existing tile
		remove_tile_at(hex_coord)
	else:
		# Try to place selected tile
		place_tile_at(hex_coord, selected_tile_type)

func place_tile_at(hex_coord: Vector2i, tile_type: String) -> bool:
	"""Place a tile at the specified hex coordinate"""
	if not hex_grid:
		print("No hex grid reference")
		return false
	
	if not can_place_tile(hex_coord, tile_type):
		return false
	
	# Create the tile
	var tile = create_tile(tile_type)
	if not tile:
		print("Failed to create tile: ", tile_type)
		return false
	
	# Place the tile on the grid
	if hex_grid.place_tile(hex_coord, tile):
		# Deduct from inventory
		if tile_type in available_tiles:
			available_tiles[tile_type] -= 1
			if available_tiles[tile_type] <= 0:
				available_tiles.erase(tile_type)
		
		tile_placed.emit(tile_type, hex_coord)
		inventory_changed.emit()
		
		print("Tile placed: ", tile_type, " at ", hex_coord)
		return true
	else:
		# Failed to place, clean up
		tile.queue_free()
		return false

func remove_tile_at(hex_coord: Vector2i) -> bool:
	"""Remove a tile at the specified hex coordinate"""
	if not hex_grid:
		return false
	
	var tile = hex_grid.get_tile(hex_coord)
	if not tile or not tile.can_be_destroyed:
		return false
	
	var tile_type = get_tile_type_name(tile)
	
	# Remove from grid
	hex_grid.remove_tile(hex_coord)
	
	# Return to inventory (optional - could be a game mechanic)
	if tile_type in available_tiles:
		available_tiles[tile_type] += 1
	else:
		available_tiles[tile_type] = 1
	
	tile_removed.emit(tile_type, hex_coord)
	inventory_changed.emit()
	
	print("Tile removed: ", tile_type, " from ", hex_coord)
	return true

func can_place_tile(hex_coord: Vector2i, tile_type: String) -> bool:
	"""Check if a tile can be placed at the specified location"""
	if not hex_grid:
		return false
	
	# Check if coordinate is valid
	if not hex_grid.is_valid_hex(hex_coord):
		print("Invalid hex coordinate: ", hex_coord)
		return false
	
	# Check if tile already exists
	if hex_grid.has_tile(hex_coord):
		print("Tile already exists at: ", hex_coord)
		return false
	
	# Check if tile type is available
	if tile_type not in available_tiles or available_tiles[tile_type] <= 0:
		print("Tile not available: ", tile_type)
		return false
	
	# Check if tile type is unlocked
	if tile_type not in unlocked_tiles:
		print("Tile not unlocked: ", tile_type)
		return false
	
	return true

func create_tile(tile_type: String) -> Tile:
	"""Create a new tile of the specified type"""
	if tile_type not in tile_scenes:
		print("Unknown tile type: ", tile_type)
		return null
	
	var tile_class = tile_scenes[tile_type]
	var tile = tile_class.new()
	
	# Configure tile based on type
	configure_tile(tile, tile_type)
	
	return tile

func configure_tile(tile: Tile, tile_type: String):
	"""Configure a tile with type-specific settings"""
	match tile_type:
		"Producer":
			tile.item_type_to_produce = get_random_producer_item()
		"Transformer":
			tile.transformation_type = get_random_transformer_type()
		"ConveyorBelt":
			# Default direction, can be changed by player
			pass
		"CentralReceiver":
			# Central receiver is unique
			pass

func get_random_producer_item() -> String:
	"""Get a random item type for producers"""
	var basic_items = ["wood", "stone", "basic_item"]
	var advanced_items = ["iron", "gold", "energy"]
	
	# Return basic items for early game, advanced for later
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.current_level >= 3:
		return advanced_items[randi() % advanced_items.size()]
	else:
		return basic_items[randi() % basic_items.size()]

func get_random_transformer_type() -> String:
	"""Get a random transformer type"""
	var basic_types = ["basic_processor", "combiner"]
	var advanced_types = ["refiner", "energy_converter"]
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.current_level >= 4:
		return advanced_types[randi() % advanced_types.size()]
	else:
		return basic_types[randi() % basic_types.size()]

func get_tile_type_name(tile: Tile) -> String:
	"""Get the type name of a tile"""
	if tile is Producer:
		return "Producer"
	elif tile is Transformer:
		return "Transformer"
	elif tile is ConveyorBelt:
		return "ConveyorBelt"
	elif tile is CentralReceiver:
		return "CentralReceiver"
	else:
		return "Unknown"

func select_tile_type(tile_type: String):
	"""Select a tile type for placement"""
	if tile_type in unlocked_tiles and tile_type in available_tiles:
		selected_tile_type = tile_type
		print("Selected tile type: ", tile_type)
	else:
		print("Cannot select tile type: ", tile_type)

func deselect_tile():
	"""Deselect the current tile type"""
	selected_tile_type = ""
	print("Tile deselected")

func add_tiles_to_inventory(tile_type: String, amount: int):
	"""Add tiles to the inventory"""
	if tile_type in available_tiles:
		available_tiles[tile_type] += amount
	else:
		available_tiles[tile_type] = amount
	
	inventory_changed.emit()
	print("Added ", amount, "x ", tile_type, " to inventory")

func unlock_new_tiles(level: int):
	"""Unlock new tiles based on level progression"""
	var game_manager = get_node_or_null("/root/GameManager")
	
	for tile_type in unlock_requirements.keys():
		if tile_type in unlocked_tiles:
			continue
		
		var requirements = unlock_requirements[tile_type]
		var can_unlock = true
		
		# Check level requirement
		if "level" in requirements and level < requirements["level"]:
			can_unlock = false
		
		# Check other requirements
		if game_manager:
			if "items_delivered" in requirements and game_manager.items_delivered < requirements["items_delivered"]:
				can_unlock = false
			if "total_value" in requirements and game_manager.current_score < requirements["total_value"]:
				can_unlock = false
		
		if can_unlock:
			unlock_tile(tile_type)

func unlock_tile(tile_type: String):
	"""Unlock a specific tile type"""
	if tile_type not in unlocked_tiles:
		unlocked_tiles.append(tile_type)
		
		# Add some tiles to inventory
		var initial_amount = 2
		add_tiles_to_inventory(tile_type, initial_amount)
		
		tile_unlocked.emit(tile_type)
		print("Tile unlocked: ", tile_type)

func reset_tiles():
	"""Reset all tiles (for game restart)"""
	available_tiles.clear()
	unlocked_tiles.clear()
	selected_tile_type = ""
	
	initialize_starting_tiles()
	print("Tiles reset")

func get_available_tiles() -> Dictionary:
	"""Get the current available tiles"""
	return available_tiles.duplicate()

func get_unlocked_tiles() -> Array[String]:
	"""Get the list of unlocked tiles"""
	return unlocked_tiles.duplicate()

func get_tile_cost(tile_type: String) -> int:
	"""Get the cost of a tile type"""
	return tile_costs.get(tile_type, 0)

func get_selected_tile_type() -> String:
	"""Get the currently selected tile type"""
	return selected_tile_type