# Vosk Temporary Disable Instructions

## What Was Changed

To allow testing the game without Vosk voice recognition, the following modifications were made to `autoload/minigame_manager.gd`:

### 1. Added Disable Flag (Line ~27)
```gdscript
# ============================================
# TEMPORARY: Set to true to disable Vosk and test other game features
const DISABLE_VOSK = true
# ============================================
```

### 2. Modified `_ready()` Function (Line ~35)
- Skips Vosk loading when `DISABLE_VOSK = true`
- Skips the loading screen entirely
- Game proceeds directly to main menu

### 3. Auto-Complete Voice Recognition Minigames
When `DISABLE_VOSK = true`, these minigames automatically succeed after 0.5 seconds:
- **Dialogue Choice** minigames (voice recognition)
- **Pronunciation** minigames (voice recognition)
- **Hear and Fill** minigames (TTS-based, but disabled for consistency)

## Current Status

✅ **Vosk is DISABLED**
- No loading screen appears
- No voice recognition initialization
- Voice minigames auto-complete successfully
- All other minigames work normally

## How to Re-Enable Vosk

When you fix the Vosk loading issue, simply change one line in `autoload/minigame_manager.gd`:

**Change this:**
```gdscript
const DISABLE_VOSK = true
```

**To this:**
```gdscript
const DISABLE_VOSK = false
```

Then the game will:
- Show the Vosk loading screen on startup
- Initialize voice recognition properly
- Run voice recognition minigames normally

## Testing Checklist

With Vosk disabled, you can now test:
- ✅ Main menu navigation
- ✅ Character selection (Conrad/Celestine)
- ✅ Subject selection (Math/Science/English)
- ✅ Chapter progression (1-5)
- ✅ Non-voice minigames (fill-in-blank, riddles, logic grids, etc.)
- ✅ Evidence system
- ✅ Save/load system
- ✅ Chapter results screens
- ✅ Dialogue and story progression
- ⚠️ Voice recognition minigames (will auto-complete)

## Notes

- Voice recognition minigames will show a console message: `⚠️ Vosk disabled - Auto-completing [minigame type]`
- The game will not hang or crash on voice minigames
- All story progression continues normally
- You can still press F5 to skip any minigame (including the auto-completing voice ones)
