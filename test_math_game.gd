extends "res://addons/gut/test.gd"

## Unit tests for the Math Game functionality
## Tests math game specific features, speed boosts, and game completion

var math_game_manager: MathGameManager
var central_receiver: CentralReceiver
var producer: Producer
var transformer: Transformer

func before_each():
	"""Setup before each test"""
	math_game_manager = MathGameManager.new()
	central_receiver = CentralReceiver.new()
	producer = Producer.new()
	transformer = Transformer.new()

func after_each():
	"""Cleanup after each test"""
	if math_game_manager:
		math_game_manager.queue_free()
	if central_receiver:
		central_receiver.queue_free()
	if producer:
		producer.queue_free()
	if transformer:
		transformer.queue_free()

func test_number_item_colors():
	"""Test that number items have distinct colors"""
	var item1 = Item.new()
	item1.item_type = "1"
	var color1 = item1.get_item_color()
	
	var item5 = Item.new()
	item5.item_type = "5"
	var color5 = item5.get_item_color()
	
	var item10 = Item.new()
	item10.item_type = "10"
	var color10 = item10.get_item_color()
	
	assert_ne(color1, color5, "Numbers 1 and 5 should have different colors")
	assert_ne(color5, color10, "Numbers 5 and 10 should have different colors")
	assert_ne(color1, color10, "Numbers 1 and 10 should have different colors")
	
	# Clean up
	item1.queue_free()
	item5.queue_free()
	item10.queue_free()

func test_producer_timing():
	"""Test that producers have 5-second intervals"""
	producer.configure_for_number(3)
	assert_eq(producer.production_interval, 5.0, "Producer should have 5-second interval")

func test_transformer_timing():
	"""Test that transformers have 6-second processing time"""
	transformer.configure_for_operation("addition")
	assert_eq(transformer.processing_time, 6.0, "Transformer should have 6-second processing time")

func test_addition_recipes():
	"""Test addition transformer recipes"""
	transformer.configure_for_operation("addition")
	transformer.load_recipes()
	
	var recipes = transformer.recipes.get("addition", {})
	
	# Test some key addition combinations
	assert_eq(recipes.get("1+1"), "2", "1+1 should equal 2")
	assert_eq(recipes.get("2+3"), "5", "2+3 should equal 5")
	assert_eq(recipes.get("5+5"), "10", "5+5 should equal 10")
	assert_eq(recipes.get("7+3"), "10", "7+3 should equal 10")

func test_subtraction_recipes():
	"""Test subtraction transformer recipes"""
	transformer.configure_for_operation("subtraction")
	transformer.load_recipes()
	
	var recipes = transformer.recipes.get("subtraction", {})
	
	# Test some key subtraction combinations
	assert_eq(recipes.get("5-2"), "3", "5-2 should equal 3")
	assert_eq(recipes.get("7-3"), "4", "7-3 should equal 4")
	assert_eq(recipes.get("10-1"), "9", "10-1 should equal 9")

func test_math_operation_processing():
	"""Test that math operations work correctly"""
	transformer.configure_for_operation("addition")
	transformer.load_recipes()
	
	# Create two items for addition
	var item1 = Item.new()
	item1.item_type = "3"
	item1.value = 3
	
	var item2 = Item.new()
	item2.item_type = "4"
	item2.value = 4
	
	# Set up the second item as metadata (simulating the processing setup)
	item1.set_meta("second_item", item2)
	
	# Perform the math operation
	var result = transformer.perform_math_operation(item1, transformer.recipes["addition"])
	
	assert_not_null(result, "Math operation should produce a result")
	assert_eq(result.item_type, "7", "3+4 should equal 7")
	assert_eq(result.value, 7, "Result value should be 7")

func test_central_receiver_math_requirements():
	"""Test central receiver math game requirements"""
	central_receiver.setup_level_requirements()
	central_receiver.load_current_level_requirements()
	
	# Check that it wants 10 of each number 1-10
	for i in range(1, 11):
		var number_str = str(i)
		assert_true(number_str in central_receiver.current_requirements, "Should require number " + number_str)
		assert_eq(central_receiver.current_requirements[number_str], 10, "Should require 10 of number " + number_str)

