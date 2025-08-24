extends Tile
class_name CentralReceiver

## Central receiver that accepts all items and manages level progression
## Tracks required deliverables and unlocks new content

signal item_received(item_type: String, value: int)
signal requirement_completed(requirement: String)
signal level_unlocked(level: int)
signal set_completed(set_number: int)  # Math game: when 10 of a number is collected
signal game_completed()  # Math game: when 10 of number "10" is achieved
signal speed_boost_available()  # Math game: when player can choose speed boost

@export var acceptance_rate: float = 2.0
@export var storage_capacity: int = 100

var acceptance_timer: Timer
var stored_items: Dictionary = {}  # item_type -> count
var current_requirements: Dictionary = {}
var completed_requirements: Array[String] = []
var total_items_received: int = 0
var total_value_received: int = 0

# Math game specific
var completed_sets: Array[int] = []  # Numbers that have reached 10 items
var available_speed_boosts: int = 0  # Number of unused speed boosts
var is_game_completed: bool = false

# Level progression (kept for backward compatibility)
var current_level: int = 1
var level_requirements: Dictionary = {}

func _ready():
        tile_type = TileType.CENTRAL_RECEIVER
        tile_name = "Central Receiver"
        tile_description = "Accepts all items and manages progression"
        max_input_capacity = 20
        can_be_destroyed = false
        
        super._ready()
        setup_acceptance_timer()
        setup_level_requirements()
        load_current_level_requirements()

func setup_acceptance_timer():
        """Setup the timer for accepting items"""
        acceptance_timer = Timer.new()
        add_child(acceptance_timer)
        acceptance_timer.wait_time = 1.0 / acceptance_rate
        acceptance_timer.timeout.connect(_on_acceptance_tick)
        acceptance_timer.autostart = true

func setup_level_requirements():
        """Setup requirements for the math game"""
        # Math game: want 10 of each number 1-10
        level_requirements = {
                1: {
                        "1": 10, "2": 10, "3": 10, "4": 10, "5": 10,
                        "6": 10, "7": 10, "8": 10, "9": 10, "10": 10
                }
        }
        
        print("Math game requirements loaded: 10 of each number 1-10")

func load_current_level_requirements():
        """Load requirements for the current level"""
        current_requirements = level_requirements.get(current_level, {}).duplicate()
        print("Level ", current_level, " requirements loaded: ", current_requirements)

func _on_acceptance_tick():
        """Handle acceptance timer tick"""
        if not is_active:
                return
        
        if input_items.size() > 0:
                accept_next_item()

func accept_next_item():
        """Accept the next item from the input queue"""
        if input_items.size() == 0:
                return
        
        var item = input_items.pop_front()
        process_received_item(item)

func process_received_item(item: Item):
        """Process a received item"""
        var item_type = item.item_type
        var item_value = item.get_total_value()
        var stack_size = item.stack_size
        
        # Update storage
        if item_type in stored_items:
                stored_items[item_type] += stack_size
        else:
                stored_items[item_type] = stack_size
        
        # Update totals
        total_items_received += stack_size
        total_value_received += item_value
        
        # Check requirements
        check_requirements(item_type, stack_size)
        
        # Visual feedback
        show_acceptance_effect(item)
        
        # Emit signal
        item_received.emit(item_type, item_value)
        
        print("Central Receiver accepted: ", stack_size, "x ", item_type, " (Value: ", item_value, ")")
        
        # Clean up the item
        item.queue_free()

func check_requirements(item_type: String, amount: int):
        """Check if the received item fulfills any requirements"""
        # Math game: check if we've completed a set of 10
        var numeric_value = int(item_type)
        if numeric_value >= 1 and numeric_value <= 10:
                check_math_game_progress(numeric_value)
        
        # Legacy requirement checking for backward compatibility
        if item_type in current_requirements:
                current_requirements[item_type] -= amount
                
                if current_requirements[item_type] <= 0:
                        current_requirements.erase(item_type)
                        completed_requirements.append(item_type)
                        requirement_completed.emit(item_type)
                        
                        print("Requirement completed: ", item_type)
                        
                        if current_requirements.is_empty():
                                complete_level()

func check_math_game_progress(number: int):
        """Check progress for the math game"""
        if is_game_completed:
                return
        
        var count = stored_items.get(str(number), 0)
        
        # Check if we've reached 10 of this number
        if count >= 10 and number not in completed_sets:
                completed_sets.append(number)
                available_speed_boosts += 1
                
                set_completed.emit(number)
                speed_boost_available.emit()
                
                print("Set completed: 10 of number ", number, " collected!")
                print("Speed boost available! Total unused boosts: ", available_speed_boosts)
                
                # Check if this is number 10 (win condition)
                if number == 10:
                        is_game_completed = true
                        game_completed.emit()
                        print("GAME WON! 10 of number 10 collected!")

