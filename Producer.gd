extends Tile
class_name Producer

## Producer tile that generates items at regular intervals
## Different producers create different types of items

@export var production_interval: float = 5.0  # Math game: 5 seconds per item
@export var item_type_to_produce: String = "1"  # Math game: default to number 1
@export var production_efficiency: float = 1.0
@export var requires_power: bool = false

var production_timer: Timer
var is_producing: bool = false
var power_level: float = 1.0
var speed_boost: float = 1.0  # Math game: external speed boost from completed sets

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
        # Math game: item value equals the number it represents
        var numeric_value = int(item_type_to_produce)
        if numeric_value > 0:
                return numeric_value
        
        # Legacy item values for backward compatibility
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
        update_production_rate()

func apply_speed_boost(boost_multiplier: float):
        """Apply a speed boost from completed sets"""
        speed_boost = boost_multiplier
        update_production_rate()
        print("Producer speed boost applied: ", boost_multiplier, "x")

func update_production_rate():
        """Update the production rate based on power and speed boost"""
        if production_timer:
                var effective_rate = production_interval / (power_level * speed_boost) if (power_level * speed_boost) > 0 else production_interval * 2
                production_timer.wait_time = effective_rate

func configure_for_number(number: int):
        """Configure this producer to generate a specific number"""
        if number >= 1 and number <= 10:
                item_type_to_produce = str(number)
                tile_name = "Number " + str(number) + " Producer"
                tile_description = "Produces the number " + str(number)
                print("Producer configured for number: ", number)

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
        info["speed_boost"] = str(speed_boost * 100) + "%"
        info["is_producing"] = is_producing
        return info

func serialize() -> Dictionary:
        """Override to add producer-specific data"""
        var data = super.serialize()
        data["item_type_to_produce"] = item_type_to_produce
        data["production_interval"] = production_interval
        data["production_efficiency"] = production_efficiency
        data["power_level"] = power_level
        data["speed_boost"] = speed_boost
        return data

func deserialize(data: Dictionary):
        """Override to load producer-specific data"""
        super.deserialize(data)
        item_type_to_produce = data.get("item_type_to_produce", "1")
        production_interval = data.get("production_interval", 5.0)
        production_efficiency = data.get("production_efficiency", 1.0)
        power_level = data.get("power_level", 1.0)
        speed_boost = data.get("speed_boost", 1.0)