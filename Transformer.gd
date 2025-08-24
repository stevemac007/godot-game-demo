extends Tile
class_name Transformer

## Transformer tile that processes items from one type to another
## Can have different transformation recipes and processing times

@export var processing_time: float = 2.0
@export var transformation_type: String = "basic_processor"
@export var efficiency: float = 1.0
@export var power_consumption: float = 1.0

var processing_timer: Timer
var current_processing_item: Item = null
var is_processing: bool = false
var recipes: Dictionary = {}

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
	"""Load transformation recipes"""
	recipes = {
		"basic_processor": {
			"wood": "processed_wood",
			"stone": "processed_stone",
			"iron": "processed_iron"
		},
		"combiner": {
			"processed_wood+processed_stone": "advanced_material",
			"iron+gold": "alloy",
			"energy+basic_item": "powered_item"
		},
		"refiner": {
			"processed_wood": "refined_wood",
			"processed_stone": "refined_stone",
			"advanced_material": "super_material"
		},
		"energy_converter": {
			"wood": "energy",
			"processed_wood": "energy",
			"any": "energy"
		}
	}
	
	print("Transformer loaded recipes for: ", transformation_type)

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
	
	# Check direct recipe
	if item.item_type in recipe_set:
		return true
	
	# Check for "any" recipe
	if "any" in recipe_set:
		return true
	
	# Check for combination recipes (simplified)
	for recipe_key in recipe_set.keys():
		if "+" in recipe_key:
			var required_items = recipe_key.split("+")
			if item.item_type in required_items:
				return true
	
	return false

func start_processing():
	"""Start processing the first item in the input queue"""
	if input_items.size() == 0:
		return
	
	current_processing_item = input_items.pop_front()
	is_processing = true
	
	# Adjust processing time based on efficiency
	processing_timer.wait_time = processing_time / efficiency
	processing_timer.start()
	
	# Visual processing effect
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
	
	# Check direct recipe
	if item.item_type in recipe_set:
		output_type = recipe_set[item.item_type]
	elif "any" in recipe_set:
		output_type = recipe_set["any"]
	else:
		# No valid recipe found
		print("No recipe found for: ", item.item_type)
		return item
	
	# Create the transformed item
	var transformed_item = Item.new()
	transformed_item.item_type = output_type
	transformed_item.value = calculate_output_value(item)
	transformed_item.quality = calculate_output_quality(item)
	transformed_item.stack_size = item.stack_size
	
	# Clean up the original item
	item.queue_free()
	
	return transformed_item

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

func set_processing_speed(new_speed: float):
	"""Change the processing speed"""
	processing_time = new_speed
	if processing_timer and not processing_timer.is_stopped():
		processing_timer.wait_time = processing_time / efficiency

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
	info["processing_speed"] = str(1.0 / processing_time) + " items/sec"
	info["efficiency"] = str(efficiency * 100) + "%"
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
	data["is_processing"] = is_processing
	return data

func deserialize(data: Dictionary):
	"""Override to load transformer-specific data"""
	super.deserialize(data)
	transformation_type = data.get("transformation_type", "basic_processor")
	processing_time = data.get("processing_time", 2.0)
	efficiency = data.get("efficiency", 1.0)
	is_processing = data.get("is_processing", false)