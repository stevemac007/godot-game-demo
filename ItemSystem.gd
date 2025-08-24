extends Node
class_name ItemSystem

## Manages the flow of items throughout the game
## Handles item creation, movement, processing, and cleanup

signal item_created(item: Item)
signal item_destroyed(item: Item)
signal item_flow_updated()

@export var update_interval: float = 0.5
@export var max_items_in_system: int = 500

var update_timer: Timer
var all_items: Array[Item] = []
var item_flows: Dictionary = {}  # Track item movement between tiles
var processing_queue: Array[Item] = []

# Performance tracking
var items_created_this_frame: int = 0
var items_destroyed_this_frame: int = 0

func _ready():
	print("ItemSystem initialized")
	setup_update_timer()

func setup_update_timer():
	"""Setup the system update timer"""
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = update_interval
	update_timer.timeout.connect(_on_system_update)
	update_timer.autostart = true

func _on_system_update():
	"""Handle system update tick"""
	update_item_flows()
	process_item_queue()
	cleanup_destroyed_items()
	update_performance_stats()

func register_item(item: Item):
	"""Register a new item in the system"""
	if item in all_items:
		return
	
	all_items.append(item)
	item.item_destroyed.connect(_on_item_destroyed)
	
	items_created_this_frame += 1
	item_created.emit(item)
	
	print("Item registered: ", item.item_type, " (Total items: ", all_items.size(), ")")

func _on_item_destroyed(item: Item):
	"""Handle when an item is destroyed"""
	if item in all_items:
		all_items.erase(item)
	
	if item in processing_queue:
		processing_queue.erase(item)
	
	items_destroyed_this_frame += 1
	item_destroyed.emit(item)

func update_item_flows():
	"""Update the flow of items between tiles"""
	var hex_grid = get_hex_grid()
	if not hex_grid:
		return
	
	var tiles = hex_grid.get_all_tiles()
	
	for tile in tiles:
		if tile is ConveyorBelt:
			# Conveyor belts handle their own item flow
			continue
		
		# Handle item output from producers and transformers
		if tile.has_output_item():
			try_move_item_from_tile(tile)

func try_move_item_from_tile(source_tile: Tile):
	"""Try to move an item from a source tile to adjacent tiles"""
	if not source_tile.has_output_item():
		return
	
	var hex_grid = get_hex_grid()
	if not hex_grid:
		return
	
	var neighbors = hex_grid.get_hex_neighbors(source_tile.hex_coordinate)
	var item = source_tile.get_output_item()
	
	if not item:
		return
	
	# Try to find an accepting neighbor
	for neighbor_coord in neighbors:
		var neighbor_tile = hex_grid.get_tile(neighbor_coord)
		if neighbor_tile and neighbor_tile.can_accept_item(item):
			# Move item to neighbor
			if neighbor_tile.add_input_item(item):
				# Move item visually
				var target_pos = neighbor_tile.global_position
				item.move_to(target_pos, 1.0)
				
				# Track the flow
				track_item_flow(source_tile, neighbor_tile, item)
				return
	
	# No accepting neighbor found, item stays in source
	source_tile.produce_item(item)

func track_item_flow(from_tile: Tile, to_tile: Tile, item: Item):
	"""Track item flow between tiles for analytics"""
	var flow_key = str(from_tile.hex_coordinate) + "->" + str(to_tile.hex_coordinate)
	
	if flow_key in item_flows:
		item_flows[flow_key] += 1
	else:
		item_flows[flow_key] = 1
	
	item_flow_updated.emit()

func process_item_queue():
	"""Process items in the processing queue"""
	var items_to_process = processing_queue.duplicate()
	processing_queue.clear()
	
	for item in items_to_process:
		if is_instance_valid(item):
			process_item_logic(item)

