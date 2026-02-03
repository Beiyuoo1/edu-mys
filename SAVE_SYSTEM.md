# Save/Load System - Renpy-Style Implementation

This document describes the comprehensive save/load system implemented for EduMys, similar to Renpy visual novels.

## Overview

The game now features a full-featured save/load system with:
- **10 manual save slots** for player-controlled saves
- **3 rotating auto-save slots** that save automatically at key moments
- **1 quick save slot** for fast save/load with F5/F9 hotkeys
- **Save thumbnails** showing screenshots of the game state
- **Save metadata** including timestamp, chapter, scene, level, and score
- **Renpy-style UI** with grid layout and detailed slot information

## Components

### SaveManager (autoload/save_manager.gd)

The central autoload singleton managing all save operations.

**Key Methods:**
```gdscript
await SaveManager.save_game(slot_id, take_screenshot)  # Save to a specific slot (async)
await SaveManager.load_game(slot_id)                   # Load from a specific slot (async)
SaveManager.delete_save(slot_id)                       # Delete a save slot
await SaveManager.quick_save()                         # Quick save (F5) (async)
await SaveManager.quick_load()                         # Quick load (F9) (async)
await SaveManager.auto_save()                          # Auto-save (rotating slots) (async)
SaveManager.has_save(slot_id)                          # Check if slot exists
SaveManager.get_save_slot(slot_id)                     # Get slot data
```

**Important:** All save/load methods are coroutines and must be called with `await`.

**Save Slot Structure:**
```gdscript
class SaveSlot:
    var slot_id: int              # Slot number (1-10 for manual, -1 to -3 for auto, 99 for quick)
    var timestamp: int            # Unix timestamp of save
    var chapter: int              # Current chapter number
    var scene_name: String        # Timeline name (e.g., "c1s3")
    var player_level: int         # Conrad's level
    var total_score: int          # Total score
    var screenshot_path: String   # Path to thumbnail image
    var dialogic_slot_name: String  # Internal Dialogic save name
```

### Save/Load UI Screen (scenes/ui/save_load_screen.tscn)

Main save/load interface with:
- **Two tabs:** Manual Saves and Auto Saves
- **Grid layout:** 2 columns of save slots
- **Mode switching:** Can be used for saving or loading

**Usage:**
```gdscript
# Show save screen
var save_screen = SAVE_LOAD_SCREEN.instantiate()
get_tree().root.add_child(save_screen)
save_screen.set_mode(0)  # 0 = SAVE, 1 = LOAD

# Show load screen
var load_screen = SAVE_LOAD_SCREEN.instantiate()
get_tree().root.add_child(load_screen)
load_screen.set_mode(1)  # LOAD mode
```

### Save Slot Button (scenes/ui/save_slot_button.tscn)

Individual save slot display showing:
- **Screenshot thumbnail** (256x144 pixels) - **Captures actual gameplay**, not the save menu
- **Slot label** (e.g., "Slot 1", "Auto Save 1", "Quick Save")
- **Timestamp** (MM/DD/YYYY HH:MM)
- **Chapter and scene** (e.g., "Chapter 1 - c1s3")
- **Player stats** (Level and Score)
- **Action buttons** (Save/Load and Delete)

Empty slots show "Empty Slot" with grayed-out appearance.

**Screenshot Fix:**
The save system now **hides the save screen** before taking the screenshot, ensuring thumbnails show the actual game state instead of the save menu interface. This is handled automatically in `save_load_screen.gd` by temporarily hiding the UI during screenshot capture.

## User Interface Integration

### Pause Menu

New buttons added to the pause menu:
- **Save Game** - Opens save screen
- **Load Game** - Opens load screen

These appear between "Resume" and "Settings" buttons.

### Main Menu

The **Continue** button now:
- Shows the load screen instead of auto-loading the last save
- Allows players to choose which save to continue from
- Is enabled if any save exists (manual, auto, or quick)

### Hotkeys

