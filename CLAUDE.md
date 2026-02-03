# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EduMys is an educational mystery visual novel built in Godot 4.5. The player solves detective cases through dialogue choices and minigames while leveling up to unlock abilities.

**Current Status:**
- **Chapter 1:** Complete with 7 evidence items (bracelet, WiFi logs, spider envelope, etc.)
- **Chapter 2:** In development with 2 evidence items (lockbox, threatening note)
- Voice recognition minigames using Vosk (dialogue choice system)
- Save/load system with 10 manual slots, 3 auto-save slots, and quick save
- DTL to TXT converter for sharing dialogue scripts

## Running the Game

Open the project in Godot 4.5 and press F5, or run from command line:
```bash
# Windows (adjust path to your Godot installation)
"C:/Program Files/Godot/Godot.exe" --path .
```

## Architecture

### Autoload Singletons (project.godot)

The game uses several autoloaded singletons that are always available:

- **Dialogic** - Third-party narrative system (handles all dialogue, characters, timelines)
- **PlayerStats** (`src/core/PlayerStats.gd`) - XP, score, level, and hints persistence to `user://player_stats.sav`
- **LevelUpManager** (`autoload/level_up_manager.gd`) - Shows level-up UI with unlocked abilities
- **MinigameManager** (`autoload/minigame_manager.gd`) - Spawns and configures minigames, preloads Vosk model
- **DialogicSignalHandler** (`scripts/dialogic_signal_handler.gd`) - Routes Dialogic signals to game systems, handles evidence unlock animations, triggers auto-saves
- **EvidenceManager** (`autoload/evidence_manager.gd`) - Manages evidence collection and unlocking
- **EvidenceButtonManager** (`autoload/evidence_button_manager.gd`) - Controls persistent Evidence UI button
- **SaveManager** (`autoload/save_manager.gd`) - Renpy-style save/load system with multiple slots, quick save, and auto-save

### Dialogic Integration

Dialogic 2.x is the core narrative engine. Key patterns:

**Timeline files** (`.dtl`) use this syntax:
```
[background arg="res://Bg/classroom.png" fade="1.0"]
join Conrad (half) left
Conrad: Dialogue text here.
[signal arg="start_minigame puzzle_id"]
set {variable_name} = value
set {variable_name} += 10
label my_label
jump my_label
jump other_timeline/
```

**Dialogic variables** are accessed via `Dialogic.VAR.variable_name`. Key variables:
- `conrad_level` - Player's detective level (1-10)
- `minigames_completed` - Count of completed minigames in chapter
- `chapter1_score`, `chapter2_score`, etc. - Per-chapter scoring

**Signal handling**: Timeline `[signal]` events trigger `DialogicSignalHandler._on_dialogic_signal()`. To pause Dialogic during async operations (minigames, level-ups):
```gdscript
Dialogic.paused = true
await some_async_operation()
Dialogic.paused = false
```

### Minigame System

Minigames are triggered from timelines via `[signal arg="start_minigame puzzle_id"]`.

`MinigameManager` handles various minigame types:
- **Fill-in-the-blank** (`minigames/Drag/`) - Drag-and-drop word completion with timer and hints
- **Runner** - Answer questions while running
- **Pacman** - Collect correct answers while avoiding enemies
- **Platformer** - Collect items while platforming
- **Maze** - Navigate maze while answering questions (see [MAZE_MINIGAME_DOCUMENTATION.md](MAZE_MINIGAME_DOCUMENTATION.md))
- **Pronunciation** - Speech recognition minigame
- **Math** - Math problem solving
- **Dialogue Choice** - Select and speak correct dialogue options with Vosk voice recognition
- **Hear and Fill** (`minigames/HearAndFill/`) - Pronunciation-based word selection with TTS playback
- **Riddle** (`minigames/Riddle/`) - Letter-based riddle solving with scrambled letters and undo

#### Fill-in-the-Blank Minigame (Drag & Drop)

Located at `minigames/Drag/scenes/FillInTheBlank.tscn`.