func test_set_completion_detection():
	"""Test detection of completed sets"""
	central_receiver.setup_level_requirements()
	central_receiver.load_current_level_requirements()
	
	# Simulate receiving 10 of number 7
	for i in range(10):
		var item = Item.new()
		item.item_type = "7"
		item.value = 7
		item.stack_size = 1
		central_receiver.process_received_item(item)
	
	# Check set completion
	assert_true(7 in central_receiver.completed_sets, "Set of 7 should be completed")
	assert_eq(central_receiver.available_speed_boosts, 1, "Should have 1 speed boost available")

func test_game_completion_condition():
	"""Test game completion when 10 of number 10 is collected"""
	central_receiver.setup_level_requirements()
	central_receiver.load_current_level_requirements()
	
	# Simulate receiving 10 of number 10
	for i in range(10):
		var item = Item.new()
		item.item_type = "10"
		item.value = 10
		item.stack_size = 1
		central_receiver.process_received_item(item)
	
	# Check game completion
	assert_true(central_receiver.is_game_completed, "Game should be completed")
	assert_true(10 in central_receiver.completed_sets, "Set of 10 should be completed")

func test_speed_boost_application():
	"""Test speed boost application to producers and transformers"""
	producer.configure_for_number(5)
	transformer.configure_for_operation("addition")
	
	var initial_producer_boost = producer.speed_boost
	var initial_transformer_boost = transformer.speed_boost
	
	# Apply speed boosts
	producer.apply_speed_boost(1.05)  # 5% boost
	transformer.apply_speed_boost(1.05)  # 5% boost
	
	assert_gt(producer.speed_boost, initial_producer_boost, "Producer speed boost should increase")
	assert_gt(transformer.speed_boost, initial_transformer_boost, "Transformer speed boost should increase")

func test_math_game_progress_tracking():
	"""Test math game progress tracking"""
	central_receiver.setup_level_requirements()
	central_receiver.load_current_level_requirements()
	
	# Add some items
	for i in range(5):
		var item = Item.new()
		item.item_type = "3"
		item.value = 3
		item.stack_size = 1
		central_receiver.process_received_item(item)
	
	var progress = central_receiver.get_math_game_progress()
	
	assert_eq(progress["3"]["current"], 5, "Should have 5 of number 3")
	assert_eq(progress["3"]["required"], 10, "Should require 10 of number 3")
	assert_false(progress["3"]["completed"], "Set of 3 should not be completed yet")

func test_all_numbers_achievable():
	"""Test that all numbers 1-10 can be achieved through operations"""
	# This test verifies that the recipe system allows creating all numbers
	var addition_transformer = Transformer.new()
	addition_transformer.configure_for_operation("addition")
	addition_transformer.load_recipes()
	
	var subtraction_transformer = Transformer.new()
	subtraction_transformer.configure_for_operation("subtraction")
	subtraction_transformer.load_recipes()
	
	var addition_recipes = addition_transformer.recipes["addition"]
	var subtraction_recipes = subtraction_transformer.recipes["subtraction"]
	
	# Check that each number 1-10 can be produced
	for target_number in range(1, 11):
		var target_str = str(target_number)
		var can_produce = false
		
		# Check if any addition recipe produces this number
		for recipe_result in addition_recipes.values():
			if recipe_result == target_str:
				can_produce = true
				break
		
		# Check if any subtraction recipe produces this number
		if not can_produce:
			for recipe_result in subtraction_recipes.values():
				if recipe_result == target_str:
					can_produce = true
					break
		
		# Numbers 1, 2, 3, 5, 7 are produced directly by producers
		if target_number in [1, 2, 3, 5, 7]:
			can_produce = true
		
		assert_true(can_produce, "Number " + target_str + " should be achievable")
	
	# Clean up
	addition_transformer.queue_free()
	subtraction_transformer.queue_free()

func test_speed_boost_usage():
	"""Test speed boost usage system"""
	central_receiver.setup_level_requirements()
	central_receiver.available_speed_boosts = 3
	
	# Use a speed boost
	var success = central_receiver.use_speed_boost()
	assert_true(success, "Should be able to use speed boost")
	assert_eq(central_receiver.available_speed_boosts, 2, "Should have 2 boosts remaining")
	
	# Use all remaining boosts
	central_receiver.use_speed_boost()
	central_receiver.use_speed_boost()
	
	# Try to use when none available
	var failed = central_receiver.use_speed_boost()
	assert_false(failed, "Should not be able to use speed boost when none available")
	assert_eq(central_receiver.available_speed_boosts, 0, "Should have 0 boosts remaining")