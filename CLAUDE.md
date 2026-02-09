# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EduMys is an educational mystery visual novel built in Godot 4.5. The player solves detective cases through dialogue choices and minigames while leveling up to unlock abilities.

**Current Status:**
- **Chapter 1:** Complete with 7 evidence items (bracelet, WiFi logs, spider envelope, etc.) - **Multi-subject support** (Math, Science, English) - **Celestine variant complete** - **Detective Analysis minigames integrated** (proof-of-concept for capstone)
- **Chapter 2:** Complete with 2 evidence items (lockbox, threatening note) - **Celestine variant complete**
- **Chapter 3:** Complete with 4 evidence items (cruel note, paint cloth, Victor's sketchbook, receipt) - **Celestine variant complete**
- **Chapter 4:** Complete with 1+ evidence items (anonymous note, etc.) - **Celestine variant complete**
- **Chapter 5:** Complete - B.C. revelation chapter - **Celestine variant complete** (both protagonists can experience the climax)
- **Dual Protagonist System:** Players can choose between Conrad (male) or Celestine (female) at game start
  - **100% feature parity** - ALL chapters (1-5) fully support both protagonists
  - Character selection screen: `scenes/ui/character_selection.tscn`
- **Multi-Subject Curriculum System** - Math, Science, and English tracks with subject-specific minigames
- Voice recognition minigames using Vosk (dialogue choice system)
- Save/load system with 10 manual slots, 3 auto-save slots, and quick save
- **Animated character portraits** - Conrad, Celestine, Mark, Janitor Fred, Principal Alan, and Alex have mouth animation when speaking
- **DTL to TXT converter** - Convert chapters to readable transcripts
- **Clue analyzer tool** - Analyze transcripts for evidence suggestions
- Mystery character ("???") with vignette portrait for suspenseful scenes
- **B.C. Card System** - Overarching mystery across all chapters
- **Chapter Results System** - Simplified "LEVEL UP!" screen with 3-star rating and Mind Games Reviewer
  - **Timer-based failure tracking** - Failed minigames (timeout) affect star rating with 90s penalty per failure
- **F5 Skip Functionality** - All minigames support F5 to skip (for testing and accessibility)
- **ESC Pause Menu** - Works during minigames and dialogues
- **Debug Chapter Skip** - Press 1-5 keys on subject selection screen to skip to any chapter (for testing)

## Running the Game

Open the project in Godot 4.5 and press F5, or run from command line:
```bash
# Windows (adjust path to your Godot installation)
"C:/Program Files/Godot/Godot.exe" --path .
```

### Debug Chapter Skip

For testing purposes, you can skip directly to any chapter:

1. Click **"New Game"** on the main menu
2. On the subject selection screen, press **1-5** on your keyboard:
   - **1** = Chapter 1 (Stolen Exam Papers)
   - **2** = Chapter 2 (Student Council Mystery)
   - **3** = Chapter 3 (Art Week Vandalism)
   - **4** = Chapter 4 (Anonymous Notes)
   - **5** = Chapter 5 (B.C. Revelation)

**Default Settings:**
- Protagonist: Conrad (change to "celestine" in `scripts/subject_selection.gd:251` if needed)
- Subject: English
- Stats and evidence are reset for each chapter

**Location:** `scripts/subject_selection.gd` - `_debug_skip_to_chapter()` function

## Architecture

### Autoload Singletons (project.godot)

The game uses several autoloaded singletons that are always available:

- **Dialogic** - Third-party narrative system (handles all dialogue, characters, timelines)
- **PlayerStats** (`src/core/PlayerStats.gd`) - XP, score, level, hints, and selected subject persistence to `user://player_stats.sav`
- **LevelUpManager** (`autoload/level_up_manager.gd`) - Shows level-up UI with unlocked abilities
- **MinigameManager** (`autoload/minigame_manager.gd`) - Spawns and configures minigames, preloads Vosk model, handles curriculum variants
- **CurriculumQuestions** (`autoload/curriculum_questions.gd`) - Stores subject-specific questions for curriculum minigames (Math, Science, English)
- **DialogicSignalHandler** (`scripts/dialogic_signal_handler.gd`) - Routes Dialogic signals to game systems, handles evidence unlock animations, triggers auto-saves
- **EvidenceManager** (`autoload/evidence_manager.gd`) - Manages evidence collection and unlocking
- **EvidenceButtonManager** (`autoload/evidence_button_manager.gd`) - Controls persistent Evidence UI button
- **SaveManager** (`autoload/save_manager.gd`) - Renpy-style save/load system with multiple slots, quick save, and auto-save
- **ChapterStatsTracker** (`autoload/chapter_stats_tracker.gd`) - Tracks player performance for chapter results screen
- **PauseManager** (`autoload/pause_manager.gd`) - Handles ESC key pause/resume with save/load integration
- **CustomNameboxHandler** (`scripts/custom_namebox_handler.gd`) - Dynamically changes namebox style based on speaking character

### Custom Visual Novel UI

The game uses custom dialogue box and namebox textures from `assets/VisualNovelDialogueGUI_PNG/`:

**Dialogue Textbox:**
- Main textbox: `textbox_dark_yellow.png` - Gold/yellow themed dialogue box with decorative borders
- Configured in: `addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Textbox/vn_textbox_layer.tscn`
- StyleBox: `assets/VisualNovelDialogueGUI_PNG/textbox_dark_yellow_style.tres`
- Texture margins: 40px on all sides to preserve corner decorations

**Character-Specific Nameboxes:**
Each character has a unique namebox color that appears when they speak:
- **Celestine**: `namebox_pink.png` (pink)
- **Conrad**: `namebox_yellow.png` (yellow)
- **Mark**: `namebox_blue.png` (blue)
- **Alex**: `namebox_2_purple.png` (purple variant)
- **Diwata Laya**: `namebox_2_blue.png` (blue variant)
- **Greg**: `namebox_2_blue.png` (blue variant)
- **Janitor Fred**: `namebox_2_green.png` (green variant)
- **Mia**: `namebox_purple.png` (purple)
- **Ms. Reyes**: `namebox_green.png` (green)
- **Ms. Santos**: `namebox_orange.png` (orange)
- **Mystery (???)**: `namebox_red.png` (red)
- **Principal Alan**: `namebox_green.png` (green)
- **Ria**: `namebox_2_pink.png` (pink variant)
- **Ryan**: `namebox_blue.png` (blue)
- **Alice**: `namebox_blue.png` (blue)
- **Ben**: `namebox_2_green.png` (green variant)
- **Victor**: `namebox_orange.png` (orange)

**Implementation:**
- `CustomNameboxHandler` autoload listens to Dialogic's `speaker_updated` signal
- Dynamically applies character-specific StyleBoxTexture when speaker changes
- StyleBox files in `assets/VisualNovelDialogueGUI_PNG/*_style.tres`
- Texture margins: 20px left/right, 15px top/bottom for proper corner rendering

**Choice Buttons:**
- Idle state: `choice_dark_idle.png`
- Hover state: `choice_dark_hover.png`
- Configured in: `addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/vn_choice_layer.tscn`
- StyleBox files: `choice_dark_idle_style.tres` and `choice_dark_hover_style.tres`
- Texture margins: 20px on all sides

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
- **Pacman** - Collect correct answers while avoiding enemies (⚠️ Consider replacing with Logic Grid)
- **Platformer** - Collect items while platforming
- **Maze** - Navigate maze while answering questions (⚠️ Consider replacing with Timeline Reconstruction)
- **Pronunciation** - Speech recognition minigame
- **Math** - Math problem solving
- **Dialogue Choice** - Select and speak correct dialogue options with Vosk voice recognition
- **Hear and Fill** (`minigames/HearAndFill/`) - Pronunciation-based word selection with TTS playback
- **Riddle** (`minigames/Riddle/`) - Letter-based riddle solving with scrambled letters and undo
- **Detective Analysis** (`minigames/DetectiveAnalysis/`) - Context-integrated math/science problems with visual evidence and educational explanations
- **Logic Grid Puzzle** (`minigames/LogicGrid/`) - Detective-style deduction grid for systematic reasoning (NEW - better replacement for Maze)
- **Timeline Reconstruction** (`minigames/TimelineReconstruction/`) - Drag-and-drop event sequencing for chronological reasoning (NEW - better replacement for Pacman)

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
- **F5 to skip** - Press F5 to instantly complete the minigame (useful for testing or accessibility)

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

#### Dialogue Choice Minigame (Vosk Voice Recognition)

Located at `minigames/DialogueChoice/scenes/Main.tscn`.

**Current Status:** Fully functional with configurable questions and timer-based failure tracking.

**Features:**
- Multiple choice dialogue selection (4 options)
- Real-time voice recognition via Vosk speech-to-text engine
- **1:30 timer countdown with failure tracking** - Timer runs out = minigame fails and affects chapter results
- Wrong answer feedback with retry mechanism (wrong choices are disabled after selection)
- Correct answer triggers sentence-based pronunciation verification
- **Fully configurable** - Questions and choices defined in MinigameManager
- **F5 to skip** - Press F5 to instantly complete the minigame (useful for testing or accessibility)

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
1. Player selects correct dialogue choice
2. Full sentence displays on screen
3. Player speaks naturally (must complete within 1:30 timer)
4. Vosk processes speech in real-time, showing partial transcription
5. After 1.5s silence, final result is matched against target sentence
6. Success (≥60% match) completes minigame, failure allows retry
7. **Timer runs out** = minigame fails, dialogue continues, affects star rating

**Timer Failure System:**
- When timer reaches 00:00, minigame automatically fails
- Failed minigames tracked in `ChapterStatsTracker.minigames_failed`
- Each failed minigame adds **90 seconds penalty** to average time calculation
- Affects star rating on chapter results screen (3-star, 2-star, or 1-star)

**Technical Details:**
- Script: `minigames/DialogueChoice/scenes/Main.gd`
- Audio capture: 16kHz mono PCM, 100ms buffer
- Processing: 2048-byte chunks sent to Vosk
- Registered in `MinigameManager._start_dialogue_choice()`
- Question text dynamically set via `configure_puzzle()`

#### Hear and Fill Minigame (Pronunciation-Based)

Located at `minigames/HearAndFill/scenes/Main.tscn`.

**Features:**
- 8 multiple-choice pronunciation options (2 rows of 4 buttons)
- TTS (Text-to-Speech) playback of the blank word via speaker button
- 1:30 timer countdown
- Hint system integrated with PlayerStats
- Speed bonus: Complete within 1 minute = +1 hint reward
- Sentence displayed with blank word to fill
- **F5 to skip** - Press F5 to instantly complete the minigame (useful for testing or accessibility)

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

**Configuration Examples:**
```gdscript
"wifi_router": {
    "sentence": "Sir, does this room have a dedicated ____ router?",
    "blank_word": "WiFi",
    "correct_index": 2,
    "choices": ["Hi-fi", "Sci-fi", "WiFi", "Bye-bye", "Fly high", "Sky high", "Pie-fry", "Why try"]
},
"anonymous_notes": {
    "sentence": "The students are receiving ____ notes that expose their secrets.",
    "blank_word": "anonymous",
    "correct_index": 0,
    "choices": ["anonymous", "unanimous", "anomalous", "enormous", "synonymous", "autonomous", "monotonous", "ominous"]
}
```

**Important Notes:**
- The TTS system is reconfigured when `configure_puzzle()` is called
- This ensures the speaker button pronounces the correct `blank_word`
- Without re-setup, the TTS would use the default hardcoded value

#### Dialogue Choice Minigame (Voice Recognition) - CONFIGURABLE

Located at `minigames/DialogueChoice/scenes/Main.tscn`.

**Features:**
- Multiple choice dialogue selection (4 options)
- Real-time voice recognition via Vosk speech-to-text engine
- 1:30 timer countdown
- Wrong answer feedback with retry mechanism (wrong choices are disabled after selection)
- Correct answer triggers sentence-based pronunciation verification
- **Fully configurable** - Questions and choices defined in MinigameManager
- **F5 to skip** - Press F5 to instantly complete the minigame (useful for testing or accessibility)

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

**Configuration Examples:**
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
},
"dialogue_choice_cruel_note": {
    "question": "Which sentence is grammatically correct and clearly states an observation?",
    "choices": [
        "They left evidence.",  // Correct
        "They leaving evidence.",
        "Evidence left they.",
        "They was left evidence."
    ],
    "correct_index": 0  // Zero-indexed
},
"dialogue_choice_approach_suspect": {
    "question": "How should Conrad approach Alex, who might be sending the anonymous notes?",
    "choices": [
        "We should confront her directly and ask if she's been sending the notes.",
        "We should observe her behavior carefully before making assumptions about her intentions.",  // Correct
        "We should report her to the principal immediately based on the archive access log.",
        "We should ignore the evidence and look for other suspects instead."
    ],
    "correct_index": 1  // Zero-indexed
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
},
"receipt_riddle": {
    "riddle": "I am the sound of paper in motion, a quick motion of the wrist and hand. As I was ____ the pages, something fell out onto the land.",
    "answer": "FLIPPING",
    "letters": ["F", "L", "I", "P", "P", "I", "N", "G", "A", "S", "T", "R", "M", "O", "B", "W"]  // 16 letters total (8 correct + 8 decoys)
}
```

#### Detective Analysis Minigame (Context-Integrated)

Located at `minigames/DetectiveAnalysis/scenes/Main.tscn`.

**Purpose:** Integrates math and science education directly into the detective story narrative. Unlike generic curriculum games, these problems are context-specific and directly help solve the mystery.

**Features:**
- Visual evidence display with explanatory captions
- Story context explaining why this problem matters to the investigation
- Multiple-choice questions based on mathematical or scientific reasoning
- 1:30 timer countdown
- Hint system integrated with PlayerStats
- Speed bonus: Complete within 1 minute = +1 hint reward
- Educational explanations showing formulas and real-world applications
- **F5 to skip** - Press F5 to instantly complete the minigame (useful for testing or accessibility)

**Usage in Timelines:**
```
if {selected_subject} == "math":
    Conrad: I can use mathematics to verify this timeline...
    [signal arg="start_minigame timeline_analysis_greg_math"]