**Features:**
- Drag-and-drop word tiles into sentence blanks
- **Oblong aspect ratio** (2.4:1) for better visual layout
- **1:30 timer countdown** with color warnings (yellow at 30s, red at 10s)
- **Hint system** - Highlights correct answer tiles with yellow pulsing animation
- **Speed bonus** - Complete within 1 minute = +1 hint reward
- **Larger fonts** - 36px title, 26px sentence text, 24px choice tiles
- **Centered grid layout** for better aesthetics
- Time-out failure if not completed in 90 seconds

**Usage in Timelines:**
```
[signal arg="start_minigame puzzle_id"]
```

**Technical Details:**
- Script: `minigames/Drag/scripts/fill_in_the_blank.gd`
- Drag tiles from grid to blank spaces in sentence
- Timer counts down from 1:30, changes color when low
- Hint button uses PlayerStats hint pool, highlights correct tiles
- Completion triggers speed bonus check and auto-save
- Registered in `MinigameManager.start_minigame()`

**Configuration Example:**
```gdscript
"puzzle_id": {
    "sentence_parts": ["The ", " model emphasizes ", " experience."],
    "answers": ["schramm", "shared"],
    "choices": ["aristotle", "shannon", "schramm", "linear", "shared", "public", "individual", "passive"]
}
```

#### Curriculum-Based Minigames

Minigames can use the curriculum question system by using the format: `curriculum:type`

```
[signal arg="start_minigame curriculum:runner"]
[signal arg="start_minigame curriculum:pacman"]
[signal arg="start_minigame curriculum:maze"]
```

This requires two Dialogic variables to be set (usually at chapter start):
- `{current_chapter}` - Chapter number (1-5)
- `{selected_subject}` - Subject name (e.g., "English", "General Mathematics")

The curriculum system (`autoload/curriculum_questions.gd`) maps chapters to quarters:
- Chapters 1-2 → Q1 (First Quarter)
- Chapter 3 → Q2 (Second Quarter)
- Chapter 4 → Q3 (Third Quarter)
- Chapter 5 → Q4 (Fourth Quarter)

See [CURRICULUM_SYSTEM.md](CURRICULUM_SYSTEM.md) for full details on adding curriculum questions.

#### Dialogue Choice Minigame (IN DEVELOPMENT - Vosk Integration)

Located at `minigames/DialogueChoice/scenes/Main.tscn`.

**Current Status:** Voice recognition is functional but still being optimized for accuracy and performance.

**Features:**
- Multiple choice dialogue selection (4 options)
- Real-time voice recognition via Vosk speech-to-text engine
- 1:30 timer countdown
- Wrong answer feedback with retry mechanism (wrong choices are disabled after selection)
- Correct answer triggers sentence-based pronunciation verification

**Voice Recognition System:**
- Uses `GodotVoskRecognizer` with large English model (`vosk-model-en-us-0.22`, 2.7GB)
- Vosk model is preloaded asynchronously on game startup with loading screen
- Microphone audio captured via `AudioStreamMicrophone` on muted "Record" bus (prevents echo)
- Real-time partial transcription display while speaking
- Automatic silence detection (stops after 1.5s of silence)
- Sentence-based matching (60% word match threshold)
- Levenshtein distance algorithm for word similarity (70% per-word threshold)

**Known Issues (Under Development):**
- Vosk accuracy varies with microphone quality and background noise
- Silence detection may be too sensitive/insensitive depending on environment
- Long sentences may have lower match rates
- Performance optimization needed for real-time processing

**Usage in Timelines:**
```
[signal arg="start_minigame dialogue_choice_janitor"]
```

**Voice Recognition Flow:**
1. Player selects correct dialogue choice (Choice 2 for janitor scenario)
2. Full sentence displays on screen
3. Player speaks naturally: "Good afternoon, sir. I was hoping you could help me..."
4. Vosk processes speech in real-time, showing partial transcription
5. After 1.5s silence, final result is matched against target sentence
6. Success (≥60% match) completes minigame, failure allows retry

**Technical Details:**
- Script: `minigames/DialogueChoice/scenes/Main.gd`
- Audio capture: 16kHz mono PCM, 100ms buffer
- Processing: 4096-byte chunks sent to Vosk
- Registered in `MinigameManager._start_dialogue_choice()`

