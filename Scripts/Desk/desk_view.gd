class_name DeskView
extends Control

const LIBRO_OPEN_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-open.wav")
const LIBRO_CLOSE_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-close.wav")
const CAMPANA_GRANDE_SFX: AudioStream = preload("res://Assets/Audio/SFX/campana-grande.wav")
const CAMPANA_PEQUE_SFX: AudioStream = preload("res://Assets/Audio/SFX/campana-peque.wav")
const BAG_OF_COINS_SFX: AudioStream = preload("res://Assets/Audio/SFX/bag-of-coins.wav")
const TOS_SFX: AudioStream = preload("res://Assets/Audio/SFX/tos.wav")
const ESCRITURA_SFX: AudioStream = preload("res://Assets/Audio/SFX/escritura.wav")

const VIGNETTE_WHITE := Color(1.0, 1.0, 1.0, 0.9)
const VIGNETTE_RED := Color(0.95, 0.12, 0.12, 0.95)

const NPC_CENTER_X: float = 245.0
const NPC_EXIT_OFFSET: float = 75.0

const FAMILY_MEMBERS: Array[String] = ["Esposa", "Hijo", "Hija"]
const ILLNESS_MIN_COST := 8
const ILLNESS_MAX_COST := 14
const ILLNESS_PROBABILITY := 0.25
const EXTERNAL_EVENTS: Array[Dictionary] = [
	{"name": "Deuda pendiente", "min_cost": 6, "max_cost": 12, "prob": 0.30},
	{"name": "Robo en casa", "min_cost": 5, "max_cost": 10, "prob": 0.30},
]

var total_npcs: int = 4
var current_npc_index: int = 0
var arrests_today: int = 0
var charges_today: int = 0
var time_remaining: float = 60.0
var is_transitioning: bool = false
var is_day_ending: bool = false
var _last_displayed_second: int = -1
var _save_timer_accum: float = 0.0

@onready var day_progress_label: Label = %DayProgressLabel
@onready var npc_rect: ColorRect = %NPCRect
@onready var npc_label: Label = %NPCLabel
@onready var item_rect: ColorRect = %ItemRect
@onready var item_label: Label = %ItemLabel

@onready var btn_book: Button = %BtnBook
@onready var btn_cobrar: Button = %BtnCobrar
@onready var btn_arrestar: Button = %BtnArrestar

@onready var vignette_rect: ColorRect = %VignetteRect

@onready var book_overlay: Control = %BookOverlay
@onready var book_backdrop: ColorRect = %BookBackdrop
@onready var btn_close_book: Button = %BtnCloseBook

@onready var day_end_overlay: Control = %DayEndOverlay
@onready var day_end_title: Label = %DayEndTitle
@onready var day_end_label: RichTextLabel = %DayEndLabel
@onready var btn_next_day: Button = %BtnNextDay
@onready var btn_restart_day: Button = %BtnRestartDay
@onready var btn_back_menu: Button = %BtnBackMenu

func _ready() -> void:
	randomize()
	book_overlay.visible = false
	day_end_overlay.visible = false
	_set_vignette(Color.WHITE, 0.0)

	btn_book.pressed.connect(_open_book)
	btn_close_book.pressed.connect(_close_book)
	book_backdrop.gui_input.connect(_on_book_backdrop_gui_input)

	btn_cobrar.pressed.connect(_on_cobrar_pressed)
	btn_arrestar.pressed.connect(_on_arrestar_pressed)

	btn_next_day.pressed.connect(_on_next_day_pressed)
	btn_restart_day.pressed.connect(_on_restart_game_pressed)
	btn_back_menu.pressed.connect(_on_back_menu_pressed)

	_start_current_day()

func _process(delta: float) -> void:
	if day_end_overlay.visible or is_day_ending:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	GameManager.day_time_remaining = time_remaining

	var sec := ceili(time_remaining)
	if sec != _last_displayed_second:
		_last_displayed_second = sec
		_update_day_progress_label()

	_save_timer_accum += delta
	if _save_timer_accum >= 1.0:
		_save_timer_accum = 0.0
		GameManager.save_game()

	if time_remaining <= 0.0:
		is_day_ending = true
		is_transitioning = true
		_set_actions_enabled(false)
		if book_overlay.visible:
			_close_book()
		_show_day_summary(true)

func _exit_tree() -> void:
	if not day_end_overlay.visible and not is_day_ending and GameManager.has_save():
		GameManager.day_time_remaining = time_remaining
		GameManager.current_npc_index = current_npc_index
		GameManager.arrests_today = arrests_today
		GameManager.charges_today = charges_today
		GameManager.save_game()

