# Godot Tile Placement Game - Math Game Edition

A 2D hexagonal tile placement game built with Godot 4.2. Create mathematical processing chains using number producers and math operation transformers to collect sets of numbers and progress through the game.

## Math Game Overview

This implementation features a **basic math game** where players use producers and transformers to create and manipulate numbers:

- **Number Producers**: Generate numbers 1, 2, 3, 5, and 7 automatically (every 5 seconds)
- **Math Transformers**: Perform addition and subtraction operations (6 seconds per operation)
- **Central Receiver**: Collects numbers and tracks progress toward the goal
- **Goal**: Collect 10 of each number from 1 to 10
- **Win Condition**: Game ends when you collect 10 of the number "10"
- **Speed Boosts**: Earn 5% speed increases when completing sets of 10

## Math Game Mechanics

### Number Generation
- **Available Producers**: Numbers 1, 2, 3, 5, 7 (produced directly)
- **Production Rate**: 1 item every 5 seconds
- **Target Numbers**: 4, 6, 8, 9, 10 (must be created through math operations)

### Math Operations
- **Addition Transformer**: Combines two numbers (e.g., 2+3=5, 1+9=10)
- **Subtraction Transformer**: Subtracts smaller from larger (e.g., 7-3=4, 10-1=9)
- **Processing Time**: 6 seconds per operation
- **All Combinations**: Complete recipe system for creating numbers 1-10

### Progression System
- **Requirements**: 10 of each number 1-10
- **Set Completion**: When you collect 10 of any number, you earn a speed boost
- **Speed Boosts**: 5% increase in production or transformation speed
- **Game Completion**: Achieved when 10 of number "10" is collected

### Visual System
- **Distinct Colors**: Each number 1-10 has a unique, easily distinguishable color
- **Real-time Feedback**: Visual effects for production, processing, and completion
- **Progress Tracking**: Clear indication of current progress toward each number goal

## Features

### Core Systems
- ✅ Hexagonal grid system with coordinate conversion
- ✅ Tile placement and management system
- ✅ Item creation, processing, and flow system
- ✅ Level progression with requirements
- ✅ User interface with tile selection and information display
- ✅ Game state management (play, pause, restart)

### Tile Types
- ✅ **Producer**: Automatically generates items at configurable rates
- ✅ **Transformer**: Processes items using recipe system
- ✅ **Conveyor Belt**: Transports items with directional control
- ✅ **Central Receiver**: Accepts items and tracks progression

### Game Mechanics
- ✅ Item stacking and quality system
- ✅ Tile health and destruction mechanics
- ✅ Progressive unlocking of new tiles and mechanics
- ✅ Power system for enhanced production
- ✅ Visual feedback for tile interactions

## Getting Started

### Prerequisites
- Godot 4.2 or later
- Basic understanding of Godot project structure

### Setup
1. Clone or download this repository
2. Open Godot and import the project using `project.godot`
3. Run the project by pressing F5 or clicking the play button
4. The main scene (`Main.tscn`) will load automatically

### Controls
- **Left Click**: Place selected tile on grid
- **Right Click**: Remove tile from grid or deselect current tile
- **ESC**: Pause/unpause the game
- **UI Buttons**: Select different tile types for placement

## Project Structure

See [GAME_STRUCTURE.md](GAME_STRUCTURE.md) for detailed documentation of the codebase architecture and components.

### Key Files
- `GameManager.gd` - Main game controller and state management
- `MathGameManager.gd` - Math game specific logic and speed boost management
- `HexGrid.gd` - Hexagonal grid system
- `Tile.gd` - Base tile class with common functionality
- `Producer.gd` - Number producers (1, 2, 3, 5, 7) with 5-second intervals
- `Transformer.gd` - Math operation transformers (addition/subtraction) with 6-second processing
- `CentralReceiver.gd` - Number collection and progress tracking
- `Item.gd` - Number items with distinct colors and values
- `TileManager.gd` - Tile inventory and placement management
- `ItemSystem.gd` - Item flow and lifecycle management
- `UIManager.gd` - User interface handling

## Math Game Strategy