#### Hear and Fill Minigame (Pronunciation-Based)

Located at `minigames/HearAndFill/scenes/Main.tscn`.

**Features:**
- 8 multiple-choice pronunciation options (2 rows of 4 buttons)
- TTS (Text-to-Speech) playback of the blank word via speaker button
- 1:30 timer countdown
- Hint system integrated with PlayerStats
- Speed bonus: Complete within 1 minute = +1 hint reward
- Sentence displayed with blank word to fill

**Usage in Timelines:**
```
[signal arg="start_minigame wifi_router"]
```

**Technical Details:**
- Script: `minigames/HearAndFill/scenes/Main.gd`
- TTS: Uses Godot's built-in `DisplayServer.tts_speak()`
- Hint cost: 1 hint per use (managed by PlayerStats)
- Time tracking for bonus hints (< 60 seconds = +1 hint)
- Registered in `MinigameManager._start_hear_and_fill()`

**Configuration Example:**
```gdscript
"wifi_router": {
    "sentence": "Sir, does this room have a dedicated ____ router?",
    "blank_word": "WiFi",
    "correct_index": 2,
    "choices": ["Hi-fi", "Sci-fi", "WiFi", "Bye-bye", "Fly high", "Sky high", "Pie-fry", "Why try"]
}
```

#### Dialogue Choice Minigame (Voice Recognition) - CONFIGURABLE

Located at `minigames/DialogueChoice/scenes/Main.tscn`.

**Features:**
- Multiple choice dialogue selection (4 options)
- Real-time voice recognition via Vosk speech-to-text engine
- 1:30 timer countdown
- Wrong answer feedback with retry mechanism (wrong choices are disabled after selection)
- Correct answer triggers sentence-based pronunciation verification
- **Fully configurable** - Questions and choices defined in MinigameManager

**Voice Recognition System:**
- Uses `GodotVoskRecognizer` with large English model (`vosk-model-en-us-0.22`, 2.7GB)
- Vosk model is preloaded asynchronously on game startup with loading screen
- Microphone audio captured via `AudioStreamMicrophone` on muted "Record" bus (prevents echo)
- Real-time partial transcription display while speaking
- Automatic silence detection (stops after 1.5s of silence)
- Sentence-based matching (60% word match threshold)
- Levenshtein distance algorithm for word similarity (70% per-word threshold)

**Usage in Timelines:**
```
[signal arg="start_minigame dialogue_choice_janitor"]
[signal arg="start_minigame dialogue_choice_ria_note"]
```

**Configuration Example:**
```gdscript
"dialogue_choice_ria_note": {
    "question": "Why didn't Ria tell anyone about the note?",
    "choices": [
        "She feared it would make her look guilty.",  // Correct
        "She fear it make her guilty.",
        "She was fear to look guilty.",
        "She fearing it made her guilty."
    ],
    "correct_index": 0  // Zero-indexed
}
```

**Technical Details:**
- Script: `minigames/DialogueChoice/scenes/Main.gd`
- Accepts configuration via `configure_puzzle(config)` function
- Dynamically sets question text and choice buttons
- Audio capture: 16kHz mono PCM, 100ms buffer
- Processing: 2048-byte chunks sent to Vosk
- Registered in `MinigameManager._start_dialogue_choice()`

#### Riddle Minigame (Letter Selection)

Located at `minigames/Riddle/scenes/Main.tscn`.

**Features:**
- Letter-based riddle solving with 16 letter buttons (2 rows of 8)
- 1:30 timer countdown
- Dark overlay for better readability
- **Scrambled letters** - Letter positions randomized each playthrough
- **Multiple attempts** - Wrong answers don't end the game, allows retry
- **Undo functionality** - Click on answer display to remove last letter
- Hint system that reveals the next correct letter
- Speed bonus: Complete within 1 minute = +1 hint reward
- Visual feedback: Wrong answer flashes red, allows correction

**Usage in Timelines:**
```
[signal arg="start_minigame bracelet_riddle"]
```

