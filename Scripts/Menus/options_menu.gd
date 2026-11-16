class_name OptionsMenu
extends Control

const SIGN_NORMAL_COLOR := Color(0.92, 0.86, 0.74, 1)
const SIGN_HOVER_COLOR := Color(1.0, 0.85, 0.2, 1)

const HOVER_SFX: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/madera-boton-1.wav"),
	preload("res://Assets/Audio/SFX/madera-boton-2.wav"),
	preload("res://Assets/Audio/SFX/madera-boton-3.wav"),
]
const PLAY_SFX: AudioStream = preload("res://Assets/Audio/SFX/llaves-mesa.wav")

enum PanelMode {
	NONE,
	OPTIONS,
	CREDITS,
	CONFIRM_EXIT
}

var current_mode: PanelMode = PanelMode.NONE

var bus_master_idx: int = 0
var bus_bgm_idx: int = 1
var bus_sfx_idx: int = 2

@onready var scroll_panel: TextureRect = %ScrollPanel
@onready var title_label: Label = %TitleLabel
@onready var options_list: VBoxContainer = %OptionsList
@onready var credits_list: VBoxContainer = %CreditsList
@onready var confirm_exit_container: VBoxContainer = %ConfirmExitContainer

@onready var slider_master: HSlider = %SliderMaster
@onready var val_master: Label = %ValMaster

@onready var slider_bgm: HSlider = %SliderBGM
@onready var val_bgm: Label = %ValBGM

@onready var slider_sfx: HSlider = %SliderSFX
@onready var val_sfx: Label = %ValSFX

@onready var btn_fullscreen: Button = %BtnFullscreen
@onready var btn_back_from_options: Button = %BtnBackFromOptions

@onready var btn_confirm_exit: Button = %BtnConfirmExit
@onready var btn_cancel_exit: Button = %BtnCancelExit

@onready var sign_jugar: TextureButton = %SignJugar
@onready var sign_continuar: TextureButton = %SignContinuar
@onready var sign_opciones: TextureButton = %SignOpciones
@onready var sign_creditos: TextureButton = %SignCreditos
@onready var sign_salir: TextureButton = %SignSalir

@onready var audio_open: AudioStreamPlayer = %AudioOpen
@onready var audio_close: AudioStreamPlayer = %AudioClose
@onready var endings_label: Label = %EndingsLabel
@onready var new_game_overlay: Control = %NewGameOverlay
@onready var new_game_story_text: RichTextLabel = %NewGameStoryText
@onready var btn_start_adventure: Button = %BtnStartAdventure

func _ready() -> void:
	scroll_panel.visible = false
	current_mode = PanelMode.NONE

	_setup_audio_buses()
	_update_fullscreen_button()
	_update_continue_button()
	_update_endings_label()

	slider_master.value_changed.connect(_on_master_changed)
	slider_bgm.value_changed.connect(_on_bgm_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)
	btn_back_from_options.pressed.connect(close_parchment)

	sign_jugar.pressed.connect(_on_jugar_pressed)
	sign_continuar.pressed.connect(_on_continuar_pressed)
	sign_opciones.pressed.connect(_on_opciones_pressed)
	sign_creditos.pressed.connect(_on_creditos_pressed)
	sign_salir.pressed.connect(_on_salir_pressed)

	btn_confirm_exit.pressed.connect(_on_confirm_exit_pressed)
	btn_cancel_exit.pressed.connect(_on_cancel_exit_pressed)
	btn_start_adventure.pressed.connect(_on_start_adventure_pressed)

	var sign_buttons: Array[TextureButton] = [
		sign_jugar,
		sign_continuar,
		sign_opciones,
		sign_creditos,
		sign_salir,
	]
	for btn in sign_buttons:
		btn.mouse_entered.connect(_on_sign_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_sign_mouse_exited.bind(btn))

func _update_endings_label() -> void:
	if not is_instance_valid(endings_label):
		return
	var count := GameManager.unlocked_endings.size()
	endings_label.visible = count > 0
	if count > 0:
		endings_label.text = "Finales %d/6" % count

func _setup_audio_buses() -> void:
	bus_master_idx = AudioServer.get_bus_index("Master")
	bus_bgm_idx = AudioServer.get_bus_index("BGM")
	bus_sfx_idx = AudioServer.get_bus_index("SFX")

	if bus_master_idx != -1:
		var linear = _get_bus_linear(bus_master_idx)
		slider_master.value = linear
		val_master.text = "%d%%" % int(linear * 100)

	if bus_bgm_idx != -1:
		var linear = _get_bus_linear(bus_bgm_idx)
		slider_bgm.value = linear
		val_bgm.text = "%d%%" % int(linear * 100)

	if bus_sfx_idx != -1:
		var linear = _get_bus_linear(bus_sfx_idx)
		slider_sfx.value = linear
		val_sfx.text = "%d%%" % int(linear * 100)