elif {selected_subject} == "science":
    Celestine: Physics can help determine when these footprints were made...
    [signal arg="start_minigame evaporation_analysis_science"]
```

**Available Minigames (10 total - 5 Math + 5 Science):**

**Chapter 1:**
- `timeline_analysis_greg_math` - Speed-Distance-Time calculation to verify alibi
- `evaporation_analysis_science` - Evaporation rate physics to date footprints

**Chapter 2:**
- `fund_analysis_math` - Percentage and ratio calculation for missing funds
- `fingerprint_analysis_science` - Biological classification of fingerprint patterns

**Chapter 3:**
- `paint_area_math` - Area calculation to determine paint coverage
- `energy_analysis_science` - Potential energy (PE = mgh) to determine if sculpture fell or was pushed

**Chapter 4:**
- `probability_analysis_math` - Probability calculation for note sender patterns
- `electricity_analysis_science` - Electrical power (P=VI) to track printer usage

**Chapter 5:**
- `pattern_recognition_math` - Arithmetic sequences and sum formulas for B.C.'s pattern
- `light_analysis_science` - Light dispersion and wavelengths for B.C.'s prism metaphor

**Technical Details:**
- Script: `minigames/DetectiveAnalysis/scenes/Main.gd`
- Configured via `configure_puzzle(config)` with structure:
  ```gdscript
  {
      "title": "Timeline Analysis",
      "context": "Story explanation of the problem...",
      "evidence_image": "res://path/to/evidence.png",  // Optional
      "evidence_caption": "Evidence description",
      "question": "[b]Question:[/b] What is the answer?",
      "choices": ["Answer 1", "Answer 2", "Answer 3", "Answer 4"],
      "correct_index": 0,
      "explanation": "Detailed explanation with formulas and reasoning..."
  }
  ```
- Registered in `MinigameManager._start_detective_analysis()`
- All configurations stored in `MinigameManager.detective_analysis_configs`

**Pedagogical Benefits:**
- **Authentic Assessment**: Students apply knowledge to solve real problems, not drill-and-practice
- **Contextual Learning**: Knowledge embedded in meaningful narrative (Situated Learning Theory)
- **Real-World Relevance**: Shows practical applications of math/science formulas
- **Engagement**: Story motivation enhances problem-solving
- **Capstone Defense**: Strong pedagogical justification with research support

**Integration Pattern:**
For best results, add 3-5 lines of context dialogue BEFORE the minigame trigger:
```dtl
Conrad: Greg claims he walked straight home after school.
Conrad: School ends at 5:00 PM. His house is 2.5 km away.
Conrad: If he walks at 5 km/h, I can calculate his arrival time.
Mark: Math can help verify his alibi!
[signal arg="start_minigame timeline_analysis_greg_math"]
Conrad: The math shows he'd arrive at 5:30 PM...
Conrad: But his WiFi log shows 9:00 PM. He lied.
```

See [DETECTIVE_ANALYSIS_USAGE.md](DETECTIVE_ANALYSIS_USAGE.md) for complete usage guide and [CHAPTER1_INTEGRATION_COMPLETE.md](CHAPTER1_INTEGRATION_COMPLETE.md) for testing and research methodology.

**📐 Chapter 1 Math Integration:** See [CHAPTER1_MATH_INTEGRATION.md](CHAPTER1_MATH_INTEGRATION.md) for complete details on math-focused Logic Grid and Timeline Reconstruction minigames integrated throughout Chapter 1.

#### Logic Grid Puzzle (Context-Integrated Detective Reasoning)

Located at `minigames/LogicGrid/scenes/Main.tscn`.

**Purpose:** Authentic detective-style deduction grid where students systematically eliminate possibilities to find the solution. This mimics real investigative techniques and teaches logical reasoning.

**Features:**
- Interactive grid with clickable cells
- Cell states cycle: Unknown (?) → No (✗) → Yes (✓) → Unknown
- 2:00 timer countdown
- Hint system reveals one correct match
- Speed bonus: Complete within 1 minute = +1 hint reward
- Visual feedback with logical explanations
- **F5 to skip** - Press F5 to instantly complete the minigame

**Chapter 1 Math Integration:**
- **c1s3 (WiFi Analysis):** `logic_grid_wifi_math` - Match WiFi connection times to suspects
- **c1s5 (Bracelet Discovery):** `logic_grid_alibi_math` - Deduce suspect locations

**Usage in Timelines:**
```
if {selected_subject} == "math":
    Conrad: Two devices connected to the WiFi - at 8:00 PM and 9:00 PM.
    Conrad: If I use logical deduction to match devices to suspects...
    [signal arg="start_minigame logic_grid_wifi_math"]