**Technical Details:**
- Script: `minigames/Riddle/scenes/Main.gd`
- Players click letters to spell out the answer (letters scrambled on start)
- **Click answer display** to undo the last selected letter
- Letters can be re-enabled and reused after undo
- Wrong answers show feedback and allow retry until time runs out
- Answer display updates in real-time as letters are selected/removed
- Hint system auto-clicks the next correct letter with yellow highlight
- Registered in `MinigameManager._start_riddle()`

**Configuration Example:**
```gdscript
"bracelet_riddle": {
    "riddle": "Round I go, around your hand,\nI shine and sparkle, isn't that grand?",
    "answer": "BRACELET",
    "letters": ["B", "R", "A", "C", "E", "L", "E", "T", "W", "H", "V", "M", "K", "O", "I", "G"]  // 16 letters total (8 correct + 8 decoys)
}
```

#### Vosk Loading Screen

The large Vosk model (2.7GB) is preloaded asynchronously on game startup to avoid lag during gameplay.

**Features:**
- Animated loading screen with spinner and progress bar
- Shows at game startup before main menu
- Progress tracking (0% → 100%)
- Random loading tips about voice recognition
- Smooth fade-in/fade-out animations

**Technical Details:**
- Scene: `scenes/ui/vosk_loading_screen.tscn`
- Script: `scripts/vosk_loading_screen.gd`
- Triggered automatically by `MinigameManager._ready()`
- Shared Vosk instance used by all voice recognition minigames

To add a new minigame, register it in `MinigameManager.start_minigame()` and create the corresponding handler function.

### Level-Up System

10 levels with abilities defined in `LevelUpManager.ability_data`. Level-ups are triggered via:
- `[signal arg="show_level_up"]` - Shows level-up for current `conrad_level`
- `[signal arg="check_level_up"]` - Checks if conditions met and shows level-up

The flashy level-up scene is at `scenes/ui/level_up_scene_flashy.tscn`.

### Evidence System

Evidence is managed through two autoload singletons:

**EvidenceManager** tracks collected evidence:
- Evidence definitions in `evidence_definitions` dictionary
- Per-chapter evidence filtering via `get_evidence_by_chapter()`
- Unlock evidence via `[signal arg="unlock_evidence evidence_id"]` in timelines
- Evidence persists to `user://evidence.sav`

**EvidenceButtonManager** displays persistent UI:
- Evidence button appears in top-right corner during gameplay
- Shows/hides automatically when timelines start/end
- Opens evidence panel showing collected clues for current chapter
- History feature is disabled - only Evidence button shows

**Evidence Unlock Animation:**
When evidence is unlocked, an animated popup appears:
- "🔍 CLUE FOUND! 🔍" header with pulsing animation
- Evidence image displayed prominently
- Evidence title and description
- 3.5-second display duration with fade-in/fade-out
- Handled by `DialogicSignalHandler._show_evidence_unlock_animation()`

Example evidence unlock in timeline:
```
Conrad: Exactly. It's a significant addition to my clues.
[signal arg="unlock_evidence wifi_logs_c1"]
```

Example evidence definitions:
```gdscript
# Chapter 1
"bracelet_c1": {
    "id": "bracelet_c1",
    "title": "Charm Bracelet",
    "description": "A worn charm bracelet with distinctive blue, red, and white beads, and a tiny silver cross. Found under the desk in the faculty room.",
    "image_path": "res://Bg/Charm.png",
    "chapter": 1
}

# Chapter 2
"lockbox_c2": {
    "id": "lockbox_c2",
    "title": "Empty Lockbox",
    "description": "The Student Council lockbox sits empty on the desk. Whatever was inside has been taken, leaving only questions behind.",
    "image_path": "res://Pics/lockbox.jpg",
    "chapter": 2
}

"threat_note_c2": {
    "id": "threat_note_c2",
    "title": "Threatening Note",
    "description": "A threatening note found in Ria's locker: \"I know what you did with last year's fund. Resign or I'll expose you.\" Someone was blackmailing her.",
    "image_path": "res://Pics/threat_note.jpg",
    "chapter": 2
}
```

