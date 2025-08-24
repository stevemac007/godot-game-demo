extends "res://addons/gut/test.gd"

## Unit tests for the Tile system
## Tests tile creation, item handling, and tile interactions

var producer: Producer
var transformer: Transformer
var conveyor: ConveyorBelt
var central_receiver: CentralReceiver

func before_each():
	"""Setup before each test"""
	producer = Producer.new()
	transformer = Transformer.new()
	conveyor = ConveyorBelt.new()
	central_receiver = CentralReceiver.new()

func after_each():
	"""Cleanup after each test"""
	if producer:
		producer.queue_free()
	if transformer:
		transformer.queue_free()
	if conveyor:
		conveyor.queue_free()
	if central_receiver:
		central_receiver.queue_free()

func test_producer_creation():
	"""Test producer tile creation and setup"""
	assert_not_null(producer, "Producer should be created")
	assert_eq(producer.tile_type, Tile.TileType.PRODUCER, "Producer should have correct type")
	assert_true(producer.max_output_capacity > 0, "Producer should have output capacity")

func test_producer_item_creation():
	"""Test producer item creation"""
	producer.item_type_to_produce = "wood"
	var item = producer.create_item()
	
	assert_not_null(item, "Producer should create item")
	assert_eq(item.item_type, "wood", "Item should have correct type")
	assert_true(item.value > 0, "Item should have positive value")

func test_transformer_processing():
	"""Test transformer item processing"""
	transformer.transformation_type = "basic_processor"
	
	# Create input item
	var input_item = Item.new()
	input_item.item_type = "wood"
	input_item.value = 10
	
	# Test transformation
	var output_item = transformer.transform_item(input_item)
	assert_not_null(output_item, "Transformer should produce output item")
	assert_eq(output_item.item_type, "processed_wood", "Output should be processed wood")
	assert_true(output_item.value > input_item.value, "Output should have higher value")

func test_conveyor_direction():
	"""Test conveyor belt direction handling"""
	var initial_direction = conveyor.belt_direction
	
	# Test rotation
	conveyor.rotate_clockwise()
	assert_ne(conveyor.belt_direction, initial_direction, "Direction should change after rotation")
	
	# Test setting specific direction
	conveyor.set_direction(Vector2i(0, 1))
	assert_eq(conveyor.belt_direction, Vector2i(0, 1), "Direction should be set correctly")

func test_central_receiver_acceptance():
	"""Test central receiver item acceptance"""
	var item = Item.new()
	item.item_type = "basic_item"
	item.value = 10
	item.stack_size = 1
	
	# Test acceptance
	var can_accept = central_receiver.can_accept_item(item)
	assert_true(can_accept, "Central receiver should accept items")
	
	# Test processing
	central_receiver.process_received_item(item)
	var storage = central_receiver.get_storage_info()
	assert_true("basic_item" in storage, "Item should be stored")
	assert_eq(storage["basic_item"], 1, "Should have correct item count")

func test_tile_health_system():
	"""Test tile health and damage system"""
	var tile = Tile.new()
	var initial_health = tile.current_health
	
	# Test damage
	tile.take_damage(10)
	assert_lt(tile.current_health, initial_health, "Health should decrease after damage")
	
	# Test healing
	tile.heal(5)
	assert_gt(tile.current_health, initial_health - 10, "Health should increase after healing")

func test_item_stacking():
	"""Test item stacking functionality"""
	var item1 = Item.new()
	item1.item_type = "wood"
	item1.stack_size = 3
	
	var item2 = Item.new()
	item2.item_type = "wood"
	item2.stack_size = 2
	
	# Test stacking compatibility
	assert_true(item1.can_stack_with(item2), "Same item types should be stackable")
	
	# Test actual stacking
	var stacked = item1.stack_with(item2)
	assert_true(stacked, "Stacking should succeed")
	assert_eq(item1.stack_size, 5, "Stack size should be combined")

func test_tile_serialization():
	"""Test tile serialization and deserialization"""
	producer.item_type_to_produce = "iron"
	producer.production_efficiency = 1.5
	
	# Serialize
	var data = producer.serialize()
	assert_true("item_type_to_produce" in data, "Serialized data should contain producer data")
	
	# Create new producer and deserialize
	var new_producer = Producer.new()
	new_producer.deserialize(data)
	
	assert_eq(new_producer.item_type_to_produce, "iron", "Deserialized data should match")
	assert_eq(new_producer.production_efficiency, 1.5, "Efficiency should be preserved")