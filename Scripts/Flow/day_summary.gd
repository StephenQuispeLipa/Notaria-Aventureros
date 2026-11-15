class_name DaySummary
extends Control

const LIBRO_OPEN_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-open.wav")
const LIBRO_CLOSE_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-close.wav")
const TOS_SFX: AudioStream = preload("res://Assets/Audio/SFX/tos.wav")

@onready var left_title: Label = %LeftTitle
@onready var left_text: RichTextLabel = %LeftText
@onready var right_title: Label = %RightTitle
@onready var right_text: RichTextLabel = %RightText

@onready var btn_menu: Button = %BtnMenu
@onready var btn_restart: Button = %BtnRestart
@onready var btn_next_day: Button = %BtnNextDay
@onready var write_audio: AudioStreamPlayer = %WriteAudio

var _typewriter_tween: Tween = null
var _is_typing: bool = false
var _finance_data: Dictionary = {}

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_next_day.pressed.connect(_on_next_day_pressed)

	if write_audio:
		write_audio.finished.connect(_on_write_audio_finished)

	_set_buttons_active(false)

	var prev_money := GameManager.money
	var day := GameManager.current_day
	var arrests := GameManager.arrests_today
	var timed_out := GameManager.last_day_timed_out

	_finance_data = DaySummaryData.calculate_day_finances(prev_money, day, arrests, timed_out)

	var new_money: int = _finance_data["new_money"]
	GameManager.money = new_money
	GameManager.total_earned += int(_finance_data["day_income"])
	GameManager.total_spent += int(_finance_data["day_expenses"])
	GameManager.total_events += int(_finance_data["event_count"])

	var is_game_over: bool = _finance_data["is_game_over"]
	var is_game_win: bool = _finance_data["is_game_win"]

	if is_game_over:
		GameManager.delete_save()
		left_title.text = "FIN DEL JUEGO"
		btn_next_day.visible = false
		btn_restart.visible = true
		btn_restart.text = "REINTENTAR"
	elif is_game_win:
		GameManager.delete_save()
		left_title.text = "¡JUEGO COMPLETADO!"
		btn_next_day.visible = false
		btn_restart.visible = true
		btn_restart.text = "JUGAR DE NUEVO"
	else:
		left_title.text = "BALANCE DÍA %d" % day
		btn_next_day.visible = true
		btn_next_day.text = "DÍA %d ->" % (day + 1)
		btn_restart.visible = false

	right_title.text = "CONSEJOS DEL GREMIO"
	left_text.text = _finance_data["finance_text"]
	right_text.text = DaySummaryData.get_daily_tips(day, is_game_over, is_game_win)

	left_text.visible_ratio = 0.0
	right_text.visible_ratio = 0.0

	AudioManager.play_sfx(LIBRO_OPEN_SFX)
	if _finance_data.get("has_sick_family", false):
		AudioManager.play_sfx(TOS_SFX)

	_start_typewriter()

func _start_typewriter() -> void:
	_is_typing = true
	_set_buttons_active(false)

	if write_audio:
		write_audio.play()

	var left_chars := maxi(left_text.get_total_character_count(), 30)
	var right_chars := maxi(right_text.get_total_character_count(), 30)

	var left_dur := clampf(float(left_chars) * 0.015, 0.8, 2.2)
	var right_dur := clampf(float(right_chars) * 0.015, 0.8, 2.2)

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(left_text, "visible_ratio", 1.0, left_dur)
	_typewriter_tween.tween_interval(0.15)
	_typewriter_tween.tween_property(right_text, "visible_ratio", 1.0, right_dur)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

func _finish_typewriter_instantly() -> void:
	if not _is_typing:
		return
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	_is_typing = false
	if write_audio and write_audio.playing:
		write_audio.stop()
	left_text.visible_ratio = 1.0
	right_text.visible_ratio = 1.0
	_set_buttons_active(true)

func _on_write_audio_finished() -> void:
	if _is_typing and write_audio:
		write_audio.play()

func _set_buttons_active(active: bool) -> void:
	btn_menu.disabled = not active
	btn_restart.disabled = not active
	btn_next_day.disabled = not active
	btn_menu.modulate.a = 1.0 if active else 0.4
	btn_restart.modulate.a = 1.0 if active else 0.4
	btn_next_day.modulate.a = 1.0 if active else 0.4

func _gui_input(event: InputEvent) -> void:
	if _is_typing and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_typewriter_instantly()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_typing and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE)):
		_finish_typewriter_instantly()
		get_viewport().set_input_as_handled()

func _on_next_day_pressed() -> void:
	if _is_typing:
		return
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)
	GameManager.advance_to_next_day()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _on_restart_pressed() -> void:
	if _is_typing:
		return
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _on_menu_pressed() -> void:
	if _is_typing:
		return
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)
	get_tree().change_scene_to_file("res://Scenes/Menus/OptionsMenu.tscn")
