class_name AudioManagerClass
extends Node

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func _ready() -> void:
	if bgm_player.stream is AudioStreamMP3:
		(bgm_player.stream as AudioStreamMP3).loop = true
	if not bgm_player.playing:
		bgm_player.play()

func play_bgm(stream: AudioStream = null) -> void:
	if stream != null:
		if bgm_player.stream == stream and bgm_player.playing:
			return
		bgm_player.stream = stream
		if bgm_player.stream is AudioStreamMP3:
			(bgm_player.stream as AudioStreamMP3).loop = true
	if not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func set_bgm_volume(volume_linear: float) -> void:
	bgm_player.volume_db = linear_to_db(clampf(volume_linear, 0.0, 1.0))