func _get_bus_linear(bus_idx: int) -> float:
	if AudioServer.is_bus_mute(bus_idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _set_bus_volume(bus_idx: int, linear_val: float) -> void:
	if bus_idx == -1:
		return
	if linear_val <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))

func _on_master_changed(value: float) -> void:
	_set_bus_volume(bus_master_idx, value)
	val_master.text = "%d%%" % int(value * 100)
	GameManager.save_settings()

func _on_bgm_changed(value: float) -> void:
	_set_bus_volume(bus_bgm_idx, value)
	val_bgm.text = "%d%%" % int(value * 100)
	GameManager.save_settings()

func _on_sfx_changed(value: float) -> void:
	_set_bus_volume(bus_sfx_idx, value)
	val_sfx.text = "%d%%" % int(value * 100)
	GameManager.save_settings()

func _is_window_fullscreen() -> bool:
	var mode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _update_fullscreen_button() -> void:
	btn_fullscreen.text = "[ SÍ ]" if _is_window_fullscreen() else "[ NO ]"

func _on_fullscreen_pressed() -> void:
	if _is_window_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_button()
	GameManager.save_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and scroll_panel.visible:
		close_parchment()
		get_viewport().set_input_as_handled()

func _update_continue_button() -> void:
	var has_save := GameManager.has_save()
	sign_continuar.disabled = not has_save
	sign_continuar.modulate = Color.WHITE if has_save else Color(0.55, 0.55, 0.55, 0.7)

func _on_sign_mouse_entered(btn: TextureButton) -> void:
	if btn.disabled:
		return
	var label := btn.get_node_or_null("Label") as Label
	if label:
		label.add_theme_color_override("font_color", SIGN_HOVER_COLOR)
	AudioManager.play_sfx(HOVER_SFX.pick_random())

func _on_sign_mouse_exited(btn: TextureButton) -> void:
	var label := btn.get_node_or_null("Label") as Label
	if label:
		label.add_theme_color_override("font_color", SIGN_NORMAL_COLOR)

func _on_jugar_pressed() -> void:
	AudioManager.play_sfx(PLAY_SFX)
	if scroll_panel.visible:
		close_parchment()
	new_game_story_text.text = (
		"[center][color=#ffd27d][font_size=24]EL REINO DE KOKANI BUENHOMBRE[/font_size][/color]\n\n"
		+ "El recién coronado heredero, el malvado rey [color=#ff6b6b][font_size=20]Kokani Buenhombre[/font_size][/color], "
		+ "ha impuesto [color=#ff9f43]impuestos despiadados[/color] a todos los aventureros como su implacable estrategia para salvar el reino.\n\n"
		+ "Recorrer mazmorras ya no es rentable. Para subsistir —[color=#a3e635]al menos una semana más[/color]—, "
		+ "no te quedó más remedio que aceptar el puesto de [color=#7dd3fc]cobrador de impuestos[/color] en la notaría real.[/center]"
	)
	new_game_overlay.modulate.a = 0.0
	new_game_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(new_game_overlay, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)

func _on_start_adventure_pressed() -> void:
	AudioManager.play_sfx(PLAY_SFX)
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _on_continuar_pressed() -> void:
	if not GameManager.load_game():
		return
	AudioManager.play_sfx(PLAY_SFX)
	if scroll_panel.visible:
		close_parchment()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _on_opciones_pressed() -> void:
	if current_mode == PanelMode.OPTIONS and scroll_panel.visible:
		close_parchment()
	else:
		open_parchment(PanelMode.OPTIONS)

func _on_creditos_pressed() -> void:
	if current_mode == PanelMode.CREDITS and scroll_panel.visible:
		close_parchment()
	else:
		open_parchment(PanelMode.CREDITS)

func _on_salir_pressed() -> void:
	if current_mode == PanelMode.CONFIRM_EXIT and scroll_panel.visible:
		close_parchment()
	else:
		open_parchment(PanelMode.CONFIRM_EXIT)

func _on_confirm_exit_pressed() -> void:
	get_tree().quit()

func _on_cancel_exit_pressed() -> void:
	close_parchment()

func open_parchment(mode: PanelMode) -> void:
	current_mode = mode
	scroll_panel.visible = true
	_update_fullscreen_button()

	options_list.visible = (mode == PanelMode.OPTIONS)
	credits_list.visible = (mode == PanelMode.CREDITS)
	confirm_exit_container.visible = (mode == PanelMode.CONFIRM_EXIT)

	if mode == PanelMode.OPTIONS:
		title_label.text = "AJUSTES"
	elif mode == PanelMode.CREDITS:
		title_label.text = "CRÉDITOS"
	elif mode == PanelMode.CONFIRM_EXIT:
		title_label.text = "¿SALIR?"

	audio_open.play()

func close_parchment() -> void:
	if not scroll_panel.visible:
		return
	scroll_panel.visible = false
	current_mode = PanelMode.NONE
	audio_close.play()
