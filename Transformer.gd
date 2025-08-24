extends Tile
class_name Transformer

## Transformer tile that processes items from one type to another
## Can have different transformation recipes and processing times

@export var processing_time: float = 6.0  # Math game: 6 seconds per operation
@export var transformation_type: String = "addition"  # Math game: addition or subtraction
@export var efficiency: float = 1.0
@export var power_consumption: float = 1.0

var processing_timer: Timer
var current_processing_item: Item = null
var is_processing: bool = false
var recipes: Dictionary = {}
var speed_boost: float = 1.0  # Math game: external speed boost from completed sets

func _ready():
        tile_type = TileType.TRANSFORMER
        tile_name = "Transformer"
        tile_description = "Processes items into new forms"
        max_input_capacity = 3
        max_output_capacity = 5
        
        super._ready()
        setup_processing_timer()
        load_recipes()

func setup_processing_timer():
        """Setup the processing timer"""
        processing_timer = Timer.new()
        add_child(processing_timer)
        processing_timer.wait_time = processing_time
        processing_timer.timeout.connect(_on_processing_complete)
        processing_timer.one_shot = true

func load_recipes():
        """Load transformation recipes for math operations"""
        recipes = {
                "addition": {
                        # All possible addition combinations that result in numbers 1-10
                        "1+1": "2", "1+2": "3", "1+3": "4", "1+4": "5", "1+5": "6", "1+6": "7", "1+7": "8", "1+8": "9", "1+9": "10",
                        "2+1": "3", "2+2": "4", "2+3": "5", "2+4": "6", "2+5": "7", "2+6": "8", "2+7": "9", "2+8": "10",
                        "3+1": "4", "3+2": "5", "3+3": "6", "3+4": "7", "3+5": "8", "3+6": "9", "3+7": "10",
                        "4+1": "5", "4+2": "6", "4+3": "7", "4+4": "8", "4+5": "9", "4+6": "10",
                        "5+1": "6", "5+2": "7", "5+3": "8", "5+4": "9", "5+5": "10",
                        "6+1": "7", "6+2": "8", "6+3": "9", "6+4": "10",
                        "7+1": "8", "7+2": "9", "7+3": "10",
                        "8+1": "9", "8+2": "10",
                        "9+1": "10"
                },
                "subtraction": {
                        # All possible subtraction combinations that result in numbers 1-10
                        "2-1": "1", "3-1": "2", "4-1": "3", "5-1": "4", "6-1": "5", "7-1": "6", "8-1": "7", "9-1": "8", "10-1": "9",
                        "3-2": "1", "4-2": "2", "5-2": "3", "6-2": "4", "7-2": "5", "8-2": "6", "9-2": "7", "10-2": "8",
                        "4-3": "1", "5-3": "2", "6-3": "3", "7-3": "4", "8-3": "5", "9-3": "6", "10-3": "7",
                        "5-4": "1", "6-4": "2", "7-4": "3", "8-4": "4", "9-4": "5", "10-4": "6",
                        "6-5": "1", "7-5": "2", "8-5": "3", "9-5": "4", "10-5": "5",
                        "7-6": "1", "8-6": "2", "9-6": "3", "10-6": "4",
                        "8-7": "1", "9-7": "2", "10-7": "3",
                        "9-8": "1", "10-8": "2",
                        "10-9": "1"
                }
        }
        
        print("Math Transformer loaded recipes for: ", transformation_type)

func process_tick():
        """Override the base process tick"""
        super.process_tick()
        
        if not is_processing and input_items.size() > 0 and can_start_processing():
                start_processing()

func can_start_processing() -> bool:
        """Check if we can start processing an item"""
        if not is_active:
                return false
        
        if output_items.size() >= max_output_capacity:
                return false
        
        if input_items.size() == 0:
                return false
        
        # Check if we have a valid recipe for the input item
        var input_item = input_items[0]
        return has_recipe_for_item(input_item)

func has_recipe_for_item(item: Item) -> bool:
        """Check if we have a recipe for the given item"""
        var recipe_set = recipes.get(transformation_type, {})
        
        # For math operations, we need to check if we can combine this item with any other item in queue
        if transformation_type == "addition" or transformation_type == "subtraction":
                return check_math_recipe_availability(item, recipe_set)
        
        # Legacy recipe checking for backward compatibility
        if item.item_type in recipe_set:
                return true
        if "any" in recipe_set:
                return true
        
        for recipe_key in recipe_set.keys():
                if "+" in recipe_key:
                        var required_items = recipe_key.split("+")
                        if item.item_type in required_items:
                                return true
        
        return false