### Hint System

The hint system is managed globally through `PlayerStats` and used across minigames.

**PlayerStats Integration:**
- `hints: int` - Global hint pool (starts at 3)
- `add_hints(amount)` - Add hints to player's pool
- `use_hint()` - Consume 1 hint, returns true if successful
- Persists to `user://player_stats.sav`

**Earning Hints:**
- Speed Bonus: Complete any minigame in under 60 seconds = +1 hint
- Shows "⚡ Speed Bonus: +1 Hint! ⚡" message on completion

**Using Hints:**
- Cost: 1 hint per use
- Effect: Highlights the correct answer with yellow pulsing animation
- One hint allowed per minigame attempt
- Shows "No hints available!" if hint pool is empty

**Display:**
- Hint button shows in top-left of minigames
- Hint counter displays current hints: "Hints: 3"
- Updates in real-time when hints are earned or spent

### Save/Load System

The game features a comprehensive Renpy-style save/load system. See [SAVE_SYSTEM.md](SAVE_SYSTEM.md) for complete documentation.

**Quick Reference:**
- **10 manual save slots** - Player-controlled saves via Save/Load menu
- **3 auto-save slots** - Rotating auto-saves at minigame completion and chapter transitions
- **1 quick save slot** - F5 to quick save, F9 to quick load
- **Save thumbnails** - Screenshots showing game state
- **Save metadata** - Timestamp, chapter, scene, level, score

**Key Features:**
- Save/Load buttons in pause menu (ESC)
- Continue button on main menu shows load screen
- Auto-saves trigger after minigames and at chapter transitions
- Quick save/load hotkeys (F5/F9) for convenience
- Renpy-style UI with grid layout and detailed slot information
- **Per-slot data storage** - Each save slot has independent PlayerStats (level, XP, score, hints) and Evidence data
- New game resets both PlayerStats and Evidence for a fresh start

**SaveManager API:**
```gdscript
await SaveManager.save_game(slot_id, take_screenshot)  # Save to specific slot (async)
await SaveManager.load_game(slot_id)                   # Load from specific slot (async)
await SaveManager.quick_save()                         # Quick save (F5) (async)
await SaveManager.quick_load()                         # Quick load (F9) (async)
await SaveManager.auto_save()                          # Auto-save (rotating slots) (async)
```

**Important Notes:**
- All save/load functions are **coroutines** and must be called with `await`
- `load_game()` automatically cleans up active minigames and timelines before loading
- ESC key handling is context-aware (save/load screens take priority over pause menu)
- Main menu transition from pause menu properly cleans up minigames to prevent visual bugs

**Auto-Save Triggers:**
- After completing any minigame (in `DialogicSignalHandler._handle_minigame_signal()`)
- At chapter transitions when title cards appear (in `DialogicSignalHandler._handle_title_card_signal()`)

### Content Organization

- `content/characters/` - Dialogic character files (`.dch`)
- `content/timelines/Chapter N/` - Timeline files named `cNsM.dtl` (Chapter N, Scene M)
- Timeline naming: `c1s1` = Chapter 1 Scene 1, `c1s2b` = Chapter 1 Scene 2 branch
- `assets/evidence/` - Evidence placeholder images (see README.md in folder)

### DTL to TXT Converter Tool

A Python script to convert Dialogic timeline files (`.dtl`) to readable text files (`.txt`) for sharing dialogue with non-developers.

**Files:**
- `dtl_to_txt_converter.py` - Main Python script
- `convert_dtl.bat` - Windows launcher (double-click to run)
- `DTL_CONVERTER_README.md` - Complete usage documentation

**Usage:**
```bash
# Quick start (Windows)
1. Double-click convert_dtl.bat
2. Choose option 3 to convert all Chapter 2 files
3. Share the .txt files

# Command line
python dtl_to_txt_converter.py "content/timelines/Chapter 2"
python dtl_to_txt_converter.py "content/timelines/Chapter 2/c2s3.dtl"
```

**Features:**
- Converts Dialogic markup to clean, readable text
- Preserves character names, dialogue, and story flow
- Shows scene changes, character movements, choices
- Displays minigame triggers and evidence unlocks
- Supports single files or entire folders
- No external dependencies (Python 3.6+ only)

