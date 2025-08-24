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
        """Test producer item creation for math game"""
        producer.item_type_to_produce = "5"  # Math game: number 5
        var item = producer.create_item()
        
        assert_not_null(item, "Producer should create item")
        assert_eq(item.item_type, "5", "Item should have correct type")
        assert_eq(item.value, 5, "Math game: item value should equal number")

func test_math_producer_configuration():
        """Test producer configuration for math game numbers"""
        producer.configure_for_number(7)
        
        assert_eq(producer.item_type_to_produce, "7", "Producer should be configured for number 7")
        assert_eq(producer.tile_name, "Number 7 Producer", "Producer should have correct name")
        
        var item = producer.create_item()
        assert_eq(item.value, 7, "Item value should equal the number")

func test_transformer_processing():
        """Test transformer math processing"""
        transformer.transformation_type = "addition"
        
        # Create input items for addition
        var item1 = Item.new()
        item1.item_type = "2"
        item1.value = 2
        
        var item2 = Item.new()
        item2.item_type = "3"
        item2.value = 3
        
        # Add items to transformer input
        transformer.input_items.append(item1)
        transformer.input_items.append(item2)
        
        # Test if transformer can process
        assert_true(transformer.can_start_processing(), "Transformer should be able to process math operation")

func test_math_transformer_configuration():
        """Test transformer configuration for math operations"""
        transformer.configure_for_operation("subtraction")
        
        assert_eq(transformer.transformation_type, "subtraction", "Transformer should be configured for subtraction")
        assert_eq(transformer.tile_name, "Subtraction Transformer", "Transformer should have correct name")

func test_math_addition_recipe():
        """Test addition recipe functionality"""
        transformer.transformation_type = "addition"
        transformer.load_recipes()
        
        var recipes = transformer.recipes.get("addition", {})
        assert_true("2+3" in recipes, "Should have 2+3 recipe")
        assert_eq(recipes["2+3"], "5", "2+3 should equal 5")
func test_central_receiver_acceptance():
        """Test central receiver item acceptance for math game"""
        var item = Item.new()
        item.item_type = "5"  # Math game: number 5
        item.value = 5
        item.stack_size = 1
        
        # Test acceptance
        var can_accept = central_receiver.can_accept_item(item)
        assert_true(can_accept, "Central receiver should accept number items")
        
        # Test processing
        var initial_count = central_receiver.stored_items.get("5", 0)
        central_receiver.input_items.append(item)
        central_receiver.accept_next_item()
        
        var final_count = central_receiver.stored_items.get("5", 0)
        assert_eq(final_count, initial_count + 1, "Item count should increase")

func test_math_game_progress():
        """Test math game progress tracking"""
        # Simulate receiving 10 of number 3
        for i in range(10):
                var item = Item.new()
                item.item_type = "3"
                item.value = 3
                item.stack_size = 1
                central_receiver.process_received_item(item)
        
        # Check if set completion is detected
        assert_true(3 in central_receiver.completed_sets, "Set of 3 should be completed")
        assert_eq(central_receiver.available_speed_boosts, 1, "Should have 1 speed boost available")

func test_game_completion():
        """Test game completion when 10 of number 10 is collected"""
        # Simulate receiving 10 of number 10
        for i in range(10):
                var item = Item.new()
                item.item_type = "10"
                item.value = 10
                item.stack_size = 1
                central_receiver.process_received_item(item)
        
func test_conveyor_direction():
        """Test conveyor belt direction handling"""
        var initial_direction = conveyor.belt_direction
        
        # Test rotation
        conveyor.rotate_clockwise()
        assert_ne(conveyor.belt_direction, initial_direction, "Direction should change after rotation")
        
        # Test setting specific direction
        conveyor.set_direction(Vector2i(0, 1))
        assert_eq(conveyor.belt_direction, Vector2i(0, 1), "Direction should be set correctly")

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