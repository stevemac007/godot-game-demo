extends Node2D
class_name Item

## Represents an item that flows through the tile system
## Items are produced by producers, processed by transformers, and consumed by receivers

signal item_moved(from_pos: Vector2, to_pos: Vector2)
signal item_destroyed(item: Item)

@export var item_type: String = "basic_item"
@export var value: int = 10
@export var quality: float = 1.0
@export var stack_size: int = 1
@export var is_stackable: bool = true

var sprite: Sprite2D
var movement_tween: Tween
var current_position: Vector2
var target_position: Vector2
var movement_speed: float = 100.0
var is_moving: bool = false

# Item properties
var creation_time: float
var last_processed_time: float
var processing_count: int = 0

func _ready():
        creation_time = Time.get_time_dict_from_system()["unix"]
        setup_visuals()
        print("Item created: ", item_type, " (Value: ", value, ")")

func setup_visuals():
        """Setup the visual representation of the item"""
        sprite = Sprite2D.new()
        add_child(sprite)
        
        # Create a simple colored circle for the item
        var texture = ImageTexture.new()
        var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
        
        # Fill with item-specific color
        var color = get_item_color()
        image.fill(color)
        
        # Add a simple border
        for x in range(16):
                for y in range(16):
                        if x == 0 or x == 15 or y == 0 or y == 15:
                                image.set_pixel(x, y, Color.BLACK)
        
        texture.set_image(image)
        sprite.texture = texture
        sprite.scale = Vector2(0.8, 0.8)

func get_item_color() -> Color:
        """Get the color representing this item type"""
        match item_type:
                # Math game numbers - distinct colors for easy identification
                "1":
                        return Color.RED
                "2":
                        return Color.ORANGE
                "3":
                        return Color.YELLOW
                "4":
                        return Color.GREEN
                "5":
                        return Color.BLUE
                "6":
                        return Color.PURPLE
                "7":
                        return Color.PINK
                "8":
                        return Color.BROWN
                "9":
                        return Color.DARK_GREEN
                "10":
                        return Color.GOLD
                # Legacy item types for backward compatibility
                "basic_item":
                        return Color.WHITE
                "wood":
                        return Color(0.6, 0.3, 0.1)  # Brown
                "stone":
                        return Color.GRAY
                "iron":
                        return Color(0.7, 0.7, 0.8)  # Light gray
                "gold":
                        return Color.YELLOW
                "energy":
                        return Color.CYAN
                "processed_wood":
                        return Color(0.8, 0.4, 0.2)  # Lighter brown
                "processed_stone":
                        return Color.LIGHT_GRAY
                "advanced_item":
                        return Color.PURPLE
                "rare_item":
                        return Color.ORANGE
                _:
                        return Color.WHITE

func move_to(target_pos: Vector2, duration: float = 1.0):
        """Move the item to a target position"""
        if is_moving:
                return false
        
        current_position = global_position
        target_position = target_pos
        is_moving = true
        
        # Create movement tween
        movement_tween = create_tween()
        movement_tween.tween_property(self, "global_position", target_position, duration)
        movement_tween.tween_callback(_on_movement_complete)
        
        item_moved.emit(current_position, target_position)
        return true

func _on_movement_complete():
        """Called when movement is complete"""
        is_moving = false
        current_position = global_position

func stop_movement():
        """Stop the current movement"""
        if movement_tween:
                movement_tween.kill()
        is_moving = false

func process_item(processor_type: String) -> Item:
        """Process this item and potentially return a new item"""
        processing_count += 1
        last_processed_time = Time.get_time_dict_from_system()["unix"]
        
        match processor_type:
                "wood_processor":
                        if item_type == "wood":
                                return create_processed_item("processed_wood", value * 2)
                "stone_processor":
                        if item_type == "stone":
                                return create_processed_item("processed_stone", value * 2)
                "combiner":
                        # Could combine multiple items
                        return create_processed_item("advanced_item", value * 1.5)
                "refiner":
                        return create_processed_item(item_type + "_refined", value * 3)
                _:
                        # Generic processing
                        quality *= 1.1
                        value = int(value * 1.1)
        
        return self

func create_processed_item(new_type: String, new_value: int) -> Item:
        """Create a new processed item"""
        var processed_item = Item.new()
        processed_item.item_type = new_type
        processed_item.value = new_value
        processed_item.quality = quality * 1.2
        processed_item.processing_count = processing_count
        return processed_item

func can_stack_with(other_item: Item) -> bool:
        """Check if this item can stack with another item"""
        if not is_stackable or not other_item.is_stackable:
                return false
        
        return (item_type == other_item.item_type and 
                        abs(quality - other_item.quality) < 0.1 and
                        stack_size < get_max_stack_size())

func get_max_stack_size() -> int:
        """Get the maximum stack size for this item type"""
        match item_type:
                # Math game numbers - smaller stacks for better game balance
                "1", "2", "3", "4", "5", "6", "7", "8", "9", "10":
                        return 10
                # Legacy item types
                "basic_item", "wood", "stone":
                        return 10
                "iron", "gold":
                        return 5
                "energy":
                        return 20
                "advanced_item", "rare_item":
                        return 3
                _:
                        return 5

func stack_with(other_item: Item) -> bool:
        """Stack this item with another item"""
        if not can_stack_with(other_item):
                return false
        
        var total_stack = stack_size + other_item.stack_size
        var max_stack = get_max_stack_size()
        
        if total_stack <= max_stack:
                stack_size = total_stack
                other_item.destroy()
                return true
        else:
                stack_size = max_stack
                other_item.stack_size = total_stack - max_stack
                return false

func split_stack(amount: int) -> Item:
        """Split this stack and return a new item with the specified amount"""
        if amount >= stack_size or amount <= 0:
                return null
        
        var new_item = duplicate_item()
        new_item.stack_size = amount
        stack_size -= amount
        
        return new_item

func duplicate_item() -> Item:
        """Create a duplicate of this item"""
        var duplicate = Item.new()
        duplicate.item_type = item_type
        duplicate.value = value
        duplicate.quality = quality
        duplicate.stack_size = 1
        duplicate.is_stackable = is_stackable
        duplicate.processing_count = processing_count
        return duplicate

func get_total_value() -> int:
        """Get the total value of this item stack"""
        return value * stack_size

func destroy():
        """Destroy this item"""
        print("Item destroyed: ", item_type, " (Stack: ", stack_size, ")")
        item_destroyed.emit(self)
        queue_free()

func get_info() -> Dictionary:
        """Get information about this item for UI display"""
        return {
                "type": item_type,
                "value": value,
                "total_value": get_total_value(),
                "quality": "%.1f" % quality,
                "stack_size": stack_size,
                "max_stack": get_max_stack_size(),
                "processed": processing_count > 0,
                "processing_count": processing_count
        }

func serialize() -> Dictionary:
        """Serialize item data for saving"""
        return {
                "item_type": item_type,
                "value": value,
                "quality": quality,
                "stack_size": stack_size,
                "processing_count": processing_count,
                "position": [global_position.x, global_position.y]
        }

func deserialize(data: Dictionary):
        """Deserialize item data from save"""
        item_type = data.get("item_type", "basic_item")
        value = data.get("value", 10)
        quality = data.get("quality", 1.0)
        stack_size = data.get("stack_size", 1)
        processing_count = data.get("processing_count", 0)
        
        var pos = data.get("position", [0, 0])
        global_position = Vector2(pos[0], pos[1])