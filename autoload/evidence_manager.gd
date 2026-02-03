extends Node

signal evidence_unlocked(evidence_id: String)

const SAVE_PATH = "user://evidence.sav"

# Master evidence library
var evidence_definitions = {
	# Chapter 1: Faculty Room A/C Sabotage Mystery
	"exam_papers_c1": {
		"id": "exam_papers_c1",
		"title": "Damaged Exam Papers",
		"description": "Grade 12-A History examination papers ruined by water damage from the faculty room leak. All papers are unreadable.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 1
	},
	"janitor_testimony_c1": {
		"id": "janitor_testimony_c1",
		"title": "Janitor Fred's Statement",
		"description": "Janitor Fred reported that the A/C unit started leaking yesterday evening. It was discovered this morning by the English teacher.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 1
	},
	"cut_tube_c1": {
		"id": "cut_tube_c1",
		"title": "Cut A/C Tube Photo",
		"description": "Principal's photo shows the A/C drainage tube was deliberately cut, not naturally damaged. This was sabotage, not an accident.",
		"image_path": "res://assets/evidence/placeholder_leak.png",
		"chapter": 1
	},
	"wifi_logs_c1": {
		"id": "wifi_logs_c1",
		"title": "Faculty Wi-Fi Logs",
		"description": "Two devices connected to Faculty_Wifi yesterday evening: 'Galaxy_A52' at 8:00 PM and 'Redmi_Note_10' at 9:00 PM. These belong to Ben and Greg.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 1
	},
	"charm_bracelet_c1": {
		"id": "charm_bracelet_c1",
		"title": "Charm Bracelet",
		"description": "A small, worn charm bracelet with distinctive blue, red, and white beads, and a tiny silver cross. Found under the desk near the AC unit in the faculty room. This belonged to Greg's grandmother and is his most treasured possession.",
		"image_path": "res://Pics/Charm.png",
		"chapter": 1
	},

	# Chapter 2: Student Council Fund Theft Mystery
	"empty_lockbox_c2": {
		"id": "empty_lockbox_c2",
		"title": "Empty Lockbox",
		"description": "The Student Council lockbox found completely empty. Twenty thousand pesos meant for the outreach fund - money to help 12 students who needed supplies - was stolen.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 2
	},
	"witness_timeline_c2": {
		"id": "witness_timeline_c2",
		"title": "Witness Timeline",
		"description": "Between 6:30-7:00 PM yesterday: Ms. Santos took a coffee break and may have left her desk drawer unlocked. Ryan was in the hallway near the stairs. Alex entered the faculty room to return documents. All three were present when the theft occurred.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 2
	},
	"threatening_note_c2": {
		"id": "threatening_note_c2",
		"title": "Threatening Note to Ria",
		"description": "Anonymous note left in Ria's locker: 'I know what you did with last year's fund. Resign or I'll expose you.' Written with careful, precise handwriting. The writer knew about Ria's past mistake of forgetting to lock the money box overnight.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 2
	},
	"ryan_budget_draft_c2": {
		"id": "ryan_budget_draft_c2",
		"title": "Ryan's Budget Proposal Draft",
		"description": "Crumpled budget proposal found in the printer reject tray. Contains margin notes: 'If they won't listen, I'll have to make them see reason.' The handwriting matches the threatening note exactly - same loops, same angles. This proves Ryan wrote the threat to Ria.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 2
	},
	"recovered_money_c2": {
		"id": "recovered_money_c2",
		"title": "Recovered Fund Money",
		"description": "Twenty thousand pesos found hidden in a gym bag behind equipment racks in the sports storage room. All the money is accounted for. Ryan planned to 'discover' it later to look like a hero and prove the council needed better security systems.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 2
	},

	# Chapter 3: Broken Sculpture Mystery
	"broken_sculpture_note_c3": {
		"id": "broken_sculpture_note_c3",
		"title": "Broken Sculpture & Note",
		"description": "Mia's award-winning sculpture 'The Reader' found completely shattered. A threatening note was left at the scene: 'Not everyone deserves to shine.' The destruction was deliberate and personal.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 3
	},
	"paint_cloth_c3": {
		"id": "paint_cloth_c3",
		"title": "Paint-Stained Cloth",
		"description": "Small piece of paint-stained fabric found among the debris at the crime scene. The cloth has various paint colors and appears to be from an art student's supplies.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 3
	},
	"victor_sketchbook_c3": {
		"id": "victor_sketchbook_c3",
		"title": "Victor's Sketchbook",
		"description": "Victor Lim's personal sketchbook filled with technical studies. Later pages contain dark, angry sketches including violent imagery. One page shows Mia's sculpture with harsh X marks drawn over it, revealing Victor's resentment.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 3
	},
	"art_store_receipt_c3": {
		"id": "art_store_receipt_c3",
		"title": "Art Store Receipt",
		"description": "Receipt from art supply store dated the night of the crime, time stamped 8:47 PM. Found in Victor's sketchbook. This proves Victor lied about being home all night - he was out near the school.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 3
	},
	"inventory_tag_cloth_c3": {
		"id": "inventory_tag_cloth_c3",
		"title": "Inventory-Tagged Cloth",
		"description": "The paint cloth found at the scene has an inventory tag number 14-C. Ms. Reyes' records confirm this corresponds to supplies assigned to Victor Lim's cabinet. Physical evidence directly linking Victor to the crime scene.",
		"image_path": "res://assets/evidence/placeholder_document.png",
		"chapter": 3
	}
}

# Player's collected evidence
var collected_evidence: Array = []

func _ready():
	# Evidence is now loaded per-save-slot by SaveManager
	# Delete old global evidence file if it exists (migration)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Migrated: Deleted old global evidence file, evidence is now saved per-slot")

func unlock_evidence(evidence_id: String):
	if not evidence_definitions.has(evidence_id):
		push_error("Unknown evidence ID: ", evidence_id)
		return

	if not collected_evidence.has(evidence_id):
		collected_evidence.append(evidence_id)
		# Don't save to global file - evidence is now saved per-slot by SaveManager
		evidence_unlocked.emit(evidence_id)
		print("Evidence unlocked: ", evidence_definitions[evidence_id]["title"])

func is_unlocked(evidence_id: String) -> bool:
	return collected_evidence.has(evidence_id)

func get_evidence_by_chapter(chapter: int) -> Array:
	var chapter_evidence = []
	for id in collected_evidence:
		if evidence_definitions.has(id):
			var evidence_chapter = evidence_definitions[id]["chapter"]
			# Show all evidence collected up to and including the given chapter
			if evidence_chapter <= chapter:
				chapter_evidence.append(evidence_definitions[id])

	# Sort by collection order (chronological)
	return chapter_evidence

## DEPRECATED: Evidence is now saved per-slot by SaveManager
## This function is kept for backwards compatibility but should not be used
func save_evidence():
	push_warning("save_evidence() is deprecated - evidence is now saved per-slot by SaveManager")
	# Don't save to global file anymore

## DEPRECATED: Evidence is now loaded per-slot by SaveManager
## This function is kept for backwards compatibility but should not be used
func load_evidence():
	push_warning("load_evidence() is deprecated - evidence is now loaded per-slot by SaveManager")
	# Don't load from global file anymore

func reset_evidence():
	collected_evidence = []
	# Evidence is now managed per-slot by SaveManager, no need to save globally