- **F5** - Quick Save (saves to dedicated quick save slot)
- **F9** - Quick Load (loads from quick save slot)
- **ESC** - Pause/Resume game

Quick save/load only work during gameplay (when pause is enabled).

## Auto-Save System

Auto-saves trigger automatically at these moments:

1. **After completing a minigame** - Ensures progress is saved after puzzle completion
2. **At chapter transitions** - When title cards appear for new chapters

Auto-saves rotate through 3 slots (-1, -2, -3), always keeping the 3 most recent auto-saves.

**Implementation:**
```gdscript
# In dialogic_signal_handler.gd
func _handle_minigame_signal(puzzle_id: String):
    # ... minigame logic ...
    await SaveManager.auto_save()  # Auto-save after completion

func _handle_title_card_signal(chapter: String):
    # ... title card logic ...
    await SaveManager.auto_save()  # Auto-save at chapter start
```

## Save Data Storage

### File Locations

All saves are stored in `user://` directory (OS-specific):
- **Windows:** `%APPDATA%\Godot\app_userdata\EduMys\`
- **Linux:** `~/.local/share/godot/app_userdata/EduMys/`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/EduMys/`

### Save Structure

```
user://
├── save_metadata.json          # Master metadata file
├── slot_1_data.sav            # Slot 1 PlayerStats & Evidence
├── slot_2_data.sav            # Slot 2 PlayerStats & Evidence
├── slot_-1_data.sav           # Auto-save 1 PlayerStats & Evidence
├── slot_99_data.sav           # Quick save PlayerStats & Evidence
├── screenshots/
│   ├── save_1.png             # Thumbnail for slot 1
│   ├── save_2.png             # Thumbnail for slot 2
│   └── ...
└── dialogic/saves/
    ├── save_1/                # Dialogic data for slot 1
    │   └── state.txt
    ├── save_2/                # Dialogic data for slot 2
    │   └── state.txt
    ├── autosave_1/            # Auto-save slot 1
    │   └── state.txt
    └── quicksave/             # Quick save slot
        └── state.txt
```

**Important:** Each save slot now has its own `slot_X_data.sav` file containing independent PlayerStats and Evidence data. This means different save slots can have different levels, hints, scores, and collected evidence.

### save_metadata.json

Contains metadata for all saves:
```json
{
    "1": {
        "slot_id": 1,
        "timestamp": 1706745000,
        "chapter": 1,
        "scene_name": "c1s3",
        "player_level": 2,
        "total_score": 150,
        "screenshot_path": "user://screenshots/save_1.png",
        "dialogic_slot_name": "save_1"
    },
    "current_autosave_index": 0
}
```

## What Gets Saved

Each save captures **independent data per slot**:

### Dialogic State
- Current timeline position
- All Dialogic variables (conrad_level, chapter scores, etc.)
- Character states and dialogue history
- Timeline choice history

### Player Stats (Per-Slot in `slot_X_data.sav`)
- Score (total points)
- XP (experience points)
- Level (1-10)
- Hints (remaining hints)

**Note:** Each save slot has its own PlayerStats. Loading a different save slot restores that slot's stats.

### Evidence (Per-Slot in `slot_X_data.sav`)
- List of unlocked evidence IDs
- Per-chapter evidence tracking

**Note:** Each save slot has its own evidence collection. This allows multiple playthroughs with different evidence states.

### Metadata
- Timestamp (when save was created)
- Chapter number
- Scene name (current timeline)
- Screenshot thumbnail

### New Game
When starting a new game:
- PlayerStats are reset to defaults (Level 1, 0 XP, 0 Score, 3 Hints)
- Evidence collection is cleared
- All Dialogic variables are reset

## Usage Examples

### Manual Save from Code
```gdscript
# Save to slot 5 with screenshot
var success = await SaveManager.save_game(5, true)
if success:
    print("Game saved!")
```

### Load from Code
```gdscript
# Load from slot 5
var success = SaveManager.load_game(5)
if success:
    print("Game loaded!")
```