func use_speed_boost() -> bool:
        """Use one available speed boost"""
        if available_speed_boosts > 0:
                available_speed_boosts -= 1
                print("Speed boost used. Remaining: ", available_speed_boosts)
                return true
        return false

func get_math_game_progress() -> Dictionary:
        """Get current progress for the math game"""
        var progress = {}
        for i in range(1, 11):
                var number_str = str(i)
                var count = stored_items.get(number_str, 0)
                progress[number_str] = {
                        "current": count,
                        "required": 10,
                        "completed": i in completed_sets
                }
        return progress

func complete_level():
        """Handle level completion"""
        current_level += 1
        completed_requirements.clear()
        
        # Load next level requirements
        if current_level in level_requirements:
                load_current_level_requirements()
                level_unlocked.emit(current_level)
                print("Level ", current_level, " unlocked!")
        else:
                print("All levels completed! Game won!")
                # Handle game completion
                handle_game_completion()

func handle_game_completion():
        """Handle when all levels are completed"""
        tile_description = "All levels completed! Congratulations!"
        # Could trigger end game sequence, credits, etc.

func show_acceptance_effect(item: Item):
        """Show visual effect when accepting an item"""
        # Create a particle effect moving toward the center
        var effect = Node2D.new()
        add_child(effect)
        effect.global_position = item.global_position
        
        var tween = create_tween()
        tween.parallel().tween_property(effect, "global_position", global_position, 0.5)
        tween.parallel().tween_property(effect, "scale", Vector2.ZERO, 0.5)
        tween.tween_callback(effect.queue_free)
        
        # Flash the receiver
        var flash_tween = create_tween()
        flash_tween.tween_property(self, "modulate", Color.GREEN, 0.1)
        flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func get_storage_info() -> Dictionary:
        """Get information about stored items"""
        return stored_items.duplicate()

func get_requirements_info() -> Dictionary:
        """Get information about current requirements"""
        return current_requirements.duplicate()

func get_progress_info() -> Dictionary:
        """Get overall progress information"""
        return {
                "current_level": current_level,
                "total_items": total_items_received,
                "total_value": total_value_received,
                "requirements_remaining": current_requirements.size(),
                "completed_requirements": completed_requirements.size()
        }

func can_accept_item(item: Item) -> bool:
        """Override to always accept items (central receiver accepts everything)"""
        return input_items.size() < max_input_capacity

func set_acceptance_rate(new_rate: float):
        """Change the acceptance rate"""
        acceptance_rate = new_rate
        if acceptance_timer:
                acceptance_timer.wait_time = 1.0 / acceptance_rate

func clear_storage():
        """Clear all stored items (for testing/reset)"""
        stored_items.clear()
        total_items_received = 0
        total_value_received = 0
        print("Central Receiver storage cleared")

func force_level_completion():
        """Force complete the current level (for testing)"""
        current_requirements.clear()
        complete_level()

func get_info() -> Dictionary:
        """Override to add receiver-specific information"""
        var info = super.get_info()
        info["current_level"] = current_level
        info["acceptance_rate"] = str(acceptance_rate) + " items/sec"
        info["total_items"] = total_items_received
        info["total_value"] = total_value_received
        info["storage_count"] = stored_items.size()
        info["requirements"] = current_requirements
        info["completed"] = completed_requirements
        # Math game specific info
        info["completed_sets"] = completed_sets
        info["available_speed_boosts"] = available_speed_boosts
        info["game_completed"] = is_game_completed
        info["math_progress"] = get_math_game_progress()
        return info

func serialize() -> Dictionary:
        """Override to add receiver-specific data"""
        var data = super.serialize()
        data["current_level"] = current_level
        data["stored_items"] = stored_items
        data["current_requirements"] = current_requirements
        data["completed_requirements"] = completed_requirements
        data["total_items_received"] = total_items_received
        data["total_value_received"] = total_value_received
        # Math game specific data
        data["completed_sets"] = completed_sets
        data["available_speed_boosts"] = available_speed_boosts
        data["is_game_completed"] = is_game_completed
        return data

func deserialize(data: Dictionary):
        """Override to load receiver-specific data"""
        super.deserialize(data)
        current_level = data.get("current_level", 1)
        stored_items = data.get("stored_items", {})
        current_requirements = data.get("current_requirements", {})
        completed_requirements = data.get("completed_requirements", [])
        total_items_received = data.get("total_items_received", 0)
        total_value_received = data.get("total_value_received", 0)
        # Math game specific data
        completed_sets = data.get("completed_sets", [])
        available_speed_boosts = data.get("available_speed_boosts", 0)
        is_game_completed = data.get("is_game_completed", false)