extends "res://addons/gut/test.gd"

## Unit tests for the HexGrid system
## Tests coordinate conversion, tile placement, and grid management

var hex_grid: HexGrid

func before_each():
	"""Setup before each test"""
	hex_grid = HexGrid.new()
	hex_grid.hex_size = 32.0
	hex_grid.grid_radius = 5

func after_each():
	"""Cleanup after each test"""
	if hex_grid:
		hex_grid.queue_free()

func test_hex_to_pixel_conversion():
	"""Test hexagonal to pixel coordinate conversion"""
	var hex_coord = Vector2i(0, 0)
	var pixel_pos = hex_grid.hex_to_pixel(hex_coord)
	
	# Center should be at origin
	assert_eq(pixel_pos, Vector2.ZERO, "Center hex should convert to origin")
	
	# Test a known conversion
	hex_coord = Vector2i(1, 0)
	pixel_pos = hex_grid.hex_to_pixel(hex_coord)
	var expected_x = hex_grid.hex_size * sqrt(3.0)
	assert_almost_eq(pixel_pos.x, expected_x, 0.1, "X coordinate conversion incorrect")

func test_pixel_to_hex_conversion():
	"""Test pixel to hexagonal coordinate conversion"""
	var pixel_pos = Vector2.ZERO
	var hex_coord = hex_grid.pixel_to_hex(pixel_pos)
	
	# Origin should convert to center hex
	assert_eq(hex_coord, Vector2i.ZERO, "Origin should convert to center hex")

func test_hex_distance_calculation():
	"""Test distance calculation between hex coordinates"""
	var hex_a = Vector2i(0, 0)
	var hex_b = Vector2i(1, 0)
	var distance = hex_grid.hex_distance(hex_a, hex_b)
	
	assert_eq(distance, 1, "Adjacent hexes should have distance 1")
	
	# Test diagonal distance
	hex_b = Vector2i(1, -1)
	distance = hex_grid.hex_distance(hex_a, hex_b)
	assert_eq(distance, 1, "Diagonal adjacent hexes should have distance 1")

func test_valid_hex_coordinates():
	"""Test hex coordinate validation"""
	# Center should be valid
	assert_true(hex_grid.is_valid_hex(Vector2i(0, 0)), "Center should be valid")
	
	# Edge of grid should be valid
	assert_true(hex_grid.is_valid_hex(Vector2i(5, 0)), "Edge coordinate should be valid")
	
	# Outside grid should be invalid
	assert_false(hex_grid.is_valid_hex(Vector2i(10, 0)), "Outside coordinate should be invalid")

func test_hex_neighbors():
	"""Test getting hex neighbors"""
	var center = Vector2i(0, 0)
	var neighbors = hex_grid.get_hex_neighbors(center)
	
	assert_eq(neighbors.size(), 6, "Center hex should have 6 neighbors")
	
	# Test edge hex (should have fewer neighbors due to grid bounds)
	var edge = Vector2i(5, 0)
	neighbors = hex_grid.get_hex_neighbors(edge)
	assert_true(neighbors.size() < 6, "Edge hex should have fewer than 6 neighbors")

func test_tile_placement():
	"""Test tile placement and removal"""
	var tile = Tile.new()
	var hex_coord = Vector2i(1, 1)
	
	# Test placement
	var success = hex_grid.place_tile(hex_coord, tile)
	assert_true(success, "Should be able to place tile")
	assert_true(hex_grid.has_tile(hex_coord), "Grid should have tile after placement")
	
	# Test duplicate placement
	var duplicate_tile = Tile.new()
	success = hex_grid.place_tile(hex_coord, duplicate_tile)
	assert_false(success, "Should not be able to place duplicate tile")
	
	# Test removal
	var removed_tile = hex_grid.remove_tile(hex_coord)
	assert_not_null(removed_tile, "Should return removed tile")
	assert_false(hex_grid.has_tile(hex_coord), "Grid should not have tile after removal")

func test_grid_clearing():
	"""Test clearing all tiles from grid"""
	# Place some tiles
	for i in range(3):
		var tile = Tile.new()
		hex_grid.place_tile(Vector2i(i, 0), tile)
	
	assert_eq(hex_grid.get_all_tiles().size(), 3, "Should have 3 tiles")
	
	# Clear grid
	hex_grid.clear_grid()
	assert_eq(hex_grid.get_all_tiles().size(), 0, "Should have no tiles after clearing")