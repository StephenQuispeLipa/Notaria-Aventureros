class_name DaySummary
extends Control

const LIBRO_OPEN_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-open.wav")
const LIBRO_CLOSE_SFX: AudioStream = preload("res://Assets/Audio/SFX/libro-close.wav")
const TOS_SFX: AudioStream = preload("res://Assets/Audio/SFX/tos.wav")
const BAG_OF_COINS_SFX: AudioStream = preload("res://Assets/Audio/SFX/bag-of-coins.wav")
const BOOK_FONT: Font = preload("res://Assets/Art/Fonts/monogram-extended.ttf")

const ITEM_TYPE_NAMES: Dictionary = {
	"escudo": "Escudo",
	"libro": "Libro",
	"pocion": "Botella",
}

const DECORACIONES_SHEET: Texture2D = preload("res://Assets/Art/Items/Decoraciones.png")

const ITEM_ICONS: Dictionary = {
	"escudo": {
		"interior": preload("res://Assets/Art/Items/PlantillaEscudo_Interior.png"),
		"borde": preload("res://Assets/Art/Items/PlantillaEscudo_Borde.png"),
		"deco_pos": Vector2(10.0, 9.0),
	},
	"libro": {
		"interior": preload("res://Assets/Art/Items/PlantillaLibro_Libro_Interior.png"),
		"borde": preload("res://Assets/Art/Items/PlantillaLibro_Libro_Borde.png"),
		"deco_pos": Vector2(11.0, 7.0),
	},
	"pocion": {
		"interior": preload("res://Assets/Art/Items/Pocion_Interior.png"),
		"borde": preload("res://Assets/Art/Items/Pocion_Borde.png"),
		"deco_pos": Vector2(10.0, 14.0),
	},
}

const DECO_CLASSES: Dictionary = {
	"corona": {"label": "Paladín", "cell": Vector2i(0, 0), "color": Color(0.95, 0.89, 0.74, 1.0)},
	"calavera": {"label": "Brujo", "cell": Vector2i(1, 0), "color": Color(0.72, 0.22, 0.24, 1.0)},
	"luna": {"label": "Clérigo", "cell": Vector2i(2, 0), "color": Color(0.26, 0.44, 0.82, 1.0)},
	"ojo": {"label": "Mago", "cell": Vector2i(0, 1), "color": Color(0.36, 0.28, 0.68, 1.0)},
	"hacha": {"label": "Carpintería", "cell": Vector2i(1, 1), "color": Color(0.68, 0.45, 0.28, 1.0)},
	"fuego": {"label": "Alquimia", "cell": Vector2i(2, 1), "color": Color(0.78, 0.45, 0.24, 1.0)},
	"gema": {"label": "Lujo", "cell": Vector2i(0, 2), "color": Color(0.66, 0.34, 0.86, 1.0)},
	"esmeralda": {"label": "Druida", "cell": Vector2i(1, 2), "color": Color(0.24, 0.68, 0.34, 1.0)},
	"moneda": {"label": "Económico", "cell": Vector2i(2, 2), "color": Color(0.86, 0.82, 0.56, 1.0)},
}

@onready var left_title: Label = %LeftTitle
@onready var left_text: RichTextLabel = %LeftText
@onready var stolen_scroll: ScrollContainer = %StolenScroll
@onready var stolen_list: VBoxContainer = %StolenList
@onready var right_title: Label = %RightTitle
@onready var right_text: RichTextLabel = %RightText

@onready var btn_menu: Button = %BtnMenu
@onready var btn_restart: Button = %BtnRestart
@onready var btn_next_day: Button = %BtnNextDay
@onready var write_audio: AudioStreamPlayer = %WriteAudio
@onready var end_story_overlay: Control = %EndStoryOverlay
@onready var end_story_text: RichTextLabel = %EndStoryText
@onready var btn_end_continue: Button = %BtnEndContinue

var _typewriter_tween: Tween = null
var _is_typing: bool = false
var _showing_stolen_page: bool = false
var _finance_data: Dictionary = {}

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_next_day.pressed.connect(_on_next_day_pressed)
	btn_end_continue.pressed.connect(_on_end_continue_pressed)
	end_story_overlay.visible = false
	if write_audio:
		write_audio.finished.connect(_on_write_audio_finished)

	AudioManager.play_sfx(LIBRO_OPEN_SFX)
	if GameManager.dishonor_arrested:
		GameManager.dishonor_arrested = false
		end_story_text.text = _build_dishonor_ending_text()
		end_story_overlay.visible = true
		return
	if GameManager.current_day >= 3:
		_show_stolen_items_page()
	else:
		_show_balance_page()

