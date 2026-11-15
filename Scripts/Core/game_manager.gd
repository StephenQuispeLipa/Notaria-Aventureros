class_name GameManagerClass
extends Node

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"

const STARTING_MONEY := 20
const FIXED_DAILY_SALARY := 15
const MAX_DAYS := 5

var current_day: int = 1
var money: int = STARTING_MONEY
var honor: int = 0
var npcs_today_count: int = 4
var current_npc_index: int = 0
var arrests_today: int = 0
var charges_today: int = 0
var stolen_value_today: int = 0
var stolen_count_today: int = 0
var desk_items: Array = []
var day_time_remaining: float = 60.0
var book_page: int = 1
var arrest_reward_today: int = 5

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
	honor = 0
	npcs_today_count = randi_range(4, 5)
	current_npc_index = 0
	arrests_today = 0
	charges_today = 0
	stolen_value_today = 0
	stolen_count_today = 0
	desk_items = []
	day_time_remaining = get_day_duration(current_day)
	book_page = 1
	arrest_reward_today = randi_range(4, 7)
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
	stolen_value_today = 0
	stolen_count_today = 0
	desk_items = []
	day_time_remaining = get_day_duration(current_day)
	arrest_reward_today = randi_range(4, 7)
	save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"current_day": current_day,
		"money": money,
		"honor": honor,
		"npcs_today_count": npcs_today_count,
		"current_npc_index": current_npc_index,
		"arrests_today": arrests_today,
		"charges_today": charges_today,
		"stolen_value_today": stolen_value_today,
		"stolen_count_today": stolen_count_today,
		"desk_items": desk_items,
		"day_time_remaining": day_time_remaining,
		"book_page": book_page,
		"arrest_reward_today": arrest_reward_today,
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
	honor = clampi(int(data.get("honor", 0)), -100, 100)
	npcs_today_count = int(data.get("npcs_today_count", 4))
	current_npc_index = int(data.get("current_npc_index", 0))
	arrests_today = int(data.get("arrests_today", 0))
	charges_today = int(data.get("charges_today", 0))
	stolen_value_today = int(data.get("stolen_value_today", 0))
	stolen_count_today = int(data.get("stolen_count_today", 0))
	var saved_items: Variant = data.get("desk_items", [])
	desk_items = saved_items if saved_items is Array else []
	day_time_remaining = float(data.get("day_time_remaining", get_day_duration(current_day)))
	book_page = clampi(int(data.get("book_page", 1)), 1, 4)
	arrest_reward_today = int(data.get("arrest_reward_today", randi_range(4, 7)))
	total_charged = int(data.get("total_charged", 0))
	total_arrested = int(data.get("total_arrested", 0))
	total_earned = int(data.get("total_earned", 0))
	total_spent = int(data.get("total_spent", 0))
	total_events = int(data.get("total_events", 0))
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", _get_bus_linear("Master"))
	cfg.set_value("audio", "bgm", _get_bus_linear("BGM"))
	cfg.set_value("audio", "sfx", _get_bus_linear("SFX"))
	var mode := DisplayServer.window_get_mode()
	var is_fs := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	cfg.set_value("display", "fullscreen", is_fs)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_apply_bus_linear("Master", float(cfg.get_value("audio", "master", 1.0)))
	_apply_bus_linear("BGM", float(cfg.get_value("audio", "bgm", 1.0)))
	_apply_bus_linear("SFX", float(cfg.get_value("audio", "sfx", 1.0)))
	var is_fs := bool(cfg.get_value("display", "fullscreen", false))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fs else DisplayServer.WINDOW_MODE_WINDOWED)

func _get_bus_linear(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1 or AudioServer.is_bus_mute(idx):
		return 0.0 if idx != -1 else 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))

func _apply_bus_linear(bus_name: String, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if linear_val <= 0.001:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear_val, 0.0, 1.0)))

