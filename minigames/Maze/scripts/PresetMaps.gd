class_name PresetMaps
extends RefCounted

# Preset maps for the maze minigame
# Legend:
#   '#' = Wall
#   '.' = Floor (walkable)
#   'S' = Start position
#   '1' = Correct answer spot
#   'W' = Wrong answer spots

# Map dimensions: 25 wide x 15 tall (bigger maze)
const MAP_WIDTH = 35
const MAP_HEIGHT = 15

# Bigger maze for single correct answer questions
const MAP_1 = [
	"###################################",
	"#1...W#........#..............WWW1#",
	"#.###WW.####.###.###W##.##.##.###.#",
	"#.#W#.#.#W.....#......#..#..#..W#.#",
	"#...#####.####.######.#...#..#..#.#",
	"#W#..........#......#.#.#.#.#W#.#.#",
	"#.###.#####.#######.#.###.#.#.#.W.#",
	"#W........#.#......S....#.#.#.....#",
	"#########.#.#.#####.###.#.W.#..####",
	"#.........#W#...#.....#......#....#",
	"#.##W##.#.#.###.#####.####.#...#.##",
	"#W#...#.#.....#.#W..#....#....#W.W#",
	"#.#.#.#.#####.#.#.#.#.##.#..###W.W#",
	"#1..#...#W..#.........#....W..WW.1#",
	"###################################",
]

# Get the map (always returns MAP_1 for fill-in-the-blank)
static func get_map() -> Array:
	return MAP_1

# For compatibility
static func get_random_map() -> Array:
	return MAP_1

# Parse a map string array into maze data
# Returns: { "maze": 2D array, "start": Vector2i, "correct_spots": Array[Vector2i], "wrong_spots": Array[Vector2i] }
static func parse_map(map_strings: Array) -> Dictionary:
	var maze: Array = []
	var start_pos := Vector2i(1, 1)
	var correct_spots: Array = []  # Spots for correct answers
	var wrong_spots: Array = []     # Spots for wrong answers

	for y in range(map_strings.size()):
		var row: Array = []
		var line: String = map_strings[y]

		for x in range(line.length()):
			var char = line[x]

			match char:
				'#':
					row.append(0)  # Wall
				'.':
					row.append(1)  # Floor
				'S':
					row.append(1)  # Floor (start position)
					start_pos = Vector2i(x, y)
				'1':
					row.append(1)  # Floor (correct answer spot)
					correct_spots.append(Vector2i(x, y))
				'W':
					row.append(1)  # Floor (wrong answer spot)
					wrong_spots.append(Vector2i(x, y))
				_:
					row.append(0)  # Default to wall

		maze.append(row)

	return {
		"maze": maze,
		"start": start_pos,
		"correct_spots": correct_spots,
		"wrong_spots": wrong_spots,
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT
	}
