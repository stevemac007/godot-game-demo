# Godot Tile Placement Game

A 2D hexagonal tile placement game built with Godot 4.2. Create item processing chains using producers, transformers, and conveyor belts to deliver items to a central receiver and progress through levels.

## Game Overview

The game is based on a hexagonal grid with a central receiver section. Players place different types of tiles to create item processing chains:

- **Producer Tiles**: Generate raw materials (wood, stone, iron, etc.)
- **Transformer Tiles**: Process items into new forms (wood → processed_wood)
- **Conveyor Belts**: Transport items between tiles
- **Central Receiver**: Accepts all items and manages level progression

The central system accepts everything but requires specific deliverables to unlock the next set of producers and transformers. Each level has increasing difficulty and new tile types become available.

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
- `HexGrid.gd` - Hexagonal grid system
- `Tile.gd` - Base tile class with common functionality
- `Producer.gd`, `Transformer.gd`, `ConveyorBelt.gd` - Specific tile implementations
- `Item.gd` - Item system with stacking and processing
- `TileManager.gd` - Tile inventory and placement management
- `ItemSystem.gd` - Item flow and lifecycle management
- `UIManager.gd` - User interface handling

## Testing

Unit tests are provided for core components:
```bash
# Tests are located in:
test_hex_grid.gd        # Grid system tests
test_tile_system.gd     # Tile functionality tests  
test_game_manager.gd    # Game state management tests
```

To run tests, you'll need the GUT (Godot Unit Testing) addon.

## Game Progression

### Level 1
- **Available**: Basic Producer, Conveyor Belt, Simple Transformer
- **Requirements**: 10x Basic Item, 5x Wood
- **Unlocks**: Advanced tiles

### Level 2
- **Requirements**: 8x Processed Wood, 10x Stone, 15x Basic Item
- **Unlocks**: Stone processing, Iron producers

### Level 3+
- Progressive difficulty with advanced materials
- New transformer types (combiners, refiners)
- Power system mechanics
- Rare item production

## Development Status

This is a **skeleton/framework** implementation that provides:
- ✅ Complete core architecture
- ✅ All major game systems implemented
- ✅ Basic UI and interaction
- ✅ Unit tests for core functionality
- ✅ Extensible design for additional features

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