class_name OptionsMenu
extends Control

enum PanelMode {
	NONE,
	OPTIONS,
	CREDITS
}

var current_mode: PanelMode = PanelMode.NONE

# Índices de Audio Buses
var bus_master_idx: int = 0
var bus_bgm_idx: int = 1
var bus_sfx_idx: int = 2

@onready var scroll_panel: TextureRect = %ScrollPanel
@onready var title_label: Label = %TitleLabel
@onready var options_list: VBoxContainer = %OptionsList
@onready var credits_list: VBoxContainer = %CreditsList

# Controles de Opciones
@onready var slider_master: HSlider = %SliderMaster
@onready var val_master: Label = %ValMaster

@onready var slider_bgm: HSlider = %SliderBGM
@onready var val_bgm: Label = %ValBGM

@onready var slider_sfx: HSlider = %SliderSFX
@onready var val_sfx: Label = %ValSFX

@onready var btn_fullscreen: Button = %BtnFullscreen

# Botones de navegación
@onready var sign_jugar: TextureButton = %SignJugar
@onready var sign_continuar: TextureButton = %SignContinuar
@onready var sign_opciones: TextureButton = %SignOpciones
@onready var sign_creditos: TextureButton = %SignCreditos
@onready var sign_salir: TextureButton = %SignSalir

@onready var audio_open: AudioStreamPlayer = %AudioOpen
@onready var audio_close: AudioStreamPlayer = %AudioClose

func _ready() -> void:
	scroll_panel.visible = false
	current_mode = PanelMode.NONE

	_setup_audio_buses()
	_update_fullscreen_button()

	# Conexión de sliders
	slider_master.value_changed.connect(_on_master_changed)
	slider_bgm.value_changed.connect(_on_bgm_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)

	# Conexión de carteles
	sign_jugar.pressed.connect(_on_jugar_pressed)
	sign_continuar.pressed.connect(_on_continuar_pressed)
	sign_opciones.pressed.connect(_on_opciones_pressed)
	sign_creditos.pressed.connect(_on_creditos_pressed)
	sign_salir.pressed.connect(_on_salir_pressed)

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
		# Conversión logarítmica: de escala lineal (0 a 1) a decibeles
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))

func _on_master_changed(value: float) -> void:
	_set_bus_volume(bus_master_idx, value)
	val_master.text = "%d%%" % int(value * 100)

func _on_bgm_changed(value: float) -> void:
	_set_bus_volume(bus_bgm_idx, value)
	val_bgm.text = "%d%%" % int(value * 100)

func _on_sfx_changed(value: float) -> void:
	_set_bus_volume(bus_sfx_idx, value)
	val_sfx.text = "%d%%" % int(value * 100)

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and scroll_panel.visible:
		close_parchment()
		get_viewport().set_input_as_handled()

func _on_jugar_pressed() -> void:
	if scroll_panel.visible:
		close_parchment()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _on_continuar_pressed() -> void:
	if scroll_panel.visible:
		close_parchment()

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
	if scroll_panel.visible:
		close_parchment()
	else:
		get_tree().quit()

func open_parchment(mode: PanelMode) -> void:
	current_mode = mode
	scroll_panel.visible = true
	_update_fullscreen_button()

	if mode == PanelMode.OPTIONS:
		title_label.text = "AJUSTES"
		options_list.visible = true
		credits_list.visible = false
	elif mode == PanelMode.CREDITS:
		title_label.text = "CRÉDITOS"
		options_list.visible = false
		credits_list.visible = true

	audio_open.play()

func close_parchment() -> void:
	if not scroll_panel.visible:
		return
	scroll_panel.visible = false
	current_mode = PanelMode.NONE
	audio_close.play()
