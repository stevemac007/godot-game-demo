extends "res://addons/gut/test.gd"

## Unit tests for the GameManager
## Tests game state management, scoring, and level progression

var game_manager: GameManager

func before_each():
	"""Setup before each test"""
	game_manager = GameManager.new()

func after_each():
	"""Cleanup after each test"""
	if game_manager:
		game_manager.queue_free()

func test_game_state_changes():
	"""Test game state management"""
	# Initial state should be MENU
	assert_eq(game_manager.current_state, GameManager.GameState.MENU, "Initial state should be MENU")
	
	# Test state change
	game_manager.change_state(GameManager.GameState.PLAYING)
	assert_eq(game_manager.current_state, GameManager.GameState.PLAYING, "State should change to PLAYING")

func test_score_system():
	"""Test scoring system"""
	var initial_score = game_manager.current_score
	
	# Add score
	game_manager.add_score(100)
	assert_eq(game_manager.current_score, initial_score + 100, "Score should increase")
	
	# Test negative score (shouldn't go below 0 if implemented)
	game_manager.add_score(-200)
	assert_ge(game_manager.current_score, 0, "Score should not go negative")

func test_level_progression():
	"""Test level progression system"""
	var initial_level = game_manager.current_level
	var initial_target = game_manager.target_items_per_level
	
	# Complete level
	game_manager.complete_level()
	
	assert_eq(game_manager.current_level, initial_level + 1, "Level should increase")
	assert_gt(game_manager.target_items_per_level, initial_target, "Target should increase")
	assert_eq(game_manager.items_delivered, 0, "Items delivered should reset")

func test_item_received_handling():
	"""Test item received handling"""
	var initial_items = game_manager.items_delivered
	var initial_score = game_manager.current_score
	
	# Simulate item received
	game_manager._on_item_received("basic_item", 10)
	
	assert_eq(game_manager.items_delivered, initial_items + 1, "Items delivered should increase")
	assert_eq(game_manager.current_score, initial_score + 10, "Score should increase by item value")

func test_pause_resume():
	"""Test game pause and resume functionality"""
	game_manager.change_state(GameManager.GameState.PLAYING)
	
	# Test pause
	game_manager.pause_game()
	assert_eq(game_manager.current_state, GameManager.GameState.PAUSED, "Game should be paused")
	
	# Test resume
	game_manager.resume_game()
	assert_eq(game_manager.current_state, GameManager.GameState.PLAYING, "Game should resume")

func test_game_restart():
	"""Test game restart functionality"""
	# Set some game state
	game_manager.current_score = 500
	game_manager.current_level = 3
	game_manager.items_delivered = 15
	
	# Restart
	game_manager.restart_game()
	
	assert_eq(game_manager.current_score, 0, "Score should reset")
	assert_eq(game_manager.current_level, 1, "Level should reset")
	assert_eq(game_manager.items_delivered, 0, "Items delivered should reset")
	assert_eq(game_manager.current_state, GameManager.GameState.PLAYING, "Should be in playing state")

func test_level_completion_trigger():
	"""Test automatic level completion when target is reached"""
	game_manager.target_items_per_level = 5
	game_manager.items_delivered = 4
	var initial_level = game_manager.current_level
	
	# Deliver one more item to trigger completion
	game_manager._on_item_received("test_item", 10)
	
	assert_eq(game_manager.current_level, initial_level + 1, "Level should advance automatically")