func check_math_recipe_availability(item: Item, recipe_set: Dictionary) -> bool:
        """Check if we can perform a math operation with the given item"""
        var item_type = item.item_type
        
        # Check if we have at least 2 items to perform operation
        if input_items.size() < 2:
                return false
        
        # For addition/subtraction, check if any combination with other items works
        for other_item in input_items:
                if other_item == item:
                        continue
                
                var combo1 = item_type + "+" + other_item.item_type if transformation_type == "addition" else item_type + "-" + other_item.item_type
                var combo2 = other_item.item_type + "+" + item_type if transformation_type == "addition" else other_item.item_type + "-" + item_type
                
                if combo1 in recipe_set or combo2 in recipe_set:
                        return true
        
        return false

func start_processing():
        """Start processing items for math operations"""
        if input_items.size() < 2 and (transformation_type == "addition" or transformation_type == "subtraction"):
                return
        
        if transformation_type == "addition" or transformation_type == "subtraction":
                start_math_processing()
        else:
                start_legacy_processing()

func start_math_processing():
        """Start processing for math operations (requires 2 items)"""
        if input_items.size() < 2:
                return
        
        # Take the first two items for the operation
        var item1 = input_items.pop_front()
        var item2 = input_items.pop_front()
        
        # Store both items for processing
        current_processing_item = item1
        current_processing_item.set_meta("second_item", item2)
        
        is_processing = true
        
        # Adjust processing time based on efficiency and speed boost
        processing_timer.wait_time = processing_time / (efficiency * speed_boost)
        processing_timer.start()
        
        show_processing_effect()
        
        print("Math Transformer started processing: ", item1.item_type, " and ", item2.item_type)

func start_legacy_processing():
        """Start processing for legacy transformations (single item)"""
        if input_items.size() == 0:
                return
        
        current_processing_item = input_items.pop_front()
        is_processing = true
        
        processing_timer.wait_time = processing_time / (efficiency * speed_boost)
        processing_timer.start()
        
        show_processing_effect()
        
        print("Transformer started processing: ", current_processing_item.item_type)

func _on_processing_complete():
        """Handle processing completion"""
        if current_processing_item == null:
                is_processing = false
                return
        
        var processed_item = transform_item(current_processing_item)
        if processed_item:
                produce_item(processed_item)
                print("Transformer completed processing: ", processed_item.item_type)
        
        current_processing_item = null
        is_processing = false
        
        # Show completion effect
        show_completion_effect()

func transform_item(item: Item) -> Item:
        """Transform an item according to the current recipe"""
        var recipe_set = recipes.get(transformation_type, {})
        var output_type = ""
        
        if transformation_type == "addition" or transformation_type == "subtraction":
                return perform_math_operation(item, recipe_set)
        
        # Legacy transformation logic
        if item.item_type in recipe_set:
                output_type = recipe_set[item.item_type]
        elif "any" in recipe_set:
                output_type = recipe_set["any"]
        else:
                print("No recipe found for: ", item.item_type)
                return item
        
        var transformed_item = Item.new()
        transformed_item.item_type = output_type
        transformed_item.value = calculate_output_value(item)
        transformed_item.quality = calculate_output_quality(item)
        transformed_item.stack_size = item.stack_size
        
        item.queue_free()
        return transformed_item

func perform_math_operation(item1: Item, recipe_set: Dictionary) -> Item:
        """Perform math operation on two items"""
        var item2 = item1.get_meta("second_item") as Item
        if not item2:
                print("Error: Second item not found for math operation")
                return item1
        
        var combo1 = item1.item_type + ("+" if transformation_type == "addition" else "-") + item2.item_type
        var combo2 = item2.item_type + ("+" if transformation_type == "addition" else "-") + item1.item_type
        
        var result_type = ""
        if combo1 in recipe_set:
                result_type = recipe_set[combo1]
        elif combo2 in recipe_set:
                result_type = recipe_set[combo2]
        else:
                print("No math recipe found for: ", combo1, " or ", combo2)
                # Return the first item and put the second back in queue
                input_items.push_front(item2)
                return item1
        
        # Create the result item
        var result_item = Item.new()
        result_item.item_type = result_type
        result_item.value = int(result_type)  # Value equals the number
        result_item.quality = (item1.quality + item2.quality) / 2.0  # Average quality
        result_item.stack_size = 1
        
        print("Math operation completed: ", combo1, " = ", result_type)
        
        # Clean up input items
        item1.queue_free()
        item2.queue_free()
        
        return result_item