func _unhandled_input(event: InputEvent) -> void:
	if book_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_book()
		get_viewport().set_input_as_handled()

func _start_current_day() -> void:
	total_npcs = GameManager.npcs_today_count
	current_npc_index = GameManager.current_npc_index
	arrests_today = GameManager.arrests_today
	charges_today = GameManager.charges_today
	time_remaining = GameManager.day_time_remaining
	is_day_ending = false
	_last_displayed_second = ceili(time_remaining)
	_save_timer_accum = 0.0
	day_end_overlay.visible = false
	_set_vignette(Color.WHITE, 0.0)
	_update_day_progress_label()

	if current_npc_index >= total_npcs:
		_show_day_summary(false)
	elif time_remaining <= 0.0:
		_show_day_summary(true)
	else:
		_spawn_current_npc()

func _update_day_progress_label() -> void:
	var sec := maxi(ceili(time_remaining), 0)
	var mins := sec / 60
	var rem_sec := sec % 60
	var remaining_npcs := maxi(total_npcs - current_npc_index, 0)
	day_progress_label.text = "Día %d/%d  |  %02d:%02d  |  $%d\nTamaño de la fila: %d" % [
		GameManager.current_day,
		GameManagerClass.MAX_DAYS,
		mins,
		rem_sec,
		GameManager.money,
		remaining_npcs,
	]

func _spawn_current_npc() -> void:
	is_transitioning = false
	_set_actions_enabled(true)
	_update_day_progress_label()

	var display_num := current_npc_index + 1
	npc_label.text = "[NPC %d\n80x96]" % display_num
	item_label.text = "[Objeto %d\n64x64]" % display_num

	npc_rect.position.x = NPC_CENTER_X
	npc_rect.modulate.a = 0.0
	item_rect.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "modulate:a", 1.0, 0.25)
	tween.tween_property(item_rect, "modulate:a", 1.0, 0.25)

func _on_cobrar_pressed() -> void:
	if is_transitioning or is_day_ending:
		return
	charges_today += 1
	current_npc_index += 1
	GameManager.charges_today = charges_today
	GameManager.current_npc_index = current_npc_index
	GameManager.total_charged += 1
	GameManager.day_time_remaining = time_remaining
	GameManager.save_game()
	AudioManager.play_sfx(CAMPANA_PEQUE_SFX)
	_resolve_npc(NPC_EXIT_OFFSET, VIGNETTE_WHITE)

func _on_arrestar_pressed() -> void:
	if is_transitioning or is_day_ending:
		return
	arrests_today += 1
	current_npc_index += 1
	GameManager.arrests_today = arrests_today
	GameManager.current_npc_index = current_npc_index
	GameManager.total_arrested += 1
	GameManager.day_time_remaining = time_remaining
	GameManager.save_game()
	AudioManager.play_sfx(CAMPANA_GRANDE_SFX)
	AudioManager.play_sfx(BAG_OF_COINS_SFX)
	_resolve_npc(-NPC_EXIT_OFFSET, VIGNETTE_RED)

func _resolve_npc(exit_offset_x: float, vignette_color: Color) -> void:
	is_transitioning = true
	_set_actions_enabled(false)

	var mat := vignette_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("vignette_color", vignette_color)
		mat.set_shader_parameter("intensity", 0.9)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "position:x", NPC_CENTER_X + exit_offset_x, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(npc_rect, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tween.tween_property(item_rect, "modulate:a", 0.0, 0.35)
	if mat:
		tween.tween_method(_set_vignette_intensity, 0.9, 0.0, 0.65).set_ease(Tween.EASE_IN)

	await tween.finished

	if is_day_ending:
		return

	if current_npc_index < total_npcs:
		_spawn_current_npc()
	else:
		is_day_ending = true
		_show_day_summary(false)

func _set_vignette(color: Color, intensity: float) -> void:
	var mat := vignette_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("vignette_color", color)
		mat.set_shader_parameter("intensity", intensity)

func _set_vignette_intensity(value: float) -> void:
	var mat := vignette_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", value)

func _set_actions_enabled(enabled: bool) -> void:
	btn_cobrar.disabled = not enabled
	btn_arrestar.disabled = not enabled

func _open_book() -> void:
	if book_overlay.visible:
		return
	book_overlay.visible = true
	AudioManager.play_sfx(LIBRO_OPEN_SFX)

func _close_book() -> void:
	if not book_overlay.visible:
		return
	book_overlay.visible = false
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)

func _on_book_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_book()