func process_item_logic(item: Item):
	"""Handle item-specific processing logic"""
	# Items can have time-based effects, decay, etc.
	
	# Example: Items lose quality over time
	if item.quality > 0.1:
		item.quality *= 0.999  # Very slow decay
	
	# Example: Energy items might have special behavior
	if item.item_type == "energy":
		handle_energy_item(item)

func handle_energy_item(item: Item):
	"""Handle special behavior for energy items"""
	# Energy items could power nearby tiles
	var hex_grid = get_hex_grid()
	if not hex_grid:
		return
	
	# Find the tile this item is on/near
	var nearest_tile = find_nearest_tile(item.global_position)
	if nearest_tile and nearest_tile is Producer:
		nearest_tile.set_power_level(1.5)  # Boost power

func find_nearest_tile(position: Vector2) -> Tile:
	"""Find the nearest tile to a given position"""
	var hex_grid = get_hex_grid()
	if not hex_grid:
		return null
	
	var hex_coord = hex_grid.pixel_to_hex(position)
	return hex_grid.get_tile(hex_coord)

func cleanup_destroyed_items():
	"""Clean up references to destroyed items"""
	# Remove invalid items from the array
	all_items = all_items.filter(func(item): return is_instance_valid(item))

func update_performance_stats():
	"""Update performance statistics"""
	# Reset frame counters
	items_created_this_frame = 0
	items_destroyed_this_frame = 0
	
	# Check if we're approaching the item limit
	if all_items.size() > max_items_in_system * 0.9:
		print("Warning: Approaching maximum item limit (", all_items.size(), "/", max_items_in_system, ")")

func clear_all_items():
	"""Clear all items from the system"""
	for item in all_items:
		if is_instance_valid(item):
			item.queue_free()
	
	all_items.clear()
	processing_queue.clear()
	item_flows.clear()
	
	print("All items cleared from system")

func get_item_count_by_type() -> Dictionary:
	"""Get count of items by type"""
	var counts: Dictionary = {}
	
	for item in all_items:
		if is_instance_valid(item):
			var item_type = item.item_type
			if item_type in counts:
				counts[item_type] += item.stack_size
			else:
				counts[item_type] = item.stack_size
	
	return counts

func get_system_stats() -> Dictionary:
	"""Get system statistics"""
	return {
		"total_items": all_items.size(),
		"max_items": max_items_in_system,
		"item_flows": item_flows.size(),
		"processing_queue": processing_queue.size(),
		"items_by_type": get_item_count_by_type()
	}

func spawn_item_at_position(item_type: String, position: Vector2, value: int = 10) -> Item:
	"""Spawn an item at a specific position"""
	var item = Item.new()
	item.item_type = item_type
	item.value = value
	item.global_position = position
	
	# Add to scene tree
	get_tree().current_scene.add_child(item)
	
	# Register with system
	register_item(item)
	
	return item

func create_item_stack(item_type: String, stack_size: int, position: Vector2) -> Item:
	"""Create a stack of items"""
	var item = spawn_item_at_position(item_type, position)
	item.stack_size = stack_size
	return item

func get_hex_grid() -> HexGrid:
	"""Get reference to the hex grid"""
	return get_node_or_null("/root/Main/HexGrid") as HexGrid

func optimize_item_flows():
	"""Optimize item flows for better performance"""
	# Remove old flow data
	var current_time = Time.get_time_dict_from_system()["unix"]
	
	# This could be expanded to include more sophisticated optimization
	if item_flows.size() > 100:
		# Keep only the most recent flows
		var sorted_flows = item_flows.keys()
		sorted_flows.sort()
		
		# Keep only the last 50 flows
		for i in range(sorted_flows.size() - 50):
			item_flows.erase(sorted_flows[i])

func pause_system():
	"""Pause the item system"""
	if update_timer:
		update_timer.paused = true

func resume_system():
	"""Resume the item system"""
	if update_timer:
		update_timer.paused = false

func set_update_rate(new_rate: float):
	"""Change the system update rate"""
	update_interval = new_rate
	if update_timer:
		update_timer.wait_time = update_interval