extends Node2D
class_name Tile

## Base class for all tiles in the hexagonal grid game
## Provides common functionality for producers, transformers, and conveyor belts

signal tile_clicked(tile: Tile)
signal tile_destroyed(tile: Tile)
signal item_produced(item: Item, tile: Tile)
signal item_consumed(item: Item, tile: Tile)

enum TileType {
	PRODUCER,
	TRANSFORMER,
	CONVEYOR_BELT,
	CENTRAL_RECEIVER
}

@export var tile_type: TileType
@export var tile_name: String = "Base Tile"
@export var tile_description: String = "A basic tile"
@export var max_health: int = 100
@export var placement_cost: int = 10
@export var can_be_destroyed: bool = true

var hex_coordinate: Vector2i
var current_health: int
var is_active: bool = true
var sprite: Sprite2D
var collision_area: Area2D

# Item handling
var input_items: Array[Item] = []
var output_items: Array[Item] = []
var max_input_capacity: int = 5
var max_output_capacity: int = 5

func _ready():
	current_health = max_health
	setup_visuals()
	setup_collision()
	print("Tile created: ", tile_name, " at ", hex_coordinate)

func setup_visuals():
	"""Setup the visual representation of the tile"""
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Set a placeholder texture (would be replaced with actual sprites)
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(get_tile_color())
	texture.set_image(image)
	sprite.texture = texture
	
	# Add a simple border
	var border = Line2D.new()
	add_child(border)
	border.add_point(Vector2(-32, -32))
	border.add_point(Vector2(32, -32))
	border.add_point(Vector2(32, 32))
	border.add_point(Vector2(-32, 32))
	border.add_point(Vector2(-32, -32))
	border.default_color = Color.BLACK
	border.width = 2.0

func get_tile_color() -> Color:
	"""Get the color representing this tile type"""
	match tile_type:
		TileType.PRODUCER:
			return Color.GREEN
		TileType.TRANSFORMER:
			return Color.BLUE
		TileType.CONVEYOR_BELT:
			return Color.YELLOW
		TileType.CENTRAL_RECEIVER:
			return Color.RED
		_:
			return Color.GRAY

func setup_collision():
	"""Setup collision detection for mouse interaction"""
	collision_area = Area2D.new()
	add_child(collision_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision_shape.shape = shape
	collision_area.add_child(collision_shape)
	
	# Connect signals
	collision_area.input_event.connect(_on_input_event)
	collision_area.mouse_entered.connect(_on_mouse_entered)
	collision_area.mouse_exited.connect(_on_mouse_exited)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Handle input events on the tile"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and can_be_destroyed:
			destroy_tile()

func _on_mouse_entered():
	"""Handle mouse entering the tile area"""
	modulate = Color(1.2, 1.2, 1.2)  # Brighten the tile

func _on_mouse_exited():
	"""Handle mouse exiting the tile area"""
	modulate = Color.WHITE  # Reset to normal color

func process_tick():
	"""Called every game tick to update tile logic"""
	if not is_active:
		return
	
	# Override in derived classes for specific behavior
	pass

func can_accept_item(item: Item) -> bool:
	"""Check if this tile can accept the given item"""
	return input_items.size() < max_input_capacity

func add_input_item(item: Item) -> bool:
	"""Add an item to the input queue"""
	if can_accept_item(item):
		input_items.append(item)
		item_consumed.emit(item, self)
		return true
	return false

func get_output_item() -> Item:
	"""Get an item from the output queue"""
	if output_items.size() > 0:
		return output_items.pop_front()
	return null

func has_output_item() -> bool:
	"""Check if there are items in the output queue"""
	return output_items.size() > 0

func produce_item(item: Item):
	"""Add an item to the output queue"""
	if output_items.size() < max_output_capacity:
		output_items.append(item)
		item_produced.emit(item, self)

func take_damage(amount: int):
	"""Apply damage to the tile"""
	current_health -= amount
	current_health = max(0, current_health)
	
	# Visual feedback for damage
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		destroy_tile()

func heal(amount: int):
	"""Heal the tile"""
	current_health += amount
	current_health = min(max_health, current_health)

func destroy_tile():
	"""Destroy this tile"""
	if not can_be_destroyed:
		return
	
	print("Tile destroyed: ", tile_name, " at ", hex_coordinate)
	tile_destroyed.emit(self)
	
	# Visual destruction effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(queue_free)

func set_active(active: bool):
	"""Set the active state of the tile"""
	is_active = active
	modulate = Color.WHITE if active else Color.GRAY

func get_info() -> Dictionary:
	"""Get information about this tile for UI display"""
	return {
		"name": tile_name,
		"description": tile_description,
		"type": TileType.keys()[tile_type],
		"health": str(current_health) + "/" + str(max_health),
		"active": is_active,
		"input_items": input_items.size(),
		"output_items": output_items.size(),
		"coordinate": str(hex_coordinate)
	}

func serialize() -> Dictionary:
	"""Serialize tile data for saving"""
	return {
		"tile_type": tile_type,
		"tile_name": tile_name,
		"hex_coordinate": [hex_coordinate.x, hex_coordinate.y],
		"current_health": current_health,
		"is_active": is_active
	}

func deserialize(data: Dictionary):
	"""Deserialize tile data from save"""
	tile_type = data.get("tile_type", tile_type)
	tile_name = data.get("tile_name", tile_name)
	hex_coordinate = Vector2i(data.get("hex_coordinate", [0, 0])[0], data.get("hex_coordinate", [0, 0])[1])
	current_health = data.get("current_health", max_health)
	is_active = data.get("is_active", true)