**Output Format:**
```

### Multiple Choice with Retry

For choices where wrong answers should loop back:
```
label choice_label
Character: Question text?
- Wrong choice
    Character: Feedback explaining why wrong.
    jump choice_label
- Correct choice
    Character: Correct response.
```

## Key Dialogic 2.x Notes

- Use `Dialogic.signal_event.connect()` not `Dialogic.dialogic_signal` (that's v1.x)
- Variables: `set {var} = value`, `set {var} += 10`, `set {var} -= 5`
- Jumps within timeline: `jump label_name`
- Jumps to other timeline: `jump timeline_name/`

## Known Fixed Issues

### Main Menu Button from Pause Menu
**Fixed:** Main menu button now works on first click and properly cleans up minigames
- Previously required two clicks when in a minigame
- Now properly cleans up active minigames before transitioning
- No more visual artifacts (main menu showing behind minigame)

### ESC Key Behavior in Save/Load Screens
**Fixed:** ESC key now properly closes save/load screens without triggering pause menu
- Save/load screens have input priority over pause manager
- Pressing ESC in save/load screen closes it and returns to pause menu
- No more double-ESC behavior

### Load Game During Minigames
**Fixed:** Loading a save while in a minigame now works correctly
- Previously failed with "load fail" error
- Now automatically cleans up active minigames and timelines before loading
- Proper state cleanup ensures smooth transitions

### Fill-in-the-Blank Hint System
**Fixed:** Hint button now works without errors
- Fixed property checking using `"word_data" in tile_rect` syntax
- Hint animation now uses `modulate` property instead of non-existent `color` property
- Correct answer tiles pulse with yellow glow when hint is used

### Settings Transition from Pause Menu
**Fixed:** Settings menu now works properly from pause menu without errors
- Previously used Dialogic.Save.save/load which caused "Cannot call method 'set_meta' on a previously freed instance" errors
- Settings would require pressing ESC twice to open, and closing would crash with Dialogic portrait errors
- Now settings loads as an overlay on top of the paused game (no scene change)
- Returning from settings properly shows pause menu again without timeline restoration errors
- No more freed instance errors or double-click requirements

### Platformer Minigame Camera Error
**Fixed:** Platformer minigame camera follow system now works correctly
- Previously tried to access `.offset` property on Node2D (which doesn't exist)
- Error: "Invalid access to property or key 'offset' on a base object of type 'Node2D'"
- Changed to use `.position` property which is correct for Node2D
- Camera now follows player smoothly without errors
## Important Patterns & Bug Fixes

### Minigame Error Handling

`MinigameManager` must emit the `minigame_completed` signal even on failure, otherwise Dialogic remains paused forever:

```gdscript
func _start_curriculum_minigame(minigame_type: String) -> void:
	var config = CurriculumQuestions.get_config(minigame_type)
	if config.is_empty():
		push_error("No curriculum config for: " + minigame_type)
		# CRITICAL: Emit completion signal to unpause Dialogic
		minigame_completed.emit("curriculum_" + minigame_type, false)
		return
```

### Evidence Panel Input Handling

The evidence panel consumes the Escape key to prevent the pause menu from opening while evidence is displayed:

```gdscript
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_evidence_panel()
		get_viewport().set_input_as_handled()  # Prevents pause menu
```

### Testing Individual Chapters

To test a chapter directly in Dialogic without starting a new game:
1. Open the chapter's intro timeline (e.g., `c2s0.dtl`)
2. Ensure `current_chapter` and `selected_subject` are set at the top
3. Press "Play Timeline" in Dialogic editor

Without these variables, curriculum minigames will fail and freeze the game.

## Recent Changes (2026-02-02)

- Added evidence system to Chapter 2 (5 evidence items)
- Fixed curriculum minigame freeze when config fails
- Added Escape key handling to evidence panel
- Set "English" as default subject for all chapters
- Fixed Dialogic addon typo (`.ts1n` → `.tscn`)
- Standardized chapter initialization across all chapters
