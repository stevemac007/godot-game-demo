extends Tile
class_name ConveyorBelt

## Conveyor belt tile that transports items between other tiles
## Handles item movement, direction, and connections to adjacent tiles

@export var transport_speed: float = 1.0
@export var belt_direction: Vector2i = Vector2i(1, 0)
@export var max_items_on_belt: int = 3

var items_on_belt: Array[Item] = []
var transport_timer: Timer
var next_tile: Tile = null
var previous_tile: Tile = null

# Visual elements
var direction_arrow: Node2D
var belt_segments: Array[Node2D] = []

func _ready():
	tile_type = TileType.CONVEYOR_BELT
	tile_name = "Conveyor Belt"
	tile_description = "Transports items between tiles"
	max_input_capacity = max_items_on_belt
	max_output_capacity = max_items_on_belt
	
	super._ready()
	setup_transport_timer()
	setup_belt_visuals()
	update_connections()

func setup_transport_timer():
	"""Setup the transport timer"""
	transport_timer = Timer.new()
	add_child(transport_timer)
	transport_timer.wait_time = 1.0 / transport_speed
	transport_timer.timeout.connect(_on_transport_tick)
	transport_timer.autostart = true

func setup_belt_visuals():
	"""Setup visual elements for the conveyor belt"""
	# Create direction arrow
	direction_arrow = Node2D.new()
	add_child(direction_arrow)
	
	var arrow_line = Line2D.new()
	direction_arrow.add_child(arrow_line)
	arrow_line.add_point(Vector2.ZERO)
	arrow_line.add_point(Vector2(belt_direction.x * 20, belt_direction.y * 20))
	arrow_line.add_point(Vector2(belt_direction.x * 15, belt_direction.y * 15 + 5))
	arrow_line.add_point(Vector2(belt_direction.x * 20, belt_direction.y * 20))
	arrow_line.add_point(Vector2(belt_direction.x * 15, belt_direction.y * 15 - 5))
	arrow_line.default_color = Color.BLACK
	arrow_line.width = 2.0
	
	# Create belt segments for visual feedback
	for i in range(max_items_on_belt):
		var segment = Node2D.new()
		add_child(segment)
		belt_segments.append(segment)

func update_connections():
	"""Update connections to adjacent tiles"""
	if not hex_coordinate:
		return
	
	# Find the next tile in the belt direction
	var next_coord = hex_coordinate + belt_direction
	var grid = get_parent() as HexGrid
	if grid:
		next_tile = grid.get_tile(next_coord)
		
		# Find previous tile (opposite direction)
		var prev_coord = hex_coordinate - belt_direction
		previous_tile = grid.get_tile(prev_coord)

func _on_transport_tick():
	"""Handle transport timer tick"""
	if not is_active:
		return
	
	# Move items along the belt
	transport_items()
	
	# Try to accept new items from previous tile
	accept_items_from_previous()
	
	# Update visual positions
	update_item_positions()

func transport_items():
	"""Transport items to the next tile"""
	if items_on_belt.size() == 0:
		return
	
	var item_to_transport = items_on_belt[0]
	
	if next_tile and next_tile.can_accept_item(item_to_transport):
		# Move item to next tile
		items_on_belt.remove_at(0)
		next_tile.add_input_item(item_to_transport)
		
		# Move item visually
		var target_pos = next_tile.global_position
		item_to_transport.move_to(target_pos, 1.0 / transport_speed)
		
		print("Conveyor transported item to: ", next_tile.tile_name)
	elif not next_tile:
		# No next tile, item gets stuck or destroyed
		print("Conveyor belt has no output connection")

func accept_items_from_previous():
	"""Try to accept items from the previous tile"""
	if items_on_belt.size() >= max_items_on_belt:
		return
	
	if previous_tile and previous_tile.has_output_item():
		var item = previous_tile.get_output_item()
		if item:
			items_on_belt.append(item)
			item.global_position = global_position
			print("Conveyor accepted item from: ", previous_tile.tile_name)

func update_item_positions():
	"""Update visual positions of items on the belt"""
	for i in range(items_on_belt.size()):
		var item = items_on_belt[i]
		var progress = float(i) / float(max_items_on_belt)
		var offset = Vector2(belt_direction.x * progress * 30, belt_direction.y * progress * 30)
		
		var target_pos = global_position + offset
		if not item.is_moving:
			item.move_to(target_pos, 0.2)

func set_direction(new_direction: Vector2i):
	"""Change the belt direction"""
	belt_direction = new_direction
	tile_description = "Transports items in direction: " + str(belt_direction)
	
	# Update visual arrow
	if direction_arrow:
		direction_arrow.queue_free()
		setup_belt_visuals()
	
	# Update connections
	update_connections()
	print("Conveyor belt direction changed to: ", belt_direction)

func rotate_clockwise():
	"""Rotate the belt direction clockwise"""
	# Hexagonal rotation (6 directions)
	var hex_directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	var current_index = hex_directions.find(belt_direction)
	if current_index != -1:
		var new_index = (current_index + 1) % 6
		set_direction(hex_directions[new_index])

func rotate_counterclockwise():
	"""Rotate the belt direction counterclockwise"""
	var hex_directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	var current_index = hex_directions.find(belt_direction)
	if current_index != -1:
		var new_index = (current_index - 1 + 6) % 6
		set_direction(hex_directions[new_index])

func set_transport_speed(new_speed: float):
	"""Change the transport speed"""
	transport_speed = new_speed
	if transport_timer:
		transport_timer.wait_time = 1.0 / transport_speed

func can_accept_item(item: Item) -> bool:
	"""Override to check belt capacity"""
	return items_on_belt.size() < max_items_on_belt

func add_input_item(item: Item) -> bool:
	"""Override to add items to the belt"""
	if can_accept_item(item):
		items_on_belt.append(item)
		item.global_position = global_position
		return true
	return false

func has_output_item() -> bool:
	"""Override to check if belt has items to output"""
	return items_on_belt.size() > 0

func get_output_item() -> Item:
	"""Override to get items from the belt"""
	if items_on_belt.size() > 0:
		return items_on_belt.pop_front()
	return null

func clear_belt():
	"""Clear all items from the belt"""
	for item in items_on_belt:
		item.queue_free()
	items_on_belt.clear()

func process_tick():
	"""Override the base process tick"""
	super.process_tick()
	
	# Update connections in case tiles have changed
	update_connections()

func get_info() -> Dictionary:
	"""Override to add conveyor-specific information"""
	var info = super.get_info()
	info["direction"] = str(belt_direction)
	info["transport_speed"] = str(transport_speed) + " items/sec"
	info["items_on_belt"] = items_on_belt.size()
	info["max_capacity"] = max_items_on_belt
	info["next_tile"] = next_tile.tile_name if next_tile else "None"
	info["previous_tile"] = previous_tile.tile_name if previous_tile else "None"
	return info

func serialize() -> Dictionary:
	"""Override to add conveyor-specific data"""
	var data = super.serialize()
	data["belt_direction"] = [belt_direction.x, belt_direction.y]
	data["transport_speed"] = transport_speed
	data["max_items_on_belt"] = max_items_on_belt
	return data

func deserialize(data: Dictionary):
	"""Override to load conveyor-specific data"""
	super.deserialize(data)
	var dir_array = data.get("belt_direction", [1, 0])
	belt_direction = Vector2i(dir_array[0], dir_array[1])
	transport_speed = data.get("transport_speed", 1.0)
	max_items_on_belt = data.get("max_items_on_belt", 3)