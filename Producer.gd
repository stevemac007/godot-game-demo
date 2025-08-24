extends Tile
class_name Producer

## Producer tile that generates items at regular intervals
## Different producers create different types of items

@export var production_interval: float = 3.0
@export var item_type_to_produce: String = "basic_item"
@export var production_efficiency: float = 1.0
@export var requires_power: bool = false

var production_timer: Timer
var is_producing: bool = false
var power_level: float = 1.0

func _ready():
	tile_type = TileType.PRODUCER
	tile_name = "Producer"
	tile_description = "Produces items automatically"
	max_output_capacity = 10
	
	super._ready()
	setup_production_timer()

func setup_production_timer():
	"""Setup the production timer"""
	production_timer = Timer.new()
	add_child(production_timer)
	production_timer.wait_time = production_interval
	production_timer.timeout.connect(_on_production_timer_timeout)
	production_timer.autostart = true
	
	print("Producer setup complete. Producing: ", item_type_to_produce)

func _on_production_timer_timeout():
	"""Handle production timer timeout"""
	if can_produce():
		produce_new_item()

func can_produce() -> bool:
	"""Check if the producer can currently produce items"""
	if not is_active:
		return false
	
	if output_items.size() >= max_output_capacity:
		return false
	
	if requires_power and power_level < 0.1:
		return false
	
	return true

func produce_new_item():
	"""Create and produce a new item"""
	var new_item = create_item()
	if new_item:
		produce_item(new_item)
		is_producing = true
		
		# Visual production effect
		show_production_effect()
		
		print("Producer created item: ", item_type_to_produce)

func create_item() -> Item:
	"""Create a new item of the specified type"""
	var item = Item.new()
	item.item_type = item_type_to_produce
	item.value = get_item_value()
	item.quality = calculate_item_quality()
	return item

func get_item_value() -> int:
	"""Calculate the value of produced items"""
	var base_value = 10
	match item_type_to_produce:
		"basic_item":
			base_value = 10
		"advanced_item":
			base_value = 25
		"rare_item":
			base_value = 50
		_:
			base_value = 10
	
	return int(base_value * production_efficiency * power_level)

func calculate_item_quality() -> float:
	"""Calculate the quality of produced items based on various factors"""
	var base_quality = 1.0
	base_quality *= production_efficiency
	base_quality *= power_level
	
	# Add some randomness
	base_quality *= randf_range(0.8, 1.2)
	
	return clamp(base_quality, 0.1, 2.0)

func show_production_effect():
	"""Show visual effect when producing an item"""
	# Create a simple particle effect
	var effect = Node2D.new()
	add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2.0, 2.0), 0.2)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(effect.queue_free)
	
	# Flash the producer
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE * 1.5, 0.1)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func set_production_rate(new_rate: float):
	"""Change the production rate"""
	production_interval = new_rate
	if production_timer:
		production_timer.wait_time = production_interval

func set_item_type(new_type: String):
	"""Change the type of item this producer creates"""
	item_type_to_produce = new_type
	tile_description = "Produces " + new_type
	print("Producer now producing: ", new_type)

func upgrade_efficiency(amount: float):
	"""Upgrade the production efficiency"""
	production_efficiency += amount
	production_efficiency = clamp(production_efficiency, 0.1, 3.0)
	print("Producer efficiency upgraded to: ", production_efficiency)

func set_power_level(level: float):
	"""Set the power level for this producer"""
	power_level = clamp(level, 0.0, 2.0)
	
	# Adjust production rate based on power
	if production_timer:
		production_timer.wait_time = production_interval / power_level if power_level > 0 else production_interval * 2

func process_tick():
	"""Override the base process tick"""
	super.process_tick()
	
	# Update production status
	is_producing = production_timer.time_left < production_interval * 0.1

func get_info() -> Dictionary:
	"""Override to add producer-specific information"""
	var info = super.get_info()
	info["item_type"] = item_type_to_produce
	info["production_rate"] = str(1.0 / production_interval) + " items/sec"
	info["efficiency"] = str(production_efficiency * 100) + "%"
	info["power_level"] = str(power_level * 100) + "%"
	info["is_producing"] = is_producing
	return info

func serialize() -> Dictionary:
	"""Override to add producer-specific data"""
	var data = super.serialize()
	data["item_type_to_produce"] = item_type_to_produce
	data["production_interval"] = production_interval
	data["production_efficiency"] = production_efficiency
	data["power_level"] = power_level
	return data

func deserialize(data: Dictionary):
	"""Override to load producer-specific data"""
	super.deserialize(data)
	item_type_to_produce = data.get("item_type_to_produce", "basic_item")
	production_interval = data.get("production_interval", 3.0)
	production_efficiency = data.get("production_efficiency", 1.0)
	power_level = data.get("power_level", 1.0)