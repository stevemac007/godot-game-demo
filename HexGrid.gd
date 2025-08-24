extends Node2D
class_name HexGrid

## Hexagonal grid system for tile placement
## Handles coordinate conversion, tile positioning, and grid management

signal hex_clicked(hex_coord: Vector2i)
signal hex_hovered(hex_coord: Vector2i)

@export var hex_size: float = 32.0
@export var grid_radius: int = 8
@export var show_grid_lines: bool = true
@export var grid_color: Color = Color.GRAY
@export var hover_color: Color = Color.YELLOW

# Hexagonal grid constants
const HEX_WIDTH_MULTIPLIER = sqrt(3.0)
const HEX_HEIGHT_MULTIPLIER = 1.5

# Grid storage
var tiles: Dictionary = {}  # Vector2i -> Tile
var hovered_hex: Vector2i = Vector2i.ZERO
var is_hovering: bool = false

func _ready():
	print("HexGrid initialized with radius: ", grid_radius)

func _draw():
	"""Draw the hexagonal grid"""
	if show_grid_lines:
		draw_grid_lines()
	
	if is_hovering:
		draw_hex_outline(hovered_hex, hover_color, 2.0)

func draw_grid_lines():
	"""Draw the hexagonal grid lines"""
	for q in range(-grid_radius, grid_radius + 1):
		var r1 = max(-grid_radius, -q - grid_radius)
		var r2 = min(grid_radius, -q + grid_radius)
		
		for r in range(r1, r2 + 1):
			var hex_coord = Vector2i(q, r)
			draw_hex_outline(hex_coord, grid_color, 1.0)

func draw_hex_outline(hex_coord: Vector2i, color: Color, width: float):
	"""Draw the outline of a hexagon at the given coordinate"""
	var center = hex_to_pixel(hex_coord)
	var points = get_hex_corners(center)
	
	for i in range(6):
		var start = points[i]
		var end = points[(i + 1) % 6]
		draw_line(start, end, color, width)

func get_hex_corners(center: Vector2) -> Array[Vector2]:
	"""Get the six corner points of a hexagon centered at the given position"""
	var corners: Array[Vector2] = []
	
	for i in range(6):
		var angle = PI / 3.0 * i
		var x = center.x + hex_size * cos(angle)
		var y = center.y + hex_size * sin(angle)
		corners.append(Vector2(x, y))
	
	return corners

func hex_to_pixel(hex_coord: Vector2i) -> Vector2:
	"""Convert hexagonal coordinates to pixel coordinates"""
	var x = hex_size * (HEX_WIDTH_MULTIPLIER * hex_coord.x + HEX_WIDTH_MULTIPLIER / 2.0 * hex_coord.y)
	var y = hex_size * (HEX_HEIGHT_MULTIPLIER * hex_coord.y)
	return Vector2(x, y)

func pixel_to_hex(pixel_pos: Vector2) -> Vector2i:
	"""Convert pixel coordinates to hexagonal coordinates"""
	var q = (HEX_WIDTH_MULTIPLIER / 3.0 * pixel_pos.x - 1.0 / 3.0 * pixel_pos.y) / hex_size
	var r = (2.0 / 3.0 * pixel_pos.y) / hex_size
	
	return hex_round(Vector2(q, r))

func hex_round(hex: Vector2) -> Vector2i:
	"""Round fractional hex coordinates to the nearest hex"""
	var q = round(hex.x)
	var r = round(hex.y)
	var s = round(-hex.x - hex.y)
	
	var q_diff = abs(q - hex.x)
	var r_diff = abs(r - hex.y)
	var s_diff = abs(s - (-hex.x - hex.y))
	
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	
	return Vector2i(int(q), int(r))

func is_valid_hex(hex_coord: Vector2i) -> bool:
	"""Check if the hex coordinate is within the grid bounds"""
	var distance = hex_distance(Vector2i.ZERO, hex_coord)
	return distance <= grid_radius

func hex_distance(hex_a: Vector2i, hex_b: Vector2i) -> int:
	"""Calculate the distance between two hex coordinates"""
	return (abs(hex_a.x - hex_b.x) + abs(hex_a.x + hex_a.y - hex_b.x - hex_b.y) + abs(hex_a.y - hex_b.y)) / 2

func get_hex_neighbors(hex_coord: Vector2i) -> Array[Vector2i]:
	"""Get the six neighboring hex coordinates"""
	var directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	var neighbors: Array[Vector2i] = []
	for direction in directions:
		var neighbor = hex_coord + direction
		if is_valid_hex(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func place_tile(hex_coord: Vector2i, tile: Tile) -> bool:
	"""Place a tile at the given hex coordinate"""
	if not is_valid_hex(hex_coord):
		print("Invalid hex coordinate: ", hex_coord)
		return false
	
	if has_tile(hex_coord):
		print("Tile already exists at: ", hex_coord)
		return false
	
	tiles[hex_coord] = tile
	tile.position = hex_to_pixel(hex_coord)
	tile.hex_coordinate = hex_coord
	add_child(tile)
	
	print("Tile placed at hex: ", hex_coord)
	return true

func remove_tile(hex_coord: Vector2i) -> Tile:
	"""Remove and return the tile at the given hex coordinate"""
	if not has_tile(hex_coord):
		return null
	
	var tile = tiles[hex_coord]
	tiles.erase(hex_coord)
	tile.queue_free()
	
	print("Tile removed from hex: ", hex_coord)
	return tile

func get_tile(hex_coord: Vector2i) -> Tile:
	"""Get the tile at the given hex coordinate"""
	return tiles.get(hex_coord, null)

func has_tile(hex_coord: Vector2i) -> bool:
	"""Check if there's a tile at the given hex coordinate"""
	return hex_coord in tiles

func clear_grid():
	"""Remove all tiles from the grid"""
	for tile in tiles.values():
		tile.queue_free()
	tiles.clear()
	print("Grid cleared")

func get_all_tiles() -> Array[Tile]:
	"""Get all tiles currently on the grid"""
	var tile_array: Array[Tile] = []
	for tile in tiles.values():
		tile_array.append(tile)
	return tile_array

func _input(event):
	"""Handle input events for the grid"""
	if event is InputEventMouseMotion:
		var local_pos = to_local(event.position)
		var hex_coord = pixel_to_hex(local_pos)
		
		if is_valid_hex(hex_coord):
			if hex_coord != hovered_hex or not is_hovering:
				hovered_hex = hex_coord
				is_hovering = true
				hex_hovered.emit(hex_coord)
				queue_redraw()
		else:
			if is_hovering:
				is_hovering = false
				queue_redraw()
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = to_local(event.position)
			var hex_coord = pixel_to_hex(local_pos)
			
			if is_valid_hex(hex_coord):
				hex_clicked.emit(hex_coord)
				print("Hex clicked: ", hex_coord)