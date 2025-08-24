# Godot Tile Placement Game - Structure Documentation

## Overview
This is a 2D hexagonal tile placement game built with Godot 4.2. Players place producer tiles, transformer tiles, and conveyor belts to create item processing chains that deliver items to a central receiver.

## Core Game Components

### 1. GameManager.gd
- **Purpose**: Main game controller and state management
- **Key Features**:
  - Game state management (Menu, Playing, Paused, Game Over)
  - Score tracking and level progression
  - Coordination between all game systems
  - Input handling for global actions (pause, restart)

### 2. HexGrid.gd
- **Purpose**: Hexagonal grid system for tile placement
- **Key Features**:
  - Hexagonal coordinate system with pixel conversion
  - Grid visualization and interaction
  - Tile placement validation and management
  - Mouse interaction handling
  - Neighbor calculation for hex coordinates

### 3. Tile System

#### Base Tile.gd
- **Purpose**: Base class for all placeable tiles
- **Key Features**:
  - Health system and destruction mechanics
  - Item input/output queues
  - Visual representation and mouse interaction
  - Serialization for save/load functionality

#### Producer.gd
- **Purpose**: Generates items automatically
- **Key Features**:
  - Configurable production rates and item types
  - Power system for efficiency modulation
  - Visual production effects
  - Upgradeable efficiency system

#### Transformer.gd
- **Purpose**: Processes items from one type to another
- **Key Features**:
  - Recipe-based transformation system
  - Multiple transformer types (processor, combiner, refiner)
  - Processing time and efficiency mechanics
  - Visual processing feedback

#### ConveyorBelt.gd
- **Purpose**: Transports items between tiles
- **Key Features**:
  - Directional item transport
  - Rotation mechanics (clockwise/counterclockwise)
  - Item capacity management
  - Connection to adjacent tiles

#### CentralReceiver.gd
- **Purpose**: Accepts items and manages level progression
- **Key Features**:
  - Accepts all item types
  - Level requirement tracking
  - Progression unlocking system
  - Storage and statistics tracking

### 4. Item.gd
- **Purpose**: Represents items flowing through the system
- **Key Features**:
  - Item types with different properties
  - Stacking system for similar items
  - Quality and value systems
  - Visual movement animations
  - Processing history tracking

### 5. Management Systems

#### TileManager.gd
- **Purpose**: Manages tile inventory and placement
- **Key Features**:
  - Tile availability and unlocking system
  - Placement validation and cost management
  - Tile selection and inventory tracking
  - Progressive unlocking based on level

#### ItemSystem.gd
- **Purpose**: Manages item flow throughout the game
- **Key Features**:
  - Item registration and lifecycle management
  - Flow tracking between tiles
  - Performance optimization
  - System-wide item processing

#### UIManager.gd
- **Purpose**: Handles user interface and player interactions
- **Key Features**:
  - UI element updates and synchronization
  - Button handling for tile selection
  - Information display (score, level, requirements)
  - Notification system

## Game Flow

### 1. Initialization
1. GameManager initializes all systems
2. HexGrid sets up the playing field
3. TileManager loads starting tiles
4. CentralReceiver is placed at grid center
5. UI displays initial state

### 2. Gameplay Loop
1. Player selects tiles from inventory
2. Player places tiles on hexagonal grid
3. Producers generate items automatically
4. Items flow through conveyor belts
5. Transformers process items
6. Central receiver accepts items
7. Level progression based on requirements

### 3. Progression System
- Each level has specific item delivery requirements
- Completing requirements unlocks new tiles and mechanics
- Difficulty increases with higher item targets
- New tile types become available at higher levels

## File Structure
```
/workspace/
├── project.godot              # Main Godot project file
├── Main.tscn                  # Main game scene
├── icon.svg                   # Game icon
├── export_presets.cfg         # Export configuration
├── 
├── Core Scripts/
├── GameManager.gd             # Main game controller
├── HexGrid.gd                 # Hexagonal grid system
├── UIManager.gd               # User interface manager
├── 
├── Tile System/
├── Tile.gd                    # Base tile class
├── Producer.gd                # Producer tile
├── Transformer.gd             # Transformer tile
├── ConveyorBelt.gd           # Conveyor belt tile
├── CentralReceiver.gd        # Central receiver tile
├── 
├── Game Systems/
├── Item.gd                    # Item class
├── TileManager.gd             # Tile management
├── ItemSystem.gd              # Item flow management
├── 
├── Tests/
├── test_hex_grid.gd           # HexGrid unit tests
├── test_tile_system.gd        # Tile system tests
├── test_game_manager.gd       # GameManager tests
├── 
└── Assets/
    ├── sprites/               # Game sprites (placeholder)
    └── sounds/                # Game audio (placeholder)
```

## Key Game Mechanics

### Hexagonal Grid
- Uses axial coordinate system (q, r)
- Supports 6-directional movement and connections
- Visual grid overlay with hover effects
- Efficient neighbor calculation

### Item Processing Chain
1. **Producers** → Generate raw materials (wood, stone, iron)
2. **Transformers** → Process materials (wood → processed_wood)
3. **Conveyor Belts** → Transport items between tiles
4. **Central Receiver** → Accept final products

### Progression System
- Level 1: Basic items (wood, stone)
- Level 2: Processed materials
- Level 3: Advanced items and alloys
- Level 4: Energy systems and powered items
- Level 5: Super materials and rare items

## Testing
Unit tests are provided for core components:
- HexGrid coordinate system and tile management
- Tile functionality and item processing
- GameManager state management and progression

## Future Expansion
The skeleton provides foundation for:
- Additional tile types (splitters, mergers, storage)
- Power system with generators and consumers
- Research tree for unlocking advanced mechanics
- Save/load system using serialization
- Multiplayer support
- Visual effects and animations
- Sound system integration