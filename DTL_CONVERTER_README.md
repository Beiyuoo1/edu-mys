# Dialogic DTL to TXT Converter

Converts Dialogic timeline files (`.dtl`) to readable text files (`.txt`) so you can share dialogue scripts with others who don't have the Godot project.

## Features

- Converts Dialogic markup to readable text
- Preserves character names and dialogue
- Shows scene changes, character entrances/exits
- Displays minigame triggers and evidence unlocks
- Supports drag & drop
- Can convert single files or entire folders

## Usage

### Method 1: Interactive Mode (Easiest)

**Windows:**
1. Double-click `convert_dtl.bat`
2. Choose an option from the menu
3. Follow the prompts

**Mac/Linux:**
```bash
python dtl_to_txt_converter.py
```

### Method 2: Drag & Drop

**Windows:**
- Drag a `.dtl` file or folder onto `convert_dtl.bat`

**Mac/Linux:**
```bash
python dtl_to_txt_converter.py path/to/file.dtl
python dtl_to_txt_converter.py path/to/folder
```

### Method 3: Command Line

Convert a single file:
```bash
python dtl_to_txt_converter.py "content/timelines/Chapter 2/c2s0.dtl"
```

Convert all files in a folder:
```bash
python dtl_to_txt_converter.py "content/timelines/Chapter 2"
```

## Output

The converted `.txt` files will be saved in the same location as the source `.dtl` files.

### Example Output:

```
================================================================================
DIALOGUE TRANSCRIPT: c2s0
Source: c2s0.dtl
================================================================================

[SCENE: CLASSROOM]

[Conrad enters]
[Alex enters]

Conrad: Good morning, Alex!

Alex: Hey Conrad! Ready for today's mystery?

  → Yes, let's do this!
  → Not really, but let's go anyway.

[MINIGAME: investigation_basics]

[EVIDENCE UNLOCKED: exam_papers_c1]

[Conrad leaves]
```

## Converting Chapter 2 for Your Friend

Quick option - select option 3 from the menu:
1. Run `convert_dtl.bat` (Windows) or `python dtl_to_txt_converter.py` (Mac/Linux)
2. Press `3` to convert all Chapter 2 files
3. Share the generated `.txt` files from `content/timelines/Chapter 2/`

Or convert manually:
```bash
python dtl_to_txt_converter.py "content/timelines/Chapter 2"
```

## Requirements

- Python 3.6 or higher (usually pre-installed on Mac/Linux)
- No external dependencies required - uses only Python standard library

### Installing Python (Windows)

If you get an error about Python not being found:
1. Download Python from https://www.python.org/downloads/
2. Run the installer
3. ✅ **IMPORTANT:** Check "Add Python to PATH" during installation
4. Click "Install Now"

## Troubleshooting

### "Python is not recognized as an internal or external command"
- You need to install Python and add it to PATH (see above)

### Output files are empty or missing content
- Make sure the `.dtl` file is valid Dialogic format
- Check if the source file has actual dialogue content

### Special characters look weird
- The converter uses UTF-8 encoding, which should handle all characters
- If issues persist, try opening the `.txt` file in a different text editor

## File Format Support

The converter handles these Dialogic elements:

✅ Character dialogue
✅ Scene backgrounds
✅ Character joins/leaves
✅ Choices
✅ Minigame triggers
✅ Evidence unlocks
✅ Labels and jumps
✅ Variables
✅ Conditional statements
✅ Narrative text

❌ BBCode markup (stripped for readability)
❌ Complex animations (shown as simple enter/exit)
❌ Audio/music cues (not displayed)

## Example: Converting Chapter 2

Your friend wants to read Chapter 2 scenes (c2s0 through c2s6):

```bash
# Option 1: Convert all at once
python dtl_to_txt_converter.py "content/timelines/Chapter 2"

# Option 2: Convert individually
python dtl_to_txt_converter.py "content/timelines/Chapter 2/c2s0.dtl"
python dtl_to_txt_converter.py "content/timelines/Chapter 2/c2s1.dtl"
# ... etc
```

Send your friend the generated `.txt` files!

## License

This tool is part of the EduMys project and follows the same license as the main project.