elif {selected_subject} == "science":
    Celestine: Let me apply the scientific method to systematically test each hypothesis...
    [signal arg="start_minigame logic_grid_funds_science"]
```

**Educational Value:**
- **Math**: Set theory, logical operators, binary logic, systematic elimination, proof by contradiction
- **Science**: Scientific method, hypothesis testing, deductive reasoning, experimental design
- **Real-World**: Actual detective technique used in investigations
- **Bloom's Taxonomy**: Analysis/Evaluation level (higher-order thinking)

**Sample Configurations:**
```gdscript
"logic_grid_alibi_math": {
    "title": "Alibi Verification Grid",
    "rows": ["Greg", "Ben", "Alex"],
    "cols": ["Library", "Cafeteria", "Gym"],
    "clues": [
        "Greg was NOT in the library",
        "Ben was studying in a quiet place",
        ...
    ],
    "solution": {
        "Greg": "Gym",
        "Ben": "Library",
        "Alex": "Cafeteria"
    }
}
```

**Pedagogical Benefits:**
- **Situated Learning**: Embedded in mystery narrative context
- **Authentic Assessment**: Real detective reasoning, not abstract logic
- **Engagement**: Students naturally want to solve the puzzle to progress the story
- **Capstone Defense**: Strong justification - teaches mathematical proof techniques through gameplay

#### Timeline Reconstruction (Causal Reasoning & Sequencing)

Located at `minigames/TimelineReconstruction/scenes/Main.tscn`.

**Purpose:** Students drag-and-drop events into correct chronological order based on time stamps, causality, and evidence. Develops temporal reasoning and cause-effect understanding.

**Features:**
- Events pool (left side) with shuffled events
- Timeline slots (right side) for correct sequence
- Click cards to move between pool and timeline
- 2:00 timer countdown
- Hint system places next correct event
- Speed bonus: Complete within 1 minute = +1 hint reward
- Visual feedback showing correct sequence with reasoning
- **F5 to skip** - Press F5 to instantly complete the minigame

**Chapter 1 Math Integration:**
- **c1s2 (Footprint Analysis):** `timeline_footprints_math` - Calculate when footprints were made using evaporation rates
- **c1s5 (Greg's Alibi):** `timeline_analysis_greg_math` - Use distance-rate-time formula to expose false alibi

**Usage in Timelines:**
```
if {selected_subject} == "math":
    Conrad: The floor dries completely in 45 minutes according to the janitor.
    Conrad: If I can reconstruct the timeline of events mathematically...
    [signal arg="start_minigame timeline_footprints_math"]