func _show_day_summary(timed_out: bool = false) -> void:
	is_day_ending = true
	var prev_money := GameManager.money
	var salary := GameManagerClass.FIXED_DAILY_SALARY / 2 if timed_out else GameManagerClass.FIXED_DAILY_SALARY
	var arrest_rate := randi_range(4, 7)
	var arrest_bonus := arrests_today * arrest_rate
	var food_cost := randi_range(10, 16)

	var event_cost := 0
	var event_lines: Array[String] = []
	var has_sick_family := false

	for member in FAMILY_MEMBERS:
		if randf() < ILLNESS_PROBABILITY:
			var cost := randi_range(ILLNESS_MIN_COST, ILLNESS_MAX_COST)
			event_cost += cost
			event_lines.append("[color=#e05555]- Enfermedad (%s): -%d[/color]" % [member, cost])
			GameManager.total_events += 1
			has_sick_family = true

	for ev in EXTERNAL_EVENTS:
		if randf() < float(ev["prob"]):
			var cost := randi_range(int(ev["min_cost"]), int(ev["max_cost"]))
			event_cost += cost
			event_lines.append("[color=#e05555]- %s: -%d[/color]" % [ev["name"], cost])
			GameManager.total_events += 1

	var day_income := salary + arrest_bonus
	var day_expenses := food_cost + event_cost
	var new_money := prev_money + day_income - day_expenses

	GameManager.money = new_money
	GameManager.total_earned += day_income
	GameManager.total_spent += day_expenses

	var salary_line := "[color=#66e066]+ Sueldo de hoy: +%d[/color]" % salary
	if timed_out:
		salary_line = "[color=#66e066]+ Sueldo de hoy (tiempo agotado 50%%): +%d[/color]" % salary

	var summary_lines: Array[String] = [
		"Dinero actual: %d" % prev_money,
		salary_line,
		"[color=#66e066]+ Ingreso extra (arrestos): +%d (%d x %d)[/color]" % [arrest_bonus, arrests_today, arrest_rate],
		"[color=#e05555]- Comida para la familia: -%d[/color]" % food_cost,
	]
	summary_lines.append_array(event_lines)
	summary_lines.append("------------------------------")
	summary_lines.append("Dinero resultante: %d" % maxi(new_money, 0))

	if new_money <= 0:
		GameManager.delete_save()
		day_end_title.text = "FIN DEL JUEGO (Sin dinero)"
		summary_lines.append("")
		summary_lines.append("Días alcanzados: %d/%d | Cobros: %d | Arrestos: %d" % [
			GameManager.current_day,
			GameManagerClass.MAX_DAYS,
			GameManager.total_charged,
			GameManager.total_arrested,
		])
		summary_lines.append("[color=#66e066]Ingresos: +%d[/color] | [color=#e05555]Gastos: -%d[/color] | Eventos: %d" % [
			GameManager.total_earned,
			GameManager.total_spent,
			GameManager.total_events,
		])
		btn_next_day.visible = false
		btn_restart_day.visible = true
		btn_restart_day.text = "REINTENTAR"
	elif GameManager.current_day >= GameManagerClass.MAX_DAYS:
		GameManager.delete_save()
		day_end_title.text = "¡JUEGO COMPLETADO! (Día 5)"
		summary_lines.append("")
		summary_lines.append("=== ESTADÍSTICAS FINALES ===")
		summary_lines.append("Dinero final: %d | Eventos sufridos: %d" % [new_money, GameManager.total_events])
		summary_lines.append("Total cobrados: %d | Total arrestados: %d" % [GameManager.total_charged, GameManager.total_arrested])
		summary_lines.append("[color=#66e066]Ingresos totales: +%d[/color] | [color=#e05555]Gastos totales: -%d[/color]" % [GameManager.total_earned, GameManager.total_spent])
		btn_next_day.visible = false
		btn_restart_day.visible = true
		btn_restart_day.text = "JUGAR DE NUEVO"
	else:
		GameManager.advance_to_next_day()
		day_end_title.text = "RESUMEN DEL DÍA %d" % (GameManager.current_day - 1)
		btn_next_day.visible = true
		btn_next_day.text = "DÍA %d" % GameManager.current_day
		btn_restart_day.visible = false

	day_end_label.text = "\n".join(summary_lines)
	day_end_overlay.visible = true

	AudioManager.play_sfx(ESCRITURA_SFX)
	if has_sick_family:
		AudioManager.play_sfx(TOS_SFX)

func _on_next_day_pressed() -> void:
	_start_current_day()

func _on_restart_game_pressed() -> void:
	GameManager.start_new_game()
	_start_current_day()

func _on_back_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/OptionsMenu.tscn")