func _show_stolen_items_page() -> void:
	_showing_stolen_page = true
	_is_typing = false
	left_title.text = "OBJETOS ROBADOS"
	right_title.text = "BOTÍN DE HOY"
	for child in stolen_list.get_children():
		child.queue_free()

	if GameManager.stolen_items.is_empty():
		stolen_scroll.visible = false
		left_text.visible = true
		left_text.text = "No tienes objetos robados en tu bolsa."
		left_text.visible_ratio = 1.0
	else:
		left_text.visible = false
		stolen_scroll.visible = true
		for item in GameManager.stolen_items:
			if not (item is Dictionary):
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)

			var t_id := str(item.get("type_id", "escudo"))
			var deco := str(item.get("deco", "corona"))
			var icon_set: Dictionary = ITEM_ICONS.get(t_id, ITEM_ICONS["escudo"])
			var deco_info: Dictionary = DECO_CLASSES.get(deco, {"label": "Aventurero", "color": Color(0.8, 0.8, 0.8, 1.0)})

			var icon_box := Control.new()
			icon_box.custom_minimum_size = Vector2(32, 32)
			var icon_int := TextureRect.new()
			icon_int.texture = icon_set["interior"]
			icon_int.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_int.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_int.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_int.set_anchors_preset(Control.PRESET_FULL_RECT)
			var tint: Color = deco_info["color"]
			if t_id == "pocion":
				tint.a = 0.85
			icon_int.self_modulate = tint
			icon_box.add_child(icon_int)

			var icon_borde := TextureRect.new()
			icon_borde.texture = icon_set["borde"]
			icon_borde.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_borde.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_borde.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_borde.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_box.add_child(icon_borde)

			var deco_atlas := AtlasTexture.new()
			deco_atlas.atlas = DECORACIONES_SHEET
			var cell: Vector2i = deco_info.get("cell", Vector2i(0, 0))
			deco_atlas.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
			var icon_deco := TextureRect.new()
			icon_deco.texture = deco_atlas
			icon_deco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_deco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_deco.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_deco.size = Vector2(10, 10)
			icon_deco.position = icon_set.get("deco_pos", Vector2(11.0, 10.0))
			icon_box.add_child(icon_deco)
			row.add_child(icon_box)

			var info_vbox := VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.add_theme_constant_override("separation", 0)

			var type_name: String = ITEM_TYPE_NAMES.get(t_id, "Objeto")
			var class_name_str: String = str(deco_info["label"])
			var val := int(item.get("value", 1))
			var lbl := Label.new()
			lbl.text = "%s de %s ($%d)" % [type_name, class_name_str, val]
			lbl.add_theme_font_override("font", BOOK_FONT)
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.22, 0.14, 0.16, 1.0))
			info_vbox.add_child(lbl)

			var actions_row := HBoxContainer.new()
			actions_row.add_theme_constant_override("separation", 12)

			var btn_sell := Button.new()
			btn_sell.text = "[VENDER]"
			btn_sell.flat = true
			btn_sell.focus_mode = Control.FOCUS_NONE
			btn_sell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn_sell.add_theme_font_override("font", BOOK_FONT)
			btn_sell.add_theme_font_size_override("font_size", 16)
			btn_sell.add_theme_color_override("font_color", Color(0.12, 0.45, 0.18, 1.0))
			btn_sell.add_theme_color_override("font_hover_color", Color(0.08, 0.65, 0.2, 1.0))

			var btn_keep := Button.new()
			btn_keep.text = "[MANTENER]"
			btn_keep.flat = true
			btn_keep.focus_mode = Control.FOCUS_NONE
			btn_keep.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn_keep.add_theme_font_override("font", BOOK_FONT)
			btn_keep.add_theme_font_size_override("font_size", 16)
			btn_keep.add_theme_color_override("font_color", Color(0.38, 0.25, 0.15, 1.0))
			btn_keep.add_theme_color_override("font_hover_color", Color(0.6, 0.4, 0.15, 1.0))

			btn_sell.pressed.connect(func():
				GameManager.stolen_value_today += val
				GameManager.stolen_count_today += 1
				GameManager.stolen_items.erase(item)
				GameManager.save_game()
				AudioManager.play_sfx(BAG_OF_COINS_SFX)
				row.queue_free()
				_update_stolen_right_summary()
			)
			btn_keep.pressed.connect(func():
				btn_sell.disabled = true
				btn_keep.disabled = true
				btn_keep.text = "[GUARDADO]"
				_update_stolen_right_summary()
			)

			actions_row.add_child(btn_sell)
			actions_row.add_child(btn_keep)
			info_vbox.add_child(actions_row)
			row.add_child(info_vbox)
			stolen_list.add_child(row)

	_update_stolen_right_summary()
	right_text.visible_ratio = 1.0
	btn_next_day.visible = true
	btn_next_day.text = "VER BALANCE ->"
	btn_restart.visible = false
	_set_buttons_active(true)

func _update_stolen_right_summary() -> void:
	right_text.text = "En tu bolsa: %d obj.\nVendidos hoy: +$%d (%d obj.)\n\nElige [VENDER] para cobrar oro hoy o [MANTENER] para guardarlo para otro día." % [
		GameManager.stolen_items.size(),
		GameManager.stolen_value_today,
		GameManager.stolen_count_today,
	]