elif {selected_subject} == "science":
    Celestine: Let me trace the cause-and-effect chain to reconstruct what happened...
    [signal arg="start_minigame timeline_vandalism_science"]
```

**Educational Value:**
- **Math**: Time intervals, duration calculation, sequence ordering, temporal reasoning, functions
- **Science**: Cause-and-effect relationships, experimental sequencing, scientific process order
- **Real-World**: Forensic timeline reconstruction technique
- **Bloom's Taxonomy**: Analysis/Synthesis level (understanding relationships)

**Sample Configurations:**
```gdscript
"timeline_theft_math": {
    "title": "Theft Timeline Analysis",
    "events": [
        {"id": "event1", "text": "Janitor mops floor (3:00 PM)"},
        {"id": "event2", "text": "AC starts leaking (3:15 PM)"},
        {"id": "event3", "text": "Wet footprints appear (3:30 PM)"},
        ...
    ],
    "correct_order": ["event1", "event2", "event3", "event4", "event5"]
}
```

**Pedagogical Benefits:**
- **Contextual Learning**: Students see WHY chronological order matters (solves mystery)
- **Transfer of Knowledge**: Time calculation skills transfer to other math problems
- **Engagement**: Story context provides intrinsic motivation
- **Capstone Defense**: Better than generic sequencing - embedded in meaningful narrative

**Why These Replace Maze/Pacman:**
Both new minigames offer superior pedagogical value:
1. **Story Integration**: Directly help solve mysteries (vs. interrupting gameplay)
2. **Higher-Order Thinking**: Analysis/Evaluation level (vs. simple recall)
3. **Authentic Assessment**: Real detective techniques (vs. abstract challenges)
4. **Subject Integration**: Math/Science naturally embedded (vs. forced question overlays)

See [NEW_MINIGAMES_IMPLEMENTATION.md](NEW_MINIGAMES_IMPLEMENTATION.md) for complete implementation guide.

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

### Multi-Subject Curriculum System

The game supports three subject tracks: **Math (General Mathematics)**, **Science (Earth & Physical Science)**, and **English (Oral Communication)**. Players select their subject at the start, and Chapter 1 adapts minigames accordingly.

**Subject Selection:**
- Scene: `scenes/ui/subject_selection.tscn`
- Script: `scripts/subject_selection.gd`
- Stores selection in `PlayerStats.selected_subject` and `Dialogic.VAR.selected_subject`

**Curriculum Minigames:**
Triggered via `[signal arg="start_minigame curriculum:TYPE"]` format:
- `curriculum:pacman` - Pacman with subject questions (**Now with 3-lives system!**)
- `curriculum:maze` - Maze with subject questions
- `curriculum:runner` - Runner with subject questions
- `curriculum:platformer` - Platformer with subject questions

**Pacman Lives System:**
The Pacman minigame now features a 3-lives respawn system:
- Player starts with **3 lives** (displayed in red text)
- When hit by enemy: loses 1 life, respawns at center after 0.5s
- **2 seconds of invincibility** after respawn (semi-transparent)
- Game over only occurs after all 3 lives are used
- Visual feedback: red screen flash, shake effect, floating "-1 Life" text

**CurriculumQuestions System:**
- Autoload: `autoload/curriculum_questions.gd`
- Maps chapters to quarters (Chapter 1 → Q1, Chapter 2 → Q2, etc.)
- Stores questions by subject → quarter → minigame type
- Format: `{question: String, correct: String, wrong: Array}`

**Chapter 1 Subject Integration:**
The timeline checks `{selected_subject}` and triggers appropriate minigames:

```dtl
if {selected_subject} == "english":
    [signal arg="start_minigame dialogue_choice_janitor"]
elif {selected_subject} == "math":
    [signal arg="start_minigame curriculum:pacman"]
elif {selected_subject} == "science":
    [signal arg="start_minigame curriculum:runner"]