### Basic Strategy
1. **Start with Producers**: Place producers for numbers 1, 2, 3, 5, 7
2. **Add Transformers**: Use addition and subtraction to create missing numbers
3. **Key Combinations**:
   - 1+3=4, 2+4=6, 3+5=8, 1+8=9, 5+5=10
   - 5-1=4, 8-2=6, 9-1=8, 10-1=9
4. **Optimize Flow**: Use conveyor belts to efficiently route numbers
5. **Speed Boosts**: Apply boosts strategically to bottleneck operations

### Advanced Tips
- **Number 10 is Critical**: Focus on creating reliable 10 production (5+5, 7+3, etc.)
- **Balance Production**: Don't over-produce early numbers if you can't process them
- **Speed Boost Strategy**: Alternate between boosting producers and transformers
- **Conveyor Planning**: Plan efficient paths to avoid item jams

## Testing

Unit tests are provided for core components and math game functionality:
```bash
# Tests are located in:
test_hex_grid.gd        # Grid system tests
test_tile_system.gd     # Tile functionality tests (updated for math game)
test_game_manager.gd    # Game state management tests
test_math_game.gd       # Math game specific functionality tests
```

### Math Game Tests Include:
- Number item color distinctiveness
- Producer and transformer timing (5s/6s)
- Addition and subtraction recipe completeness
- Math operation processing accuracy
- Set completion detection
- Game completion conditions
- Speed boost application and usage
- Progress tracking functionality

To run tests, you'll need the GUT (Godot Unit Testing) addon.

## Game Progression

### Math Game Progression
- **Goal**: Collect 10 of each number 1-10
- **Starting Numbers**: 1, 2, 3, 5, 7 (from producers)
- **Derived Numbers**: 4, 6, 8, 9, 10 (from math operations)
- **Speed Boosts**: Earned when completing any set of 10
- **Win Condition**: Collecting 10 of number "10"

### Example Progression Path
1. **Early Game**: Set up producers for 1, 2, 3, 5, 7
2. **Mid Game**: Add transformers to create 4 (1+3), 6 (1+5), 8 (3+5)
3. **Late Game**: Focus on creating 9 (2+7) and 10 (5+5, 3+7)
4. **Optimization**: Use speed boosts to accelerate bottlenecks
5. **Victory**: Achieve 10 of number "10"

## Development Status

This is a **complete math game implementation** that provides:
- ✅ Full math game mechanics (producers, transformers, central receiver)
- ✅ Number generation system (1, 2, 3, 5, 7)
- ✅ Math operations (addition and subtraction with complete recipe sets)
- ✅ Progress tracking and set completion detection
- ✅ Speed boost system with 5% increments
- ✅ Game completion detection (10 of number "10")
- ✅ Distinct visual representation for all numbers 1-10
- ✅ Comprehensive unit tests for math game functionality
- ✅ Backward compatibility with original tile placement system

### Math Game Features
The implementation includes all requested features:
- **Producers**: Numbers 1, 2, 3, 5, 7 with 5-second production intervals
- **Transformers**: Addition and subtraction with 6-second processing times
- **Central Receiver**: Tracks 10 of each number 1-10, provides speed boosts
- **Speed Boosts**: 5% increases available when completing sets
- **Win Condition**: Game ends when 10 of number "10" is collected
- **Complete Recipe System**: All numbers 1-10 achievable through operations

### Ready for Play
The math game is fully functional and ready to play with:
- Intuitive number-based gameplay
- Strategic depth through math operations
- Progressive difficulty and optimization challenges
- Clear visual feedback and progress tracking

### Ready for Extension
The skeleton is designed to be easily extended with:
- Additional tile types and mechanics
- Enhanced visual effects and animations
- Sound system integration
- Save/load functionality
- Multiplayer support
- Advanced progression systems

## Contributing

This is a demo/skeleton project. Feel free to:
- Add new tile types
- Implement additional game mechanics
- Enhance the visual presentation
- Add sound effects and music
- Improve the UI/UX
- Add more comprehensive testing

## License

This project is provided as-is for educational and development purposes.