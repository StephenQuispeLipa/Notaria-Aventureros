class_name GameManagerClass
extends Node

const SAVE_PATH := "user://savegame.json"

const STARTING_MONEY := 20
const FIXED_DAILY_SALARY := 15
const MAX_DAYS := 5

var current_day: int = 1
var money: int = STARTING_MONEY
var npcs_today_count: int = 4
var current_npc_index: int = 0
var arrests_today: int = 0
var charges_today: int = 0
var day_time_remaining: float = 60.0

var total_charged: int = 0
var total_arrested: int = 0
var total_earned: int = 0
var total_spent: int = 0
var total_events: int = 0

func get_day_duration(day: int) -> float:
	return 60.0 + 20.0 * float(maxi(day - 1, 0))

func start_new_game() -> void:
	current_day = 1
	money = STARTING_MONEY
	npcs_today_count = randi_range(4, 5)
	current_npc_index = 0
	arrests_today = 0
	charges_today = 0
	day_time_remaining = get_day_duration(current_day)
	total_charged = 0
	total_arrested = 0
	total_earned = 0
	total_spent = 0
	total_events = 0
	save_game()

func advance_to_next_day() -> void:
	current_day += 1
	npcs_today_count += randi_range(1, 2)
	current_npc_index = 0
	arrests_today = 0
	charges_today = 0
	day_time_remaining = get_day_duration(current_day)
	save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"current_day": current_day,
		"money": money,
		"npcs_today_count": npcs_today_count,
		"current_npc_index": current_npc_index,
		"arrests_today": arrests_today,
		"charges_today": charges_today,
		"day_time_remaining": day_time_remaining,
		"total_charged": total_charged,
		"total_arrested": total_arrested,
		"total_earned": total_earned,
		"total_spent": total_spent,
		"total_events": total_events,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return false

	var data := parsed as Dictionary
	current_day = int(data.get("current_day", 1))
	money = int(data.get("money", STARTING_MONEY))
	npcs_today_count = int(data.get("npcs_today_count", 4))
	current_npc_index = int(data.get("current_npc_index", 0))
	arrests_today = int(data.get("arrests_today", 0))
	charges_today = int(data.get("charges_today", 0))
	day_time_remaining = float(data.get("day_time_remaining", get_day_duration(current_day)))
	total_charged = int(data.get("total_charged", 0))
	total_arrested = int(data.get("total_arrested", 0))
	total_earned = int(data.get("total_earned", 0))
	total_spent = int(data.get("total_spent", 0))
	total_events = int(data.get("total_events", 0))
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