```

**Subject-Specific Variants:**
For story-specific minigames (like `locker_examination`), MinigameManager automatically looks for subject variants:
- Base: `locker_examination` (English)
- Math: `locker_examination_math`
- Science: `locker_examination_science`

The system checks `PlayerStats.selected_subject` and automatically appends `_math` or `_science` to find variants. If no variant exists, it falls back to the English version.

**All Science Variants Available:**
All story-specific minigames now have science variants with **Physics-focused content**:
- **Fill-in-blank:** `locker_examination_science`, `pedagogy_methods_science`, `wifi_router_science`, `anonymous_notes_science`, `observation_teaching_science`
- **Riddles:** `bracelet_riddle_science` (INERTIA), `receipt_riddle_science` (ENERGY)
- **Dialogue Choices:** `dialogue_choice_janitor_science`, `dialogue_choice_ria_note_science`, `dialogue_choice_cruel_note_science`, `dialogue_choice_approach_suspect_science`, `dialogue_choice_bc_approach_science`
- **Platformer:** `platformer_science`

**Curriculum Content (Complete Q1-Q4):**
- **Math Q1-Q4:** Functions & Operations, Exponentials & Logarithms, Trigonometry, Statistics & Probability
- **Science Q1-Q4 (100% Physics):**
  - **Q1 (Ch 1-2):** Motion and Forces (Newton's Laws, F=ma, kinematics)
  - **Q2 (Ch 3):** Work, Energy, and Power (PE=mgh, KE=½mv², conservation)
  - **Q3 (Ch 4):** Electricity and Magnetism (Ohm's Law, circuits, P=VI)
  - **Q4 (Ch 5):** Waves, Light, and Modern Physics (v=fλ, wave-particle duality, photons)
- **English Q1-Q4:** Communication Models, Communication Strategies, Speech Context/Acts, Presentation Skills/Argumentation

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

# Chapter 3: Art Week Vandalism Mystery
"cruel_note_c3": {
    "id": "cruel_note_c3",
    "title": "Cruel Note",
    "description": "A handwritten note found at the vandalized sculpture scene: \"Not everyone deserves to shine.\" The message is personal and emotional, suggesting the vandal felt overshadowed.",
    "image_path": "res://Bg/assets/evidence/cruel_note.png",
    "chapter": 3
}

"paint_cloth_c3": {
    "id": "paint_cloth_c3",
    "title": "Paint-Stained Cloth",
    "description": "A cloth rag stained with various paint colors found in Victor's art supply cabinet. Matches the fabric and paint patterns of the cloth found at the vandalism scene. Contains an inventory tag linking it to Victor's assigned supplies.",
    "image_path": "res://Bg/assets/evidence/rug.png",
    "chapter": 3
}

"victor_sketchbook_c3": {
    "id": "victor_sketchbook_c3",
    "title": "Victor's Sketchbook",
    "description": "Victor's personal sketchbook containing technical studies and later pages filled with angry, violent sketches. One page shows Mia's sculpture 'The Reader' with harsh X marks drawn over it, revealing his dark thoughts and resentment.",
    "image_path": "res://Bg/assets/evidence/victor_sketchbook.png",
    "chapter": 3
}

"receipt_c3": {
    "id": "receipt_c3",
    "title": "Art Supply Receipt",
    "description": "Receipt from an art supply store dated yesterday at 8:47 PM. Found in Victor's sketchbook. Proves he was out near the school despite claiming to be home all night.",
    "image_path": "res://Bg/assets/evidence/receipt.png",
    "chapter": 3
}

# Chapter 4: Anonymous Notes Mystery
"anonymous_note_c4": {
    "id": "anonymous_note_c4",
    "title": "Anonymous Note",
    "description": "A folded note found in Ben's locker containing a moral accusation: \"You witnessed your friend cheat on the exam but said nothing. Silence protects the guilty. What does that make you?\" The handwriting is neat and deliberate, written on standard school paper.",
    "image_path": "res://Bg/assets/evidence/anonymous_note.png",
    "chapter": 4
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

### Chapter Results System (COMPLETE)

The game tracks player performance throughout each chapter and displays a simplified results screen followed by an educational review.

**Current Implementation Status:** ✅ **COMPLETE** - Fully implemented for Chapters 1-4

**Key Files:**
- **ChapterStatsTracker** (`autoload/chapter_stats_tracker.gd`) - Tracks all stats during gameplay
- **SimpleResultsScreen** (`scenes/ui/chapter_results/simple_results_screen.gd`) - "LEVEL UP!" screen with 3-star rating
- **MindGamesReviewer** (`scenes/ui/chapter_results/mind_games_reviewer.gd`) - Educational review page (notebook-style)
- **DialogicSignalHandler** (`scripts/dialogic_signal_handler.gd`) - Handles chapter results display sequence

**Two-Screen Design:**

**STEP 1: Simple Results Screen**
- Title: "LEVEL UP!" (gold text, 72px with outline)
- Subtitle: "Chapter X Complete!" (light blue-white text, 42px)
- **3-Star Rating System** based on average minigame completion time:
  - ⭐⭐⭐ (3 stars): < 30 seconds average per minigame - "⚡ Outstanding Performance! ⚡"
  - ⭐⭐☆ (2 stars): < 60 seconds average per minigame - "Great Job!"
  - ⭐☆☆ (1 star): ≥ 60 seconds average per minigame - "Case Solved!"
- Dark overlay (85% opacity) with centered gold-bordered panel
- "Continue" button at bottom (blue, hover effect)
- Viewport-based centering for all screen sizes

**STEP 2: Mind Games Reviewer** (Educational Content)
- Notebook-style two-page layout with cream/paper background
- **Left Page:**
  - Chapter title (e.g., "Chapter 1: The Stolen Exam Papers")
  - **Dynamic Clues** - Pulled from collected evidence titles
  - **Dynamic Evidence** - Full descriptions from EvidenceManager
  - Culprit identification (color-coded in red)
  - Remaining mystery (B.C. card references in purple)
- **Right Page:**
  - "Chapter X: Mind Games Reviewer" title
  - **5 Educational Concepts** - Oral Communication terms with definitions
  - **Minigame Solution Guides** - Explanations of correct answers and why they matter
  - Decorative separator line between concepts and guides
- "Continue" button at bottom center (blue, hover effect)
- Viewport-based centering, scrollable content

**Tracked Statistics** (used for star calculation):
- ⏱️ **Completion time** - Total time to complete chapter
- 🎮 **Minigames completed** - Number of minigames finished successfully
- ❌ **Minigames failed** - Number of minigames that timed out (90s penalty each)
- ⭐ **Average time per minigame** - Used for star rating (includes failure penalties)

**Star Rating Calculation:**
```gdscript
# Formula: (completion_time + failed_minigames * 90s) / total_minigames
var total_minigames = minigames_completed + minigames_failed
var failed_penalty = minigames_failed * 90.0  # 90s penalty per failure
var avg_time = (completion_time + failed_penalty) / total_minigames

# Star thresholds:
# 3 stars: avg_time < 30.0 seconds
# 2 stars: avg_time < 60.0 seconds
# 1 star:  avg_time >= 60.0 seconds
```

**Timeline Integration:**

Automatic tracking (via existing signals):
```dtl
[signal arg="unlock_evidence clue_id"]  # Tracks clue collection
[signal arg="start_minigame puzzle_id"]  # Tracks minigames
[signal arg="show_title_card 1"]  # Starts chapter tracking
```

Manual tracking for choices:
```dtl
label question_label
Conrad: Who is the culprit?
- Greg (CORRECT)
    [signal arg="track_correct_choice"]
    set {chapter1_score} += 10
    Conrad: Correct!
- Ben (WRONG)
    [signal arg="track_wrong_choice"]
    set {chapter1_score} -= 5
    Conrad: Wrong, try again.
    jump question_label