func calculate_output_value(input_item: Item) -> int:
        """Calculate the value of the output item"""
        var base_multiplier = 1.5
        
        match transformation_type:
                "basic_processor":
                        base_multiplier = 2.0
                "combiner":
                        base_multiplier = 2.5
                "refiner":
                        base_multiplier = 3.0
                "energy_converter":
                        base_multiplier = 1.2
        
        return int(input_item.value * base_multiplier * efficiency)

func calculate_output_quality(input_item: Item) -> float:
        """Calculate the quality of the output item"""
        var quality_bonus = 0.2 * efficiency
        return clamp(input_item.quality + quality_bonus, 0.1, 3.0)

func show_processing_effect():
        """Show visual effect during processing"""
        var tween = create_tween()
        tween.set_loops()
        tween.tween_property(self, "modulate", Color.CYAN, 0.5)
        tween.tween_property(self, "modulate", Color.WHITE, 0.5)
        
        # Stop the effect when processing is complete
        processing_timer.timeout.connect(func(): tween.kill(), CONNECT_ONE_SHOT)

func show_completion_effect():
        """Show visual effect when processing is complete"""
        var flash_tween = create_tween()
        flash_tween.tween_property(self, "modulate", Color.GREEN, 0.2)
        flash_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func set_transformation_type(new_type: String):
        """Change the transformation type"""
        transformation_type = new_type
        tile_description = "Processes items using " + new_type
        print("Transformer type changed to: ", new_type)

func upgrade_efficiency(amount: float):
        """Upgrade the processing efficiency"""
        efficiency += amount
        efficiency = clamp(efficiency, 0.1, 3.0)
        print("Transformer efficiency upgraded to: ", efficiency)

func apply_speed_boost(boost_multiplier: float):
        """Apply a speed boost from completed sets"""
        speed_boost = boost_multiplier
        print("Transformer speed boost applied: ", boost_multiplier, "x")

func configure_for_operation(operation: String):
        """Configure this transformer for a specific math operation"""
        if operation == "addition" or operation == "subtraction":
                transformation_type = operation
                tile_name = operation.capitalize() + " Transformer"
                tile_description = "Performs " + operation + " operations on numbers"
                print("Transformer configured for: ", operation)

func get_recipe_info() -> Array[String]:
        """Get information about available recipes"""
        var recipe_set = recipes.get(transformation_type, {})
        var recipe_info: Array[String] = []
        
        for input_type in recipe_set.keys():
                var output_type = recipe_set[input_type]
                recipe_info.append(input_type + " -> " + output_type)
        
        return recipe_info

func get_info() -> Dictionary:
        """Override to add transformer-specific information"""
        var info = super.get_info()
        info["transformation_type"] = transformation_type
        info["processing_speed"] = str(1.0 / processing_time) + " operations/sec"
        info["efficiency"] = str(efficiency * 100) + "%"
        info["speed_boost"] = str(speed_boost * 100) + "%"
        info["is_processing"] = is_processing
        info["current_item"] = current_processing_item.item_type if current_processing_item else "None"
        info["recipes"] = get_recipe_info()
        return info

func serialize() -> Dictionary:
        """Override to add transformer-specific data"""
        var data = super.serialize()
        data["transformation_type"] = transformation_type
        data["processing_time"] = processing_time
        data["efficiency"] = efficiency
        data["speed_boost"] = speed_boost
        data["is_processing"] = is_processing
        return data

func deserialize(data: Dictionary):
        """Override to load transformer-specific data"""
        super.deserialize(data)
        transformation_type = data.get("transformation_type", "addition")
        processing_time = data.get("processing_time", 6.0)
        efficiency = data.get("efficiency", 1.0)
        speed_boost = data.get("speed_boost", 1.0)
        is_processing = data.get("is_processing", false)