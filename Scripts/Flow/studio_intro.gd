class_name StudioIntro
extends Control

const NEXT_SCENE := "res://Scenes/Menus/OptionsMenu.tscn"

@onready var center_box: Control = %CenterContainer
@onready var snow_particles: CPUParticles2D = %SnowParticles
@onready var rain_audio: AudioStreamPlayer = %RainAudio

var _finishing: bool = false
var _intro_tween: Tween = null

func _ready() -> void:
	AudioManager.stop_bgm()
	center_box.modulate.a = 0.0
	snow_particles.modulate.a = 0.0
	rain_audio.volume_db = -40.0
	rain_audio.play()

	_intro_tween = create_tween().set_parallel(true)
	_intro_tween.tween_property(rain_audio, "volume_db", -4.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(center_box, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(snow_particles, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)
	_intro_tween.chain().tween_interval(6.6)
	_intro_tween.chain().tween_callback(_finish_intro)

func _unhandled_input(event: InputEvent) -> void:
	if _finishing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_intro()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish_intro()

func _finish_intro() -> void:
	if _finishing:
		return
	_finishing = true
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()

	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(rain_audio, "volume_db", -45.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(center_box, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	fade_out.tween_property(snow_particles, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	await fade_out.finished

	rain_audio.stop()
	AudioManager.play_bgm()
	get_tree().change_scene_to_file(NEXT_SCENE)