```

Perfect interrogation tracking:
```dtl
[signal arg="start_interrogation"]
(Multiple choice questions)
[signal arg="end_interrogation"]
```

Show results at chapter end:
```dtl
Conrad: Case closed!
[signal arg="show_chapter_results"]
jump c2s0/
```

**Chapter Content Summary:**

**Chapter 1: The Stolen Exam Papers**
- Educational Concepts: Speaker, Encoding, Channel, Feedback, Decoding
- Minigames: Janitor Approach (dialogue), WiFi Router (hear & fill), Communication Model (fill-in-blank)
- Evidence: 7 items (bracelet, WiFi logs, spider envelope, etc.)
- Culprit: Greg (accidental)
- B.C. Card: Lesson 1 - Truth

**Chapter 2: The Student Council Mystery**
- Educational Concepts: Context, Barriers, Clarity, Active Listening, Non-verbal Communication
- Minigames: Ria's Note Question (dialogue)
- Evidence: 2 items (lockbox, threatening note)
- Culprit: Ryan (blackmailer)
- B.C. Card: Lesson 2 - Responsibility

**Chapter 3: Art Week Vandalism**
- Educational Concepts: Tone, Purpose, Audience, Empathy, Inference
- Minigames: Cruel Note Observation (dialogue), Receipt Riddle (riddle)
- Evidence: 4 items (cruel note, paint cloth, Victor's sketchbook, receipt)
- Culprit: Victor
- B.C. Card: Lesson 3 - Creativity

**Chapter 4: Anonymous Notes Mystery**
- Educational Concepts: Ethics, Intention, Impact vs Intent, Critical Thinking, Wisdom
- Minigames: Anonymous Notes (hear & fill), Approaching Suspect (dialogue), Maze (curriculum)
- Evidence: 1+ items (anonymous note, etc.)
- Culprit: Alex (well-intentioned student)
- B.C. Card: Lesson 4 - Wisdom

See [CHAPTER_RESULTS_USAGE.md](CHAPTER_RESULTS_USAGE.md) for complete implementation guide.

### Content Organization

- `content/characters/` - Dialogic character files (`.dch`)
  - **Animated Portraits**: Multiple characters have animated mouth movement when speaking
    - **Conrad** (Main protagonist - Male):
      - Scene: `scenes/portraits/conrad_animated_portrait.tscn`
      - Script: `scenes/portraits/conrad_animated_portrait.gd`
      - Extends `DialogicPortrait` for Dialogic 2.x compatibility
      - Uses `AnimatedSprite2D` with "idle" and "talking" animations
      - Automatically plays "talking" animation when Conrad speaks
      - Returns to "idle" when dialogue stops or other characters speak
      - Frames: `Conrad_half.png` (idle), `Conrad_half_mouth_animation_1-5.png` (talking)
    - **Celestine** (Main protagonist - Female):
      - Scene: `scenes/portraits/celestine_animated_portrait.tscn`
      - Script: `scenes/portraits/celestine_animated_portrait.gd`
      - Same system as Conrad, responds to Celestine's dialogue
      - Frames: `Sprites/mouth_animation/Celestine/Thebe_half.png` (idle), `Celestine_half_mouth_animation_1-5.png` (talking)
    - **Mark** (Best friend):
      - Scene: `scenes/portraits/mark_animated_portrait.tscn`
      - Script: `scenes/portraits/mark_animated_portrait.gd`
      - Same system as Conrad, responds to Mark's dialogue
      - Frames: `Characters/animation/mark/Mark_half.png` (idle), `Mark_half mouth animation 1-5.png` (talking)
    - **Janitor Fred** (Chapter 1):
      - Scene: `scenes/portraits/janitor_animated_portrait.tscn`
      - Script: `scenes/portraits/janitor_animated_portrait.gd`
      - Frames: `Sprites/Janitor_half.png` (idle), `Sprites/mouth_animation/Janitor/Janitor_half mouth animation 1-5.png` (talking)
    - **Principal Alan** (Chapter 1):
      - Scene: `scenes/portraits/principal_animated_portrait.tscn`
      - Script: `scenes/portraits/principal_animated_portrait.gd`
      - Supports both "Principal Alan" and "Principal" display names
      - Frames: `Sprites/mouth_animation/Principal/Principal_half idle.png` (idle), `Principal_half mouth animation 1-5.png` (talking)
    - **Alex** (Chapter 2/4 - Former Student Council Treasurer):
      - Scene: `scenes/portraits/alex_animated_portrait.tscn`
      - Script: `scenes/portraits/alex_animated_portrait.gd`
      - Frames: `Sprites/Alex_half.png` (idle), `Sprites/mouth_animation/Alice/Alex_half  mouth animation 1-5.png` (talking)
    - **Ben** (Chapter 4 - Student):
      - Scene: `scenes/portraits/ben_animated_portrait.tscn`
      - Script: `scenes/portraits/ben_animated_portrait.gd`
      - Frames: `Sprites/Ben_half.png` (idle), `Sprites/mouth_animation/Ben/Ben_half mouth animation 1-5.png` (talking)
    - **Greg** (Chapter 1 - Student, multiple expressions):
      - **Regular Expression**:
        - Scene: `scenes/portraits/greg_animated_portrait.tscn`
        - Script: `scenes/portraits/greg_animated_portrait.gd`
        - Frames: `Sprites/Greg_half.png` (idle), `Sprites/mouth_animation/Greg/Greg_half mouth animation 1-5.png` (talking)
        - Usage: `join Greg (animated) left`
      - **Sad Expression**:
        - Scene: `scenes/portraits/greg_sad_animated_portrait.tscn`
        - Script: `scenes/portraits/greg_sad_animated_portrait.gd`
        - Frames: `Sprites/Greg_sad_half.png` (idle), `Sprites/mouth_animation/Greg_sad/Greg_half sad mouth animation 1-5.png` (talking)
        - Usage: `join Greg (animated_sad) left`
    - **Diwata Laya** (Chapter 2 - Student Council President):
      - Scene: `scenes/portraits/laya_animated_portrait.tscn`
      - Script: `scenes/portraits/laya_animated_portrait.gd`
      - Frames: `Sprites/Laya_half.png` (idle), `Sprites/mouth_animation/Laya/Laya_half mouth animation 1-5.png` (talking)
    - **Ms. Santos** (Chapter 2 - Faculty Advisor):
      - Scene: `scenes/portraits/ms_santos_animated_portrait.tscn`
      - Script: `scenes/portraits/ms_santos_animated_portrait.gd`
      - Frames: `Sprites/MsSantos_half.png` (idle), `Sprites/mouth_animation/MsSantos/MsSantos_half mouth animation 1-5.png` (talking)
    - **Ria** (Chapter 2 - Student Council Treasurer):
      - Scene: `scenes/portraits/ria_animated_portrait.tscn`
      - Script: `scenes/portraits/ria_animated_portrait.gd`
      - Frames: `Sprites/Ria_half.png` (idle), `Sprites/mouth_animation/Ria/Ria_half mouth animation 1-5.png` (talking)
    - **Ryan** (Chapter 2 - Student Council President):
      - Scene: `scenes/portraits/ryan_animated_portrait.tscn`
      - Script: `scenes/portraits/ryan_animated_portrait.gd`
      - Frames: `Sprites/Ryan_half.png` (idle), `Sprites/mouth_animation/Ryan/Ryan_half mouth animation 1-5.png` (talking)
    - **Victor** (Chapter 3 - Art Student):
      - Scene: `scenes/portraits/victor_animated_portrait.tscn`
      - Script: `scenes/portraits/victor_animated_portrait.gd`
      - Frames: `Characters/Victor.png` (idle), `Sprites/mouth_animation/Victor/Victor_half mouth animation 1-5.png` (talking)
  - **Mystery Character ("???)**: Vignette-style character for mysterious/suspenseful scenes
    - Display name: "???"
    - Portrait: Dark silhouette with modulated opacity (Color(0.2, 0.2, 0.2, 0.8))
    - Image: `res://Characters/Mysterious.png`
    - Usage: `join Mystery (vignette) center`
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
2. Choose options 3-6 for chapter quick convert:
   - Option 3: Chapter 2 → transcripts/Chapter_2/
   - Option 4: Chapter 3 → transcripts/Chapter_3/
   - Option 5: Chapter 4 → transcripts/Chapter_4/
   - Option 6: Chapter 5 → transcripts/Chapter_5/

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
- **Organized output** - Chapter conversions save to `transcripts/Chapter_N/` folders
- No external dependencies (Python 3.6+ only)

