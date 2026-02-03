#!/usr/bin/env python3
"""
Dialogic DTL to TXT Converter
Converts Dialogic timeline files (.dtl) to readable text files (.txt)

Usage:
1. Run the script: python dtl_to_txt_converter.py
2. Select a .dtl file using the file picker OR drag and drop a file
3. The converted .txt file will be saved in the same directory
"""

import os
import re
import sys
from pathlib import Path

def clean_dialogic_markup(text):
    """Remove Dialogic markup codes from text"""
    # Remove color tags
    text = re.sub(r'\[color=#[0-9a-fA-F]+\]', '', text)
    text = re.sub(r'\[/color\]', '', text)

    # Remove italics/bold tags but keep the text
    text = re.sub(r'\[i\]', '', text)
    text = re.sub(r'\[/i\]', '', text)
    text = re.sub(r'\[b\]', '', text)
    text = re.sub(r'\[/b\]', '', text)

    # Remove other BBCode tags
    text = re.sub(r'\[/?[^\]]+\]', '', text)

    return text

def parse_dtl_line(line):
    """Parse a single DTL line and return formatted text"""
    line = line.strip()

    # Skip empty lines
    if not line:
        return ""

    # Background changes
    if line.startswith('[background'):
        match = re.search(r'arg="([^"]+)"', line)
        if match:
            bg_path = match.group(1)
            bg_name = os.path.basename(bg_path).replace('.png', '').replace('.jpg', '')
            return f"\n[SCENE: {bg_name.upper()}]\n"
        return ""

    # Character joins
    if line.startswith('join '):
        match = re.search(r'join ([^\s(]+)', line)
        if match:
            char_name = match.group(1).strip('"')
            return f"[{char_name} enters]"
        return ""

    # Character leaves
    if line.startswith('leave '):
        if '--All--' in line:
            return "[Everyone leaves]"
        match = re.search(r'leave ([^\s]+)', line)
        if match:
            char_name = match.group(1).strip('"')
            return f"[{char_name} leaves]"
        return ""

    # Dialogue line (character: text)
    if ':' in line and not line.startswith('['):
        parts = line.split(':', 1)
        if len(parts) == 2:
            character = parts[0].strip().strip('"')
            dialogue = parts[1].strip()
            dialogue = clean_dialogic_markup(dialogue)
            return f"\n{character}: {dialogue}"

    # Signal commands (minigames, evidence, etc.)
    if line.startswith('[signal'):
        match = re.search(r'arg="([^"]+)"', line)
        if match:
            signal_arg = match.group(1)

            if 'start_minigame' in signal_arg:
                game_id = signal_arg.replace('start_minigame ', '')
                return f"\n[MINIGAME: {game_id}]\n"
            elif 'unlock_evidence' in signal_arg:
                evidence_id = signal_arg.replace('unlock_evidence ', '')
                return f"\n[EVIDENCE UNLOCKED: {evidence_id}]\n"
            elif 'show_level_up' in signal_arg or 'check_level_up' in signal_arg:
                return f"\n[LEVEL UP ANIMATION]\n"
            else:
                return f"\n[EVENT: {signal_arg}]\n"
        return ""

    # Choices
    if line.startswith('-'):
        choice_text = line.lstrip('- ').strip()
        choice_text = clean_dialogic_markup(choice_text)
        return f"  → {choice_text}"

    # Labels
    if line.startswith('label '):
        label_name = line.replace('label ', '').strip()
        return f"\n[LABEL: {label_name}]\n"

    # Jumps
    if line.startswith('jump '):
        jump_target = line.replace('jump ', '').strip()
        return f"[JUMP TO: {jump_target}]"

    # Variable sets
    if line.startswith('set {'):
        return f"[{line}]"

    # If/else conditions
    if line.startswith('if ') or line.startswith('elif ') or line.startswith('else'):
        return f"\n{line}"

    # Narrative text (no character name)
    if not line.startswith('[') and ':' not in line:
        cleaned = clean_dialogic_markup(line)
        if cleaned:
            return f"\n{cleaned}"

    return ""

def convert_dtl_to_txt(dtl_path):
    """Convert a DTL file to a readable TXT file"""
    dtl_path = Path(dtl_path)

    if not dtl_path.exists():
        print(f"❌ Error: File not found: {dtl_path}")
        return False

    if dtl_path.suffix != '.dtl':
        print(f"❌ Error: File is not a .dtl file: {dtl_path}")
        return False

    # Create output path
    txt_path = dtl_path.with_suffix('.txt')

    print(f"\n📖 Reading: {dtl_path.name}")

    try:
        with open(dtl_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Parse and format content
        formatted_lines = []
        formatted_lines.append("=" * 80)
        formatted_lines.append(f"DIALOGUE TRANSCRIPT: {dtl_path.stem}")
        formatted_lines.append(f"Source: {dtl_path.name}")
        formatted_lines.append("=" * 80)
        formatted_lines.append("")

        for line in lines:
            parsed = parse_dtl_line(line)
            if parsed:
                formatted_lines.append(parsed)

        # Write to TXT file
        with open(txt_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(formatted_lines))

        print(f"✅ Converted successfully!")
        print(f"📄 Output: {txt_path}")
        print(f"📊 Lines processed: {len(lines)}")

        return True

    except Exception as e:
        print(f"❌ Error converting file: {e}")
        return False

def convert_folder(folder_path):
    """Convert all DTL files in a folder"""
    folder_path = Path(folder_path)

    if not folder_path.exists() or not folder_path.is_dir():
        print(f"❌ Error: Invalid folder: {folder_path}")
        return

    dtl_files = list(folder_path.glob('*.dtl'))

    if not dtl_files:
        print(f"❌ No .dtl files found in: {folder_path}")
        return

    print(f"\n📁 Found {len(dtl_files)} DTL file(s) in folder")
    print(f"📂 Folder: {folder_path}")
    print("-" * 80)

    success_count = 0
    for dtl_file in dtl_files:
        if convert_dtl_to_txt(dtl_file):
            success_count += 1
        print()

    print("=" * 80)
    print(f"✅ Converted {success_count}/{len(dtl_files)} files successfully!")

def main():
    print("\n" + "=" * 80)
    print("  DIALOGIC DTL TO TXT CONVERTER")
    print("  Convert Dialogic timeline files to readable text format")
    print("=" * 80)

    # Check if file/folder was provided as argument (drag & drop)
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])

        if path.is_file() and path.suffix == '.dtl':
            convert_dtl_to_txt(path)
        elif path.is_dir():
            convert_folder(path)
        else:
            print(f"❌ Invalid file or folder: {path}")

        input("\nPress Enter to exit...")
        return

    # Interactive mode
    print("\nOptions:")
    print("  1. Convert a single DTL file")
    print("  2. Convert all DTL files in a folder")
    print("  3. Convert all Chapter 2 files (content/timelines/Chapter 2/)")
    print("  4. Exit")

    choice = input("\nEnter your choice (1-4): ").strip()

    if choice == '1':
        file_path = input("\nEnter the path to the DTL file: ").strip().strip('"')
        convert_dtl_to_txt(file_path)

    elif choice == '2':
        folder_path = input("\nEnter the path to the folder: ").strip().strip('"')
        convert_folder(folder_path)

    elif choice == '3':
        chapter2_path = Path(__file__).parent / "content" / "timelines" / "Chapter 2"
        if chapter2_path.exists():
            convert_folder(chapter2_path)
        else:
            print(f"❌ Chapter 2 folder not found: {chapter2_path}")

    elif choice == '4':
        print("\n👋 Goodbye!")
        return

    else:
        print("\n❌ Invalid choice!")

    input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()
