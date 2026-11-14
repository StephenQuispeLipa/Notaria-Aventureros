class_name DeskView
extends Control

const LIBRO_OPEN_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-open.wav")
const LIBRO_CLOSE_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-close.wav")
const CAMPANA_GRANDE_SFX: AudioStream = preload("res://Assets/Audio/SFX/campana-grande.wav")
const CAMPANA_PEQUE_SFX: AudioStream = preload("res://Assets/Audio/SFX/campana-peque.wav")
const BAG_OF_COINS_SFX: AudioStream = preload("res://Assets/Audio/SFX/bag-of-coins.wav")

const VIGNETTE_WHITE := Color(1.0, 1.0, 1.0, 0.9)
const VIGNETTE_RED := Color(0.95, 0.12, 0.12, 0.95)

const NPC_CENTER_X: float = 245.0
const NPC_EXIT_OFFSET: float = 75.0

var total_npcs: int = 4
var current_npc_index: int = 0
var is_transitioning: bool = false

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
@onready var day_end_label: Label = %DayEndLabel
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

	btn_restart_day.pressed.connect(_start_level)
	btn_back_menu.pressed.connect(_on_back_menu_pressed)

	_start_level()

func _unhandled_input(event: InputEvent) -> void:
	if book_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_book()
		get_viewport().set_input_as_handled()

func _start_level() -> void:
	total_npcs = randi_range(4, 5)
	current_npc_index = 0
	day_end_overlay.visible = false
	_set_vignette(Color.WHITE, 0.0)
	_spawn_current_npc()

func _spawn_current_npc() -> void:
	is_transitioning = false
	_set_actions_enabled(true)

	var display_num := current_npc_index + 1
	day_progress_label.text = "Nivel 1 - NPC %d/%d" % [display_num, total_npcs]
	npc_label.text = "[NPC %d\n80x96]" % display_num
	item_label.text = "[Objeto %d\n64x64]" % display_num

	npc_rect.position.x = NPC_CENTER_X
	npc_rect.modulate.a = 0.0
	item_rect.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "modulate:a", 1.0, 0.25)
	tween.tween_property(item_rect, "modulate:a", 1.0, 0.25)

func _on_cobrar_pressed() -> void:
	if is_transitioning:
		return
	AudioManager.play_sfx(CAMPANA_PEQUE_SFX)
	_resolve_npc(NPC_EXIT_OFFSET, VIGNETTE_WHITE)

func _on_arrestar_pressed() -> void:
	if is_transitioning:
		return
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

	current_npc_index += 1
	if current_npc_index < total_npcs:
		_spawn_current_npc()
	else:
		_show_day_end()

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

func _show_day_end() -> void:
	day_end_label.text = "Nivel 1 completado\n(%d/%d NPCs atendidos)" % [total_npcs, total_npcs]
	day_end_overlay.visible = true

func _on_back_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/OptionsMenu.tscn")