**Output Format:**
```
================================================================================
DIALOGUE TRANSCRIPT: c2s3
Source: c2s3.dtl
================================================================================

[SCENE: COUNCIL_ROOM]

[Conrad enters]
[Ria enters]

Conrad: We need to talk about what happened.

[EVIDENCE UNLOCKED: threat_note_c2]
[MINIGAME: dialogue_choice_ria_note]
```

### Clue Analyzer Tool

A Python script that analyzes converted dialogue transcripts to suggest potential evidence items and clues based on story content.

**Files:**
- `clue_analyzer.py` - Main analyzer script
- `analyze_clues.bat` - Windows launcher
- `CLUE_ANALYZER_README.md` - Complete documentation

**Usage:**
```bash
# Step 1: Convert chapter to TXT
python dtl_to_txt_converter.py  # Select chapter option

# Step 2: Analyze transcripts
python clue_analyzer.py  # Select same chapter
```

**Features:**
- 🔍 Identifies mentions of 40+ clue-related keywords (objects, locations, suspicious words)
- 💡 Suggests potential evidence items based on dialogue context
- 📊 Shows existing evidence unlocks and minigames
- ✨ Highlights key dialogue moments with high clue density
- 📈 Ranks suggestions by frequency across all scenes

**Output Report:**
```
📊 Summary:
  Files analyzed: 5
  Clue keyword mentions: 47
  Existing evidence items: 4

💡 Suggested Evidence Items (by frequency):
  1. "the note" - mentioned 8 time(s)
  2. "a cloth" - mentioned 5 time(s)
  3. "the receipt" - mentioned 4 time(s)

🔍 Key Moments (Clue-Rich Dialogue):
  • [Conrad] I found a strange note hidden under the desk...
    (Line 145, 3 clue keywords)
```

**Use Cases:**
- Planning new evidence while writing chapters
- Ensuring dialogue-mentioned items are unlocked as evidence
- Balancing evidence distribution across scenes
- Finding gaps in evidence implementation

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

### Alex Animated Portrait Bug
**Fixed:** Alex's animated portrait now displays correctly throughout all dialogue
- Previously showed correct portrait during dialogue but displayed default portrait after dialogue ended
- Root cause: Scene file referenced wrong directory path (`Alice/` instead of `Alex/`)
- Fixed texture resource paths in `scenes/portraits/alex_animated_portrait.tscn`
- Changed from `res://Sprites/mouth_animation/Alice/` to `res://Sprites/mouth_animation/Alex/`
- Portrait now works correctly in Chapter 2 Scene 2 and Chapter 4 Scene 2

### Main Menu Background Music Bug
**Fixed:** Main menu background music now properly starts and stops
- **Issue 1 - Music starts too early:** Background music now only plays after Vosk plugin finishes loading
  - Added `music_started` flag and `_process()` polling in `scripts/main_menu.gd`
  - Music waits for `MinigameManager.vosk_is_loaded` to become true
  - Prevents music from playing during Vosk loading screen
- **Issue 2 - Music continues after loading save:** Background music now stops when loading a save file
  - Added `stop_background_music()` public function to main menu
  - Function called immediately when Continue button is pressed
  - Also called as backup when save successfully loads (in `scripts/save_load_screen.gd`)
  - Music no longer overlaps with gameplay audio after loading

