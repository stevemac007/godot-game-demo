extends Node
class_name UIManager

## Manages the user interface and player interactions
## Handles UI updates, button clicks, and information display

signal tile_button_clicked(tile_type: String)

# UI References
var score_label: Label
var level_label: Label
var items_label: Label
var requirements_label: Label
var producer_button: Button
var transformer_button: Button
var conveyor_button: Button

# Game system references
var game_manager: GameManager
var tile_manager: TileManager
var central_receiver: CentralReceiver

func _ready():
	print("UIManager initialized")
	setup_ui_references()
	connect_signals()
	update_ui()

func setup_ui_references():
	"""Setup references to UI elements"""
	score_label = get_node_or_null("../UI/HUD/TopPanel/ScoreLabel")
	level_label = get_node_or_null("../UI/HUD/TopPanel/LevelLabel")
	items_label = get_node_or_null("../UI/HUD/TopPanel/ItemsLabel")
	requirements_label = get_node_or_null("../UI/HUD/SidePanel/VBoxContainer/RequirementsLabel")
	
	producer_button = get_node_or_null("../UI/HUD/SidePanel/VBoxContainer/ProducerButton")
	transformer_button = get_node_or_null("../UI/HUD/SidePanel/VBoxContainer/TransformerButton")
	conveyor_button = get_node_or_null("../UI/HUD/SidePanel/VBoxContainer/ConveyorButton")

func connect_signals():
	"""Connect UI signals to handlers"""
	# Connect button signals
	if producer_button:
		producer_button.pressed.connect(func(): _on_tile_button_pressed("Producer"))
	if transformer_button:
		transformer_button.pressed.connect(func(): _on_tile_button_pressed("Transformer"))
	if conveyor_button:
		conveyor_button.pressed.connect(func(): _on_tile_button_pressed("ConveyorBelt"))
	
	# Connect to game systems
	game_manager = get_node_or_null("../GameManager") as GameManager
	tile_manager = get_node_or_null("../TileManager") as TileManager
	central_receiver = get_node_or_null("../HexGrid/CentralReceiver") as CentralReceiver
	
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.level_completed.connect(_on_level_completed)
	
	if tile_manager:
		tile_manager.inventory_changed.connect(_on_inventory_changed)
		tile_manager.tile_unlocked.connect(_on_tile_unlocked)
	
	if central_receiver:
		central_receiver.requirement_completed.connect(_on_requirement_completed)

func _on_tile_button_pressed(tile_type: String):
	"""Handle tile button presses"""
	if tile_manager:
		tile_manager.select_tile_type(tile_type)
		update_button_states()
	
	tile_button_clicked.emit(tile_type)
	print("UI: Tile button pressed: ", tile_type)

func _on_score_changed(new_score: int):
	"""Handle score changes"""
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_level_completed(level: int):
	"""Handle level completion"""
	if level_label:
		level_label.text = "Level: " + str(level + 1)
	
	update_requirements_display()

func _on_inventory_changed():
	"""Handle inventory changes"""
	update_tile_buttons()

func _on_tile_unlocked(tile_type: String):
	"""Handle tile unlocking"""
	print("UI: Tile unlocked: ", tile_type)
	update_tile_buttons()

func _on_requirement_completed(requirement: String):
	"""Handle requirement completion"""
	print("UI: Requirement completed: ", requirement)
	update_requirements_display()

func update_ui():
	"""Update all UI elements"""
	update_score_display()
	update_level_display()
	update_items_display()
	update_tile_buttons()
	update_requirements_display()

func update_score_display():
	"""Update the score display"""
	if score_label and game_manager:
		score_label.text = "Score: " + str(game_manager.current_score)

func update_level_display():
	"""Update the level display"""
	if level_label and game_manager:
		level_label.text = "Level: " + str(game_manager.current_level)

func update_items_display():
	"""Update the items delivered display"""
	if items_label and game_manager:
		items_label.text = "Items Delivered: " + str(game_manager.items_delivered)

func update_tile_buttons():
	"""Update the tile selection buttons"""
	if not tile_manager:
		return
	
	var available_tiles = tile_manager.get_available_tiles()
	
	# Update Producer button
	if producer_button:
		var count = available_tiles.get("Producer", 0)
		producer_button.text = "Producer (" + str(count) + ")"
		producer_button.disabled = count <= 0
	
	# Update Transformer button
	if transformer_button:
		var count = available_tiles.get("Transformer", 0)
		transformer_button.text = "Transformer (" + str(count) + ")"
		transformer_button.disabled = count <= 0
	
	# Update Conveyor button
	if conveyor_button:
		var count = available_tiles.get("ConveyorBelt", 0)
		conveyor_button.text = "Conveyor Belt (" + str(count) + ")"
		conveyor_button.disabled = count <= 0

func update_button_states():
	"""Update button visual states based on selection"""
	if not tile_manager:
		return
	
	var selected_type = tile_manager.get_selected_tile_type()
	
	# Reset all button states
	if producer_button:
		producer_button.button_pressed = (selected_type == "Producer")
	if transformer_button:
		transformer_button.button_pressed = (selected_type == "Transformer")
	if conveyor_button:
		conveyor_button.button_pressed = (selected_type == "ConveyorBelt")

func update_requirements_display():
	"""Update the requirements display"""
	if not requirements_label or not central_receiver:
		return
	
	var requirements = central_receiver.get_requirements_info()
	var requirements_text = ""
	
	if requirements.is_empty():
		requirements_text = "Level Complete!"
	else:
		for item_type in requirements.keys():
			var amount = requirements[item_type]
			requirements_text += item_type + ": " + str(amount) + "\n"
	
	requirements_label.text = requirements_text

func show_notification(message: String, duration: float = 3.0):
	"""Show a temporary notification"""
	# Create a temporary notification label
	var notification = Label.new()
	notification.text = message
	notification.add_theme_color_override("font_color", Color.YELLOW)
	
	# Add to UI
	var hud = get_node_or_null("../UI/HUD")
	if hud:
		hud.add_child(notification)
		
		# Position in center
		notification.anchors_preset = Control.PRESET_CENTER
		notification.position = Vector2(-notification.size.x / 2, -50)
		
		# Animate and remove
		var tween = create_tween()
		tween.tween_property(notification, "modulate", Color.TRANSPARENT, duration)
		tween.tween_callback(notification.queue_free)

func show_tile_info(tile: Tile):
	"""Show information about a selected tile"""
	if not tile:
		return
	
	var info = tile.get_info()
	var info_text = "=== " + info["name"] + " ===\n"
	info_text += info["description"] + "\n\n"
	
	for key in info.keys():
		if key != "name" and key != "description":
			info_text += key + ": " + str(info[key]) + "\n"
	
	print("Tile Info:\n", info_text)
	# Could show this in a popup or info panel

func toggle_pause():
	"""Toggle game pause"""
	if game_manager:
		if game_manager.current_state == GameManager.GameState.PLAYING:
			game_manager.pause_game()
			show_notification("Game Paused")
		elif game_manager.current_state == GameManager.GameState.PAUSED:
			game_manager.resume_game()
			show_notification("Game Resumed")

func _input(event):
	"""Handle global UI input"""
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	
	# Deselect tile on right click
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if tile_manager:
				tile_manager.deselect_tile()
				update_button_states()

func _process(delta):
	"""Update UI elements that need frequent updates"""
	# Update items delivered counter
	if items_label and game_manager:
		items_label.text = "Items Delivered: " + str(game_manager.items_delivered) + "/" + str(game_manager.target_items_per_level)