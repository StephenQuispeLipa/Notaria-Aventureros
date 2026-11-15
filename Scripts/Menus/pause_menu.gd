class_name PauseMenu
extends CanvasLayer

var bus_master_idx: int = 0
var bus_bgm_idx: int = 1
var bus_sfx_idx: int = 2

@onready var dimmer: ColorRect = $Dimmer
@onready var parchment_center: CenterContainer = $ParchmentCenter
@onready var title_label: Label = %TitleLabel

@onready var btn_menu: BaseButton = $TopRightCorner/BtnMenu

@onready var pause_buttons: VBoxContainer = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/PauseButtons
@onready var options_container: VBoxContainer = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer
@onready var confirm_exit_container: VBoxContainer = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/ConfirmExitContainer

@onready var btn_resume: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/PauseButtons/BtnResume
@onready var btn_options: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/PauseButtons/BtnOptions
@onready var btn_exit: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/PauseButtons/BtnExit

@onready var btn_back_from_options: Button = %BtnBackFromOptions
@onready var btn_confirm_exit: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/ConfirmExitContainer/ConfirmButtonsRow/BtnConfirmExit
@onready var btn_cancel_exit: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/ConfirmExitContainer/ConfirmButtonsRow/BtnCancelExit

@onready var slider_master: HSlider = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/MasterContainer/SliderMaster
@onready var val_master: Label = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/MasterContainer/Header/ValMaster
@onready var slider_bgm: HSlider = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/BGMContainer/SliderBGM
@onready var val_bgm: Label = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/BGMContainer/Header/ValBGM
@onready var slider_sfx: HSlider = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/SFXContainer/SliderSFX
@onready var val_sfx: Label = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/SFXContainer/Header/ValSFX
@onready var btn_fullscreen: Button = $ParchmentCenter/Parchment/ParchmentMargin/VBoxContent/OptionsContainer/FullscreenContainer/BtnFullscreen

@onready var audio_open: AudioStreamPlayer = $AudioOpen
@onready var audio_close: AudioStreamPlayer = $AudioClose

var is_open: bool = false

func _ready() -> void:
	_setup_audio_buses()
	_update_fullscreen_button()

	slider_master.value_changed.connect(_on_master_changed)
	slider_bgm.value_changed.connect(_on_bgm_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)

	btn_menu.pressed.connect(toggle_menu)
	btn_resume.pressed.connect(close_menu)
	btn_options.pressed.connect(_show_options)
	btn_exit.pressed.connect(_show_confirm_exit)

	btn_back_from_options.pressed.connect(_show_pause_buttons)
	btn_confirm_exit.pressed.connect(_on_confirm_exit_pressed)
	btn_cancel_exit.pressed.connect(_show_pause_buttons)

	for btn in [btn_menu, btn_resume, btn_options, btn_exit, btn_back_from_options, btn_confirm_exit, btn_cancel_exit, btn_fullscreen]:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE

	close_menu(false)

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
	if event.is_action_pressed("ui_cancel"):
		if is_open:
			if options_container.visible or confirm_exit_container.visible:
				_show_pause_buttons()
			else:
				close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if is_open:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	is_open = true
	dimmer.visible = true
	parchment_center.visible = true
	_show_pause_buttons()
	get_tree().paused = true
	if audio_open:
		audio_open.play()

func close_menu(play_sound: bool = true) -> void:
	is_open = false
	dimmer.visible = false
	parchment_center.visible = false
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	get_tree().paused = false
	if play_sound and audio_close:
		audio_close.play()

func _show_pause_buttons() -> void:
	title_label.text = "PAUSA"
	pause_buttons.visible = true
	options_container.visible = false
	confirm_exit_container.visible = false

func _show_options() -> void:
	title_label.text = "AJUSTES"
	pause_buttons.visible = false
	options_container.visible = true
	confirm_exit_container.visible = false
	_update_fullscreen_button()

func _show_confirm_exit() -> void:
	title_label.text = "¿SALIR?"
	pause_buttons.visible = false
	options_container.visible = false
	confirm_exit_container.visible = true

func _on_confirm_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/OptionsMenu.tscn")
