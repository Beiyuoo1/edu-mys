extends Node

# Quick test script to check if GodotVoskRecognizer is available
# Attach this to a Node and run it

func _ready():
	print("=== VOSK AVAILABILITY TEST ===")

	# Test 1: Can we create the class?
	var test_recognizer = GodotVoskRecognizer.new()
	if test_recognizer != null:
		print("✓ GodotVoskRecognizer class is available")

		# Test 2: What does the globalized path look like?
		var model_path = "res://addons/vosk/models/vosk-model-en-us-0.22"
		var absolute_path = ProjectSettings.globalize_path(model_path)
		print("✓ Model path: ", model_path)
		print("✓ Absolute path: ", absolute_path)

		# Test 3: Check if directory exists
		var dir = DirAccess.open(absolute_path)
		if dir:
			print("✓ Directory accessible at absolute path")
			print("✓ Directory contents:")
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				print("  - ", file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("✗ ERROR: Cannot access directory at:", absolute_path)

		# Test 4: Try to initialize
		print("\nAttempting to initialize Vosk...")
		var success = test_recognizer.initialize(absolute_path, 16000.0)
		if success:
			print("✓ SUCCESS: Vosk initialized!")
		else:
			print("✗ FAILED: Vosk initialization failed")
			print("  This means the C++ library rejected the model path")
			print("  Possible causes:")
			print("  - Missing required model files")
			print("  - Corrupted model files")
			print("  - Incompatible model version")

		test_recognizer.free()
	else:
		print("✗ ERROR: GodotVoskRecognizer class not found!")
		print("  The GDExtension is not loaded properly.")
		print("  Check addons/vosk/vosk_godot.gdextension")

	print("=== TEST COMPLETE ===")