### Quick Save/Load
```gdscript
# Quick save
await SaveManager.quick_save()

# Quick load
SaveManager.quick_load()
```

### Check if Save Exists
```gdscript
if SaveManager.has_save(1):
    print("Slot 1 has a save")
else:
    print("Slot 1 is empty")
```

### Get Save Information
```gdscript
var slot = SaveManager.get_save_slot(1)
if slot:
    print("Saved at: ", SaveManager.format_timestamp(slot.timestamp))
    print("Chapter: ", slot.chapter)
    print("Level: ", slot.player_level)
```

## User Experience Flow

### Saving a Game
1. Player presses ESC to open pause menu
2. Player clicks "Save Game"
3. Save screen appears showing all slots
4. Player clicks on a slot (empty or filled)
5. If slot is filled, confirmation dialog appears
6. Game saves with screenshot thumbnail
7. Save screen refreshes to show updated slot
8. Notification: "Game Saved!"

### Loading a Game
1. **From Main Menu:**
   - Player clicks "Continue"
   - Load screen appears with all saves
   - Player selects a save
   - Game loads and continues from that point

2. **From Pause Menu:**
   - Player presses ESC to open pause menu
   - Player clicks "Load Game"
   - Load screen appears
   - Player selects a save
   - Game loads immediately

### Quick Save/Load
1. **Quick Save (F5):**
   - Player presses F5 during gameplay
   - Game saves instantly to quick save slot
   - Notification appears: "Quick Saved!" (green)

2. **Quick Load (F9):**
   - Player presses F9 during gameplay
   - If quick save exists, game loads instantly
   - If no quick save, notification: "No Quick Save Found!" (orange)

### Auto-Save
- Happens automatically, no user interaction
- Notification not shown (silent save)
- Visible in Load screen under "Auto Saves" tab

## Technical Notes

### Screenshot Thumbnails
- Captured using `get_viewport().get_texture().get_image()`
- Resized to 256x144 (16:9 aspect ratio)
- Saved as PNG in `user://screenshots/`
- Loaded asynchronously when displaying save slots

### Save Timing
- Screenshots are taken **before** saving Dialogic state
- One frame delay to ensure screen is rendered
- Auto-saves use `await` to prevent blocking gameplay

### Save Slot IDs
- **Manual saves:** 1-10
- **Auto-saves:** -1, -2, -3 (negative numbers)
- **Quick save:** 99

### Backwards Compatibility
- Old "continue_save" system still works
- SaveManager checks for both new and old saves
- Players with existing saves can continue normally

## Future Enhancements

Possible additions:
- Save descriptions (player-editable text)
- Save sorting (by date, chapter, level)
- Multiple save pages (20+ slots)
- Cloud save integration
- Save file export/import
- Save file validation and corruption detection

## Debugging

### Clear All Saves
Press **Delete** key on main menu to clear the old "continue_save" slot.

To clear all new saves manually:
```gdscript
# Delete all manual saves
for i in range(1, 11):
    SaveManager.delete_save(i)

# Delete auto-saves
for i in range(1, 4):
    SaveManager.delete_save(-i)

# Delete quick save
SaveManager.delete_save(99)
```

### Enable Save Logging
SaveManager prints debug info for all operations:
```
Game saved to slot 1 at 2025-01-31 14:30:00
Game loaded from slot 1 (2025-01-31 14:30:00)
Save slot 3 deleted
```

## Troubleshooting

### "Failed to save Dialogic state"
- Ensure Dialogic timeline is active when saving
- Check that `dialogic_slot_name` is valid
- Verify `user://dialogic/saves/` directory exists

### "Save Failed!" notification
- Check console for error messages
- Ensure sufficient disk space
- Verify write permissions to `user://` directory

### Screenshots not showing
- Check if screenshot file exists at `user://screenshots/save_X.png`
- Verify viewport is rendering when screenshot is taken
- Ensure one frame delay before capturing