func _show_balance_page() -> void:
	_showing_stolen_page = false
	stolen_scroll.visible = false
	left_text.visible = true
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
		btn_next_day.visible = true
		btn_next_day.text = "VER FINAL ->"
		btn_restart.visible = true
		btn_restart.text = "REINTENTAR"
	elif is_game_win:
		GameManager.delete_save()
		left_title.text = "¡JUEGO COMPLETADO!"
		btn_next_day.visible = true
		btn_next_day.text = "CONTINUAR ->"
		btn_restart.visible = false
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
	if _showing_stolen_page:
		AudioManager.play_sfx(LIBRO_OPEN_SFX)
		_show_balance_page()
		return
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)
	if _finance_data.get("is_game_win", false) or _finance_data.get("is_game_over", false):
		end_story_text.text = _build_ending_text(bool(_finance_data.get("is_game_over", false)))
		end_story_overlay.visible = true
		return
	GameManager.advance_to_next_day()
	get_tree().change_scene_to_file("res://Scenes/Desk/Desk_View.tscn")

func _build_ending_text(is_game_over: bool) -> String:
	var has_carpinteria_book := false
	var has_alquimia_book := false
	var has_any_book := false
	var tool_hint := ""
	for item in GameManager.stolen_items:
		var t_id := str(item.get("type_id", ""))
		var deco := str(item.get("deco", ""))
		if t_id == "libro":
			has_any_book = true
			if deco in ["hacha", "espada"]:
				has_carpinteria_book = true
			elif deco == "fuego":
				has_alquimia_book = true
		elif tool_hint.is_empty() and t_id in ["pocion", "escudo"]:
			var item_phrase := "una botella" if t_id == "pocion" else "un escudo"
			if deco == "fuego":
				tool_hint = "Tus hijos no saben qué hacer solo con %s de alquimia." % item_phrase
			elif deco in ["hacha", "espada"]:
				tool_hint = "Tus hijos no saben qué hacer solo con %s de carpintería." % item_phrase

	var title := ""
	var body := ""
	var ending_id := ""
	var hint := ""
	if not is_game_over and has_carpinteria_book and has_alquimia_book:
		ending_id = "5"
		title = "FINAL 5: ALQUIMIA DE MADERA Y ORO"
		body = "Tu hijo compro un monton de madera para practicar carpinteria, pero tu hija, que estaba practicando alquimia, convirtio toda esa madera en oro. Lograron escapar del reino tirano."
	else:
		var high_honor := GameManager.honor >= 30
		var high_money := (not is_game_over) and GameManager.money >= 50
		if not high_honor and high_money:
			ending_id = "1"
			title = "FINAL 1: FORTUNA MANCHADA"
			body = "Poco honor, mucho dinero.\nTe hiciste rico a costa del pueblo."
		elif high_honor and high_money:
			ending_id = "2"
			title = "FINAL 2: INTEGRIDAD INQUEBRANTABLE"
			body = "Mucho honor, mucho dinero.\nLograste lo impensable: pudiste sobrevivir sin cometer ilegalidades."
		elif not high_honor and not high_money:
			ending_id = "3"
			title = "FINAL 3: RUINA Y DESHONRA"
			body = "Poco honor, poco dinero.\nCometiste ilegalidades, pero no sobreviviste al hambre."
		else:
			ending_id = "4"
			title = "FINAL 4: HONRADEZ HUMILDE"
			body = "Mucho honor, poco dinero.\nSobreviviste al hambre, pero apenas alcanzo para tu familia."

		if GameManager.stolen_items.is_empty():
			hint = "Para desbloquear un final, quédate objetos en lugar de venderlos."
		elif has_any_book:
			hint = "Tus hijos no quisieron estudiar los libros que trajiste."
		elif not tool_hint.is_empty():
			hint = tool_hint

	GameManager.unlock_ending(ending_id)
	var hint_block := "\n\n[color=#9fd3ff]%s[/color]" % hint if not hint.is_empty() else ""
	return "[center][color=#ffd27d]%s[/color]\n\n%s%s\n\n[color=#aaaaaa]FIN DE LA HISTORIA[/color][/center]" % [title, body, hint_block]

func _build_dishonor_ending_text() -> String:
	GameManager.unlock_ending("6")
	var title := "FINAL 6: TRAICIÓN A LA CORONA"
	var body := "Tu deshonra colmó la paciencia del reino. La guardia real irrumpió en la notaría y te arrestó por tus crímenes contra la corona.\n\nAhora compartes celda con los mismos aventureros cuya ruina firmaste."
	return "[center][color=#ff6b6b]%s[/color]\n\n%s\n\n[color=#aaaaaa]FIN DE LA HISTORIA[/color][/center]" % [title, body]

func _on_end_continue_pressed() -> void:
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)
	get_tree().change_scene_to_file("res://Scenes/Menus/OptionsMenu.tscn")

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