### Platformer Minigame Camera Error
**Fixed:** Platformer minigame camera follow system now works correctly
- Previously tried to access `.offset` property on Node2D (which doesn't exist)
- Error: "Invalid access to property or key 'offset' on a base object of type 'Node2D'"
- Changed to use `.position` property which is correct for Node2D
- Camera now follows player smoothly without errors

### Pause Menu During Minigames
**Fixed:** ESC key now properly opens pause menu during minigames
- Previously minigames captured input before PauseManager could process it
- Changed minigame input handling from `_input()` to `_unhandled_input()`
- Now pause menu has priority while F5 skip still works in minigames
- Fixed in: fill_in_the_blank.gd, DialogueChoice Main.gd, HearAndFill Main.gd, Pronunciation Main.gd

### Maze Minigame Curriculum Integration
**Fixed:** Maze minigame now properly uses curriculum questions based on selected subject
- Previously always showed hardcoded English question
- Added curriculum format conversion in `configure_puzzle()`
- Fixed initialization order - now waits for configuration before starting game
- Randomly selects questions from subject-specific curriculum pool

### Fill-in-the-Blank Subject Variants
**Fixed:** Fill-in-the-blank minigames now support Math/Science subject variants
- Fixed `locker_examination` to use 1-blank format (scene only supports 1 drop zone)
- Updated label logic to handle 2 sentence parts instead of requiring 3
- Subject variant system automatically finds `_math` and `_science` versions
- Math variant: "In the equation y = mx + b, m represents the **[slope]**."

### Animated Portrait System - Character File Locations
**Important:** Dialogic loads character files from `Characters/` folder, NOT `content/characters/`
- The `content/characters/` folder exists but is NOT used by Dialogic at runtime
- Always update character files in `Characters/` folder (e.g., `Characters/Conrad.dch`, `Characters/Mark.dch`)
- For animated portraits to work, character files must have:
  - `export_overrides: {}` (empty dictionary)
  - `scene: "res://scenes/portraits/character_animated_portrait.tscn"` (path to animated portrait scene)
- If `export_overrides` contains an `image` property, it will override the custom scene and animations won't work
- **Troubleshooting**: If animated portraits don't work, check which character file Dialogic is loading by adding debug output in `addons/dialogic/Modules/Character/subsystem_portraits.gd`

**Example Working Configuration:**
```json
"half": {
    "export_overrides": {},  // Must be empty!
    "mirror": false,
    "offset": Vector2(0, 0),
    "scale": 0.8,
    "scene": "res://scenes/portraits/conrad_animated_portrait.tscn"
}
```

**Example Broken Configuration (DON'T DO THIS):**
```json
"half": {
    "export_overrides": {
        "image": "\"res://Sprites/Conrad_half.png\""  // This breaks animations!
    },
    "scene": "res://scenes/portraits/conrad_animated_portrait.tscn"
}
```

### Save/Load Screen Signal Connection Error
**Fixed:** Save/load screen no longer throws "Signal already connected" errors
- Previously `pressed` signals were being connected multiple times (from scene editor or repeat calls)
- Error: "Signal 'pressed' is already connected to given callable"
- Now checks `is_connected()` before attempting to connect signals
- Fixed in `scripts/save_load_screen.gd` for close button and tab buttons
- Prevents duplicate signal connections and related errors

### Save Loading Robustness (Dialogic State Failure Handling)
**Fixed:** Save loading no longer fails completely when Dialogic state is corrupted/incompatible
- Previously would fail with "Failed to load Dialogic state from slot X" and abort the entire load
- Issue occurred when saves were created before code changes (e.g., Vosk disable flag)
- Now uses `push_warning()` instead of `push_error()` and continues loading
- PlayerStats and Evidence data still restored even if Dialogic timeline position is lost
- User may need to restart chapter from main menu but stats/evidence are preserved
- Fixed in `autoload/save_manager.gd` at line 144

### Dialogic Variable Declaration Error
**Fixed:** Timeline error "Invalid named index 'selected_character' for base type Object"
- Variable `selected_character` was used in timeline `c1s1.dtl` but not declared in project settings
- Added `"selected_character": ""` to Dialogic variables section in `project.godot`
- Character selection system now works properly without parse errors

### Chapter 1 Dialogue Location Continuity Error
**Fixed:** Chapter 1 Scene 2 dialogue now correctly references storage room instead of classroom
- Lines 16 and 86 in `content/timelines/Chapter 1/c1s2.dtl` said "went to the classroom"
- Background image shows storage room, not classroom (continuity error)
- Changed both instances to "went to the storage room"
- Story flow now matches visual environment

### Vosk Troubleshooting: Temporary Disable Flag
**Note:** A `DISABLE_VOSK` flag exists in `autoload/minigame_manager.gd` for troubleshooting
- Set to `false` by default (Vosk enabled)
- If Vosk model fails to load, can be set to `true` to test other game features
- When disabled: voice recognition minigames auto-complete after 0.5 seconds
- When disabled: loading screen is skipped, no Vosk initialization occurs
- See `VOSK_DISABLE_INSTRUCTIONS.md` for complete usage guide
- This is a temporary development/testing flag, not a user-facing feature

## Story Structure: The B.C. Card System

The game features an overarching mystery that ties all chapters together through the **B.C. Card** system.

### What are B.C. Cards?

**B.C.** is a mysterious teacher figure who leaves elegant, philosophical cards for the protagonist (Conrad or Celestine) after each solved case. The cards transform the game from a mystery visual novel into a coming-of-age story where the protagonist evolves from Detective → Student → Teacher.

### The 5 Lessons

Each chapter has a corresponding B.C. card with a moral lesson:

1. **Chapter 1 - Truth**: "Evidence and honesty matter. The chain begins."
2. **Chapter 2 - Responsibility**: "Actions have consequences. Every choice echoes forward."
3. **Chapter 3 - Creativity**: "Expression over competition. True art comes from within."
4. **Chapter 4 - Wisdom**: "Knowledge illuminates, but wisdom guides. The eager student learned what the patient teacher already knew."
5. **Chapter 5 - Choice**: "True teaching respects free will. Guide, never control. The chain transforms."

### Key Story Points

**Important Distinctions:**
- B.C. did **NOT** cause any crimes - Greg, Ria, Victor, and Alex made their own choices
- B.C. did **NOT** stage incidents or manipulate students
- B.C. simply observes natural human events and uses them to teach the protagonist
- The cards appear **after** the protagonist solves each case, not before

**Card Progression:**
- **Card 1 (c1s5)**: Mystery - Protagonist is confused but intrigued
- **Card 2 (c2s6)**: Pattern Recognition - "This happened before..."
- **Card 3 (c3s6)**: Understanding - "They're teaching me something"
- **Card 4 (c4s6)**: Revelation - "They knew all along" (found inside returned journal)
- **Chapter 5**: Face-to-face meeting - No card, actual encounter with B.C.

### Evidence Placement Guidelines

B.C. cards should be unlocked in the **final scene** of each chapter (c1s5, c2s6, c3s6, c4s6):

**Trigger placement:**
```
[After case is resolved and consequences delivered]
[Protagonist is alone, reflecting]
if {selected_character} == "celestine":
    Celestine: Another case closed. But something feels incomplete...
    [Celestine notices/finds a card]
    [signal arg="unlock_evidence bc_card_truth_c1"]
    Celestine reads: "Lesson 1: Truth. Evidence and honesty matter. The chain begins. - B.C."
    Celestine: B.C.? Who...?
else:
    Conrad: Another case closed. But something feels incomplete...
    [Conrad notices/finds a card]
    [signal arg="unlock_evidence bc_card_truth_c1"]
    Conrad reads: "Lesson 1: Truth. Evidence and honesty matter. The chain begins. - B.C."
    Conrad: B.C.? Who...?
```

**Evidence ID Format:**
- `bc_card_truth_c1`
- `bc_card_responsibility_c2`
- `bc_card_creativity_c3`
- `bc_card_wisdom_c4`

### Chapter 5 Revelation

Chapter 5 is NOT a crime case - it's the revelation chapter where:
- The protagonist (Conrad or Celestine) creates an **invitation** (not a trap) for B.C.
- B.C. appears **voluntarily** and reveals their identity (Principal Bernardino Cruz)
- B.C. explains their philosophy of teaching through observation
- The protagonist learns the final lesson about choice and free will
- **No B.C. card** this time - instead, the protagonist writes their **own** card (signed "- C"), showing they've become a teacher themselves
- The chain doesn't end, it transforms
- **Both protagonists can experience this climactic chapter** - all scenes support dual protagonist system

### Visual Design Guidelines

**B.C. Card Image Prompts:**
```
An elegant card on aged parchment with beautiful calligraphy reading:
"[LESSON TEXT]" signed "B.C."
Embossed [RELEVANT SYMBOLS] in [METAL COLOR].
Warm lighting, vintage scholarly aesthetic, photorealistic, wise mentor mood.
```

**Core Visual Elements:**
- Material: Aged parchment/cream paper with subtle texture
- Typography: Elegant calligraphy, readable but artistic
- Signature: "B.C." in distinctive stylized initials
- Borders: Subtle embossed symbols relevant to each lesson
- Lighting: Warm, dramatic, philosophical mood lighting
- Colors: Warm sepia/cream tones, gold/silver/bronze accents
- Mood: Wise, timeless, mentor-like, respectful (NOT threatening)