### Quick load not working
- Verify quick save exists with `SaveManager.has_save(99)`
- Check that F9 input action is properly configured
- Ensure pause is enabled (only works during gameplay)

## Configuration

### Change Number of Slots

Edit `autoload/save_manager.gd`:
```gdscript
const MAX_MANUAL_SLOTS := 10  # Change to 20 for more slots
const AUTOSAVE_SLOTS := 3      # Change to 5 for more auto-saves
```

### Change Hotkeys

Edit `project.godot` input actions:
```
quick_save = F5  # Change to different key
quick_load = F9  # Change to different key
```

### Disable Auto-Save

Comment out auto-save calls in `dialogic_signal_handler.gd`:
```gdscript
# await SaveManager.auto_save()  # Disabled
```

### Change Screenshot Size

Edit `autoload/save_manager.gd`:
```gdscript
# Change from 256x144 to different resolution
img.resize(512, 288, Image.INTERPOLATE_LANCZOS)
```

## Recent Bug Fixes and Improvements

### Loading During Minigames
**Fixed:** Loading a save while in a minigame now works correctly.
- `load_game()` now automatically cleans up active minigames before loading
- Properly ends any active timelines to prevent conflicts
- Waits one frame to ensure complete cleanup before loading Dialogic state

**Technical Implementation:**
```gdscript
# In SaveManager.load_game()
if MinigameManager and MinigameManager.current_minigame:
    if is_instance_valid(MinigameManager.current_minigame):
        MinigameManager.current_minigame.queue_free()
    MinigameManager.current_minigame = null

if Dialogic.current_timeline:
    Dialogic.end_timeline()
    await get_tree().process_frame
```

### ESC Key Handling in Save/Load Screens
**Fixed:** ESC key now properly closes save/load screens without triggering the pause menu.
- Save/load screens now handle `ui_cancel` input directly
- `PauseManager._is_save_load_screen_active()` checks for active save/load screens
- Input priority: Save/Load Screen > Pause Menu

**User Experience:**
- Press ESC in save/load screen → screen closes, returns to pause menu
- No more double-ESC behavior or unexpected game resuming

### Main Menu Transition from Pause Menu
**Fixed:** Main menu button now works on first click and properly cleans up minigames.
- Previously required two clicks when in a minigame
- Now cleans up active minigames before transitioning to main menu
- Proper cleanup order prevents visual artifacts

**Technical Implementation:**
```gdscript
# In PauseManager._on_main_menu()
if MinigameManager and MinigameManager.current_minigame:
    if is_instance_valid(MinigameManager.current_minigame):
        MinigameManager.current_minigame.queue_free()
    MinigameManager.current_minigame = null
```

### Settings Transition from Pause Menu
**Fixed:** Game no longer continues briefly when entering settings from pause menu.
- Previously, calling `_resume_game()` would unpause Dialogic, causing brief gameplay
- Now manually cleans up pause menu without restoring Dialogic's pause state
- Settings screen loads smoothly without game continuation

**Technical Implementation:**
```gdscript
# In PauseManager._on_settings()
# Clean up pause menu WITHOUT unpausing Dialogic
is_paused = false
if pause_menu_instance and is_instance_valid(pause_menu_instance):
    var canvas_layer = pause_menu_instance.get_parent()
    pause_menu_instance.queue_free()
    if canvas_layer:
        canvas_layer.queue_free()
    pause_menu_instance = null
# Don't restore Dialogic's pause state - keep it paused until settings loads
```

## Summary

The new save/load system provides a professional, Renpy-style experience with:
- Multiple save slots for different playthroughs
- Quick save/load for convenience
- Auto-save for safety
- Rich metadata and thumbnails
- Intuitive UI
- Backwards compatibility
- Robust error handling and cleanup
- Context-aware input handling

Players can now manage their game progress with confidence, experiment with different choices, and never lose progress to unexpected interruptions. The system handles edge cases gracefully, including loading during minigames and transitioning between game states.
