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

const NPC_CENTER_X: float = 221.0
const NPC_EXIT_OFFSET: float = 75.0
const BOOK_PEEK_Y: float = 264.0
const BOOK_HOVER_Y: float = 200.0
const ITEM_DEFAULT_POS := Vector2(253.0, 236.0)
const VIEWPORT_SIZE := Vector2(570.0, 320.0)
const LENS_GLASS_RADIUS: float = 34.0
const RUNE_ALPHABET := "abcdefghijklmnopqrstuvwxyz"
const RUNES_PER_ITEM := 10
const MAX_ITEMS_PER_NPC := 3
const MAX_BOOK_PAGES := 4
const BOOK_FONT: Font = preload("res://Assets/Art/Fonts/monogram-extended.ttf")

const ITEM_SLOT_POSITIONS: Dictionary = {
	1: [Vector2(282.0, 222.0)],
	2: [Vector2(224.0, 222.0), Vector2(336.0, 222.0)],
	3: [Vector2(180.0, 222.0), Vector2(282.0, 222.0), Vector2(384.0, 222.0)],
}

const DECORACIONES_SHEET: Texture2D = preload("res://Assets/Art/Items/Decoraciones-Sheet.png")

const ITEM_TEMPLATES: Array[Dictionary] = [
	{
		"id": "escudo",
		"interior": preload("res://Assets/Art/Items/PlantillaEscudo_Interior.png"),
		"borde": preload("res://Assets/Art/Items/PlantillaEscudo_Borde.png"),
		"deco_pos": Vector2(32.0, 28.0),
	},
	{
		"id": "libro",
		"interior": preload("res://Assets/Art/Items/PlantillaLibro_Libro_Interior.png"),
		"borde": preload("res://Assets/Art/Items/PlantillaLibro_Libro_Borde.png"),
		"deco_pos": Vector2(35.0, 22.0),
	},
	{
		"id": "pocion",
		"interior": preload("res://Assets/Art/Items/Pocion_Interior.png"),
		"borde": preload("res://Assets/Art/Items/Pocion_Borde.png"),
		"deco_pos": Vector2(32.0, 42.0),
	},
]

const ITEM_DECORATIONS: Array[Dictionary] = [
	{"name": "corona", "cell": Vector2i(0, 0), "color": Color(0.95, 0.89, 0.74, 1.0)},    # Crema
	{"name": "calavera", "cell": Vector2i(1, 0), "color": Color(0.55, 0.14, 0.16, 1.0)},  # Rojo oscuro
	{"name": "luna", "cell": Vector2i(2, 0), "color": Color(0.16, 0.24, 0.52, 1.0)},      # Azul oscuro
	{"name": "ojo", "cell": Vector2i(0, 1), "color": Color(0.14, 0.14, 0.17, 1.0)},       # Negro
	{"name": "espada", "cell": Vector2i(1, 1), "color": Color(0.52, 0.33, 0.20, 1.0)},    # Café
	{"name": "fuego", "cell": Vector2i(2, 1), "color": Color(0.52, 0.54, 0.58, 1.0)},     # Gris
	{"name": "gema", "cell": Vector2i(0, 2), "color": Color(0.52, 0.22, 0.72, 1.0)},      # Púrpura
	{"name": "esmeralda", "cell": Vector2i(1, 2), "color": Color(0.15, 0.45, 0.22, 1.0)}, # Verde oscuro
	{"name": "moneda", "cell": Vector2i(2, 2), "color": Color(0.78, 0.82, 0.88, 1.0)},    # Plateado
]

const RUNE_FONTS: Array[Font] = [
	preload("res://Assets/Art/Fonts/Silver.ttf"),
	preload("res://Assets/Art/Fonts/monogram-extended.ttf"),
]

const WIZARD_COLORS: Array[Color] = [
	Color(0.32, 0.52, 0.88, 1.0), # Azul real
	Color(0.84, 0.28, 0.28, 1.0), # Rojo carmesí
	Color(0.28, 0.72, 0.42, 1.0), # Verde esmeralda
	Color(0.64, 0.34, 0.82, 1.0), # Morado arcano
	Color(0.88, 0.68, 0.24, 1.0), # Dorado
	Color(0.26, 0.72, 0.78, 1.0), # Turquesa
	Color(0.82, 0.44, 0.68, 1.0), # Magenta suave
	Color(0.76, 0.74, 0.70, 1.0), # Gris claro
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
var _dragging_node: Control = null
var _drag_offset: Vector2 = Vector2.ZERO
var _item_slots: Array[Dictionary] = []
var _runes: Array[Dictionary] = []
var current_book_page: int = 1

@onready var day_progress_label: Label = %DayProgressLabel
@onready var npc_rect: Control = %NPCRect
@onready var npc_interior: TextureRect = %NPCInterior
@onready var item_rect: Control = %ItemRect
@onready var rune_label: Label = %RuneLabel
@onready var magic_lens: TextureRect = %MagicLens

@onready var btn_book: Button = %BtnBook
@onready var btn_cobrar: Button = %BtnCobrar
@onready var btn_arrestar: Button = %BtnArrestar

@onready var vignette_rect: ColorRect = %VignetteRect

@onready var book_overlay: Control = %BookOverlay
@onready var book_backdrop: ColorRect = %BookBackdrop
@onready var btn_close_book: Button = %BtnCloseBook
@onready var btn_prev_page: Button = %BtnPrevPage
@onready var btn_next_page: Button = %BtnNextPage
@onready var book_page_label: Label = %BookPageLabel
@onready var left_page: VBoxContainer = %LeftPage
@onready var right_page: VBoxContainer = %RightPage

func _ready() -> void:
	randomize()
	book_overlay.visible = false
	_set_vignette(Color.WHITE, 0.0)

	btn_book.pressed.connect(_open_book)
	btn_book.mouse_entered.connect(_on_book_mouse_entered)
	btn_book.mouse_exited.connect(_on_book_mouse_exited)
	btn_close_book.pressed.connect(_close_book)
	btn_prev_page.pressed.connect(_on_prev_page_pressed)
	btn_next_page.pressed.connect(_on_next_page_pressed)
	book_backdrop.gui_input.connect(_on_book_backdrop_gui_input)

	btn_cobrar.pressed.connect(_on_cobrar_pressed)
	btn_arrestar.pressed.connect(_on_arrestar_pressed)

	magic_lens.gui_input.connect(_on_draggable_gui_input.bind(magic_lens))

	_setup_items()
	_start_current_day()

func _process(delta: float) -> void:
	if is_day_ending:
		return

	_update_runes(delta)
	_update_magic_lens_shaders()

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
	if not is_day_ending and GameManager.has_save():
		GameManager.day_time_remaining = time_remaining
		GameManager.current_npc_index = current_npc_index
		GameManager.arrests_today = arrests_today
		GameManager.charges_today = charges_today
		GameManager.save_game()

func _input(event: InputEvent) -> void:
	if _dragging_node != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging_node = null

func _on_draggable_gui_input(event: InputEvent, target: Control) -> void:
	if is_day_ending or book_overlay.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_node = target
			_drag_offset = target.global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		elif _dragging_node == target:
			_dragging_node = null
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging_node == target:
		var new_pos := get_global_mouse_position() + _drag_offset
		new_pos = new_pos.clamp(Vector2.ZERO, VIEWPORT_SIZE - target.size)
		target.global_position = new_pos
		_update_magic_lens_shaders()
		get_viewport().set_input_as_handled()

func _update_magic_lens_shaders() -> void:
	var lens_center_global := magic_lens.global_position + magic_lens.size * 0.5
	if not _item_slots.is_empty():
		var first_interior := _item_slots[0]["interior"] as TextureRect
		var item_mat := first_interior.material as ShaderMaterial
		if item_mat:
			item_mat.set_shader_parameter("lens_center_px", lens_center_global)
			item_mat.set_shader_parameter("lens_radius_px", LENS_GLASS_RADIUS)
	var rune_mat := rune_label.material as ShaderMaterial
	if rune_mat:
		rune_mat.set_shader_parameter("lens_center_px", lens_center_global)
		rune_mat.set_shader_parameter("lens_radius_px", LENS_GLASS_RADIUS)

func _setup_items() -> void:
	var parent_node := item_rect.get_parent()
	var base_idx := item_rect.get_index()
	for i in range(MAX_ITEMS_PER_NPC):
		var slot_ctrl := item_rect if i == 0 else (item_rect.duplicate() as Control)
		if i > 0:
			parent_node.add_child(slot_ctrl)
			parent_node.move_child(slot_ctrl, base_idx + i)
		slot_ctrl.gui_input.connect(_on_draggable_gui_input.bind(slot_ctrl))
		var interior := slot_ctrl.get_node("ItemInterior") as TextureRect
		var borde := slot_ctrl.get_node("ItemBorde") as TextureRect
		var deco := slot_ctrl.get_node("ItemDecoracion") as TextureRect
		var first_rune := interior.get_node("RuneLabel") as Label
		first_rune.size = Vector2(14.0, 18.0)
		_item_slots.append({"ctrl": slot_ctrl, "interior": interior, "borde": borde, "deco": deco})
		_runes.append({"label": first_rune, "owner": slot_ctrl, "vel": Vector2.ZERO, "dir": 0})
		for _r in range(RUNES_PER_ITEM - 1):
			var lbl := first_rune.duplicate() as Label
			interior.add_child(lbl)
			_runes.append({"label": lbl, "owner": slot_ctrl, "vel": Vector2.ZERO, "dir": 0})

func _randomize_all_runes() -> void:
	for entry in _runes:
		_reset_rune(entry, true)

func _reset_rune(entry: Dictionary, random_along_axis: bool) -> void:
	var lbl := entry["label"] as Label
	var owner_ctrl := entry["owner"] as Control
	lbl.text = RUNE_ALPHABET[randi() % RUNE_ALPHABET.length()]
	lbl.add_theme_font_override("font", RUNE_FONTS.pick_random())

	var dir := randi() % 4
	var speed := randf_range(54.0, 108.0)
	var item_w := owner_ctrl.size.x
	var item_h := owner_ctrl.size.y
	entry["dir"] = dir

	match dir:
		0: # Izquierda -> Derecha
			entry["vel"] = Vector2(speed, 0.0)
			lbl.position = Vector2(randf_range(-12.0, item_w) if random_along_axis else -12.0, randf_range(0.0, item_h - 16.0))
		1: # Derecha -> Izquierda
			entry["vel"] = Vector2(-speed, 0.0)
			lbl.position = Vector2(randf_range(0.0, item_w + 12.0) if random_along_axis else item_w + 2.0, randf_range(0.0, item_h - 16.0))
		2: # Arriba -> Abajo
			entry["vel"] = Vector2(0.0, speed)
			lbl.position = Vector2(randf_range(2.0, item_w - 14.0), randf_range(-16.0, item_h) if random_along_axis else -16.0)
		3: # Abajo -> Arriba
			entry["vel"] = Vector2(0.0, -speed)
			lbl.position = Vector2(randf_range(2.0, item_w - 14.0), randf_range(0.0, item_h + 16.0) if random_along_axis else item_h + 2.0)

func _update_runes(delta: float) -> void:
	for entry in _runes:
		var owner_ctrl := entry["owner"] as Control
		if not owner_ctrl.visible:
			continue
		var lbl := entry["label"] as Label
		var vel: Vector2 = entry["vel"]
		var dir: int = entry["dir"]
		var item_w := owner_ctrl.size.x
		var item_h := owner_ctrl.size.y
		lbl.position += vel * delta
		if (dir == 0 and lbl.position.x > item_w + 4.0) \
			or (dir == 1 and lbl.position.x < -14.0) \
			or (dir == 2 and lbl.position.y > item_h + 4.0) \
			or (dir == 3 and lbl.position.y < -18.0):
			_reset_rune(entry, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if not is_day_ending:
			if book_overlay.visible:
				_close_book()
			else:
				_open_book()
			get_viewport().set_input_as_handled()
			return
	if book_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_book()
		get_viewport().set_input_as_handled()

func _on_book_mouse_entered() -> void:
	var tween := create_tween()
	tween.tween_property(btn_book, "position:y", BOOK_HOVER_Y, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_book_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(btn_book, "position:y", BOOK_PEEK_Y, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _start_current_day() -> void:
	total_npcs = GameManager.npcs_today_count
	current_npc_index = GameManager.current_npc_index
	arrests_today = GameManager.arrests_today
	charges_today = GameManager.charges_today
	time_remaining = GameManager.day_time_remaining
	current_book_page = clampi(GameManager.book_page, 1, MAX_BOOK_PAGES)
	is_day_ending = false
	_last_displayed_second = ceili(time_remaining)
	_save_timer_accum = 0.0
	_set_vignette(Color.WHITE, 0.0)
	_update_day_progress_label()
	_update_book_page_ui()

	if current_npc_index >= total_npcs:
		_show_day_summary(false)
	elif time_remaining <= 0.0:
		_show_day_summary(true)
	else:
		_spawn_current_npc()

func _update_day_progress_label() -> void:
	var sec := maxi(ceili(time_remaining), 0)
	var mins := floori(sec / 60.0)
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

	npc_interior.modulate = WIZARD_COLORS.pick_random()

	npc_rect.position.x = NPC_CENTER_X
	npc_rect.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "modulate:a", 1.0, 0.25)

	var item_count := randi_range(1, MAX_ITEMS_PER_NPC)
	var slot_positions: Array = ITEM_SLOT_POSITIONS[item_count]
	for i in range(_item_slots.size()):
		var slot := _item_slots[i]
		var ctrl := slot["ctrl"] as Control
		if i < item_count:
			var tpl: Dictionary = ITEM_TEMPLATES.pick_random()
			var deco_info: Dictionary = ITEM_DECORATIONS.pick_random()
			var interior := slot["interior"] as TextureRect
			var borde := slot["borde"] as TextureRect
			var deco := slot["deco"] as TextureRect
			interior.texture = tpl["interior"]
			var item_color: Color = deco_info["color"]
			if tpl["id"] == "libro":
				item_color = item_color.darkened(0.22)
			elif tpl["id"] == "pocion":
				item_color.a = 0.70
			interior.self_modulate = item_color
			borde.texture = tpl["borde"]
			var atlas := AtlasTexture.new()
			atlas.atlas = DECORACIONES_SHEET
			var cell: Vector2i = deco_info["cell"]
			atlas.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
			deco.texture = atlas
			deco.position = tpl["deco_pos"]
			ctrl.visible = true
			ctrl.position = slot_positions[i]
			ctrl.modulate.a = 0.0
			tween.tween_property(ctrl, "modulate:a", 1.0, 0.25)
		else:
			ctrl.visible = false

	_randomize_all_runes()
	_update_magic_lens_shaders()

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
	for slot in _item_slots:
		var ctrl := slot["ctrl"] as Control
		if ctrl.visible:
			tween.tween_property(ctrl, "modulate:a", 0.0, 0.35)
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
	_update_book_page_ui()
	book_overlay.visible = true
	AudioManager.play_sfx(LIBRO_OPEN_SFX)

func _close_book() -> void:
	if not book_overlay.visible:
		return
	book_overlay.visible = false
	GameManager.book_page = current_book_page
	GameManager.save_game()
	AudioManager.play_sfx(LIBRO_CLOSE_SFX)

func _on_prev_page_pressed() -> void:
	if current_book_page <= 1:
		return
	current_book_page -= 1
	GameManager.book_page = current_book_page
	GameManager.save_game()
	_update_book_page_ui()
	AudioManager.play_sfx(LIBRO_OPEN_SFX)

func _get_max_unlocked_book_page() -> int:
	return clampi(1 + ceili(float(GameManager.current_day) / 2.0), 1, MAX_BOOK_PAGES)

func _on_next_page_pressed() -> void:
	if current_book_page >= _get_max_unlocked_book_page():
		return
	current_book_page += 1
	GameManager.book_page = current_book_page
	GameManager.save_game()
	_update_book_page_ui()
	AudioManager.play_sfx(LIBRO_OPEN_SFX)

func _update_book_page_ui() -> void:
	var max_unlocked := _get_max_unlocked_book_page()
	current_book_page = clampi(current_book_page, 1, max_unlocked)
	book_page_label.text = "Página %d/%d" % [current_book_page, MAX_BOOK_PAGES]
	btn_prev_page.disabled = current_book_page <= 1
	btn_next_page.disabled = current_book_page >= max_unlocked

	_clear_container(left_page)
	_clear_container(right_page)

	match current_book_page:
		1:
			_populate_book_glossary_page(left_page)
			_populate_book_categories_page(right_page)
		2:
			_populate_book_day_page(left_page, 1)
			if GameManager.current_day >= 2:
				_populate_book_day_page(right_page, 2)
		3:
			if GameManager.current_day >= 3:
				_populate_book_day_page(left_page, 3)
			if GameManager.current_day >= 4:
				_populate_book_day_page(right_page, 4)
		4:
			if GameManager.current_day >= 5:
				_populate_book_day_page(left_page, 5)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _colored_tag(label_text: String, hex_color: String) -> String:
	return "[color=%s]%s[/color]" % [hex_color, label_text]

func _make_book_rtl(bbcode_text: String = "", font_size: int = 16) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rtl.add_theme_font_override("normal_font", BOOK_FONT)
	rtl.add_theme_font_override("bold_font", BOOK_FONT)
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_font_size_override("bold_font_size", font_size)
	rtl.add_theme_color_override("default_color", Color(0.24, 0.14, 0.10, 1.0))
	if not bbcode_text.is_empty():
		rtl.text = bbcode_text
	return rtl

func _get_deco_atlas(cell: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = DECORACIONES_SHEET
	atlas.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
	return atlas

func _append_book_tokens(rtl: RichTextLabel, tokens: Array) -> void:
	for token in tokens:
		if token is String:
			rtl.append_text(token)
		elif token is Vector2i:
			rtl.add_image(_get_deco_atlas(token), 14, 14, Color.WHITE, INLINE_ALIGNMENT_CENTER)
		elif token is Texture2D:
			rtl.add_image(token, 14, 14, Color.WHITE, INLINE_ALIGNMENT_CENTER)

func _make_deco_icon(cell: Vector2i) -> TextureRect:
	var tex := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DECORACIONES_SHEET
	atlas.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
	tex.texture = atlas
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex.custom_minimum_size = Vector2(16, 16)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex

func _populate_book_glossary_page(page: VBoxContainer) -> void:
	page.add_theme_constant_override("separation", 2)
	var lines: Array[String] = [
		"%s: Obj. paladín" % _colored_tag("Corona", "#9e6b00"),
		"%s: Obj. brujo" % _colored_tag("Calavera", "#5a5a5a"),
		"%s: Obj. clérigo" % _colored_tag("Luna", "#006e9e"),
		"%s: Obj. mago" % _colored_tag("Ojo", "#3b2896"),
		"%s: Obj. guerrero" % _colored_tag("Espada", "#4f5b66"),
		"%s: Obj. alquimia" % _colored_tag("Fuego", "#c44d00"),
		"%s: Obj. de lujo" % _colored_tag("Gema", "#7b1fa2"),
		"%s: Obj. druida" % _colored_tag("Esmeralda", "#157524"),
		"%s: Obj. económico" % _colored_tag("Moneda", "#997a00"),
		"%s: Armas" % _colored_tag("Escudos", "#4f5b66"),
		"Pociones: Consumibles",
		"Libros: Educación",
	]
	page.add_child(_make_book_rtl("\n".join(lines), 16))

func _populate_book_categories_page(page: VBoxContainer) -> void:
	page.add_theme_constant_override("separation", 6)
	var categories: Array[Dictionary] = [
		{"title": "Objetos sagrados:", "cells": [Vector2i(2, 0), Vector2i(0, 0), Vector2i(0, 2)]},
		{"title": "Objetos peligrosos:", "cells": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), Vector2i(0, 1)]},
		{"title": "Objetos valiosos:", "cells": [Vector2i(0, 2), Vector2i(2, 2)]},
		{"title": "Objetos naturistas:", "cells": [Vector2i(1, 2), Vector2i(2, 1)]},
	]
	for cat in categories:
		page.add_child(_make_book_rtl(cat["title"], 16))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for cell in cat["cells"]:
			row.add_child(_make_deco_icon(cell))
		page.add_child(row)

func _populate_book_day_page(page: VBoxContainer, day: int) -> void:
	page.add_theme_constant_override("separation", 6)
	var reward_line := "Pago por arresto: 4-7 monedas"
	if day == GameManager.current_day:
		reward_line = "Pago por arresto hoy: %d monedas" % GameManager.arrest_reward_today

	var rtl := _make_book_rtl("", 16)
	rtl.append_text("[b]DÍA %d[/b]\n%s\n\n" % [day, reward_line])

	var escudo_icon: Texture2D = ITEM_TEMPLATES[0]["borde"]
	var libro_icon: Texture2D = ITEM_TEMPLATES[1]["borde"]
	var pocion_icon: Texture2D = ITEM_TEMPLATES[2]["borde"]
	var magic_tag := _colored_tag("Mágicos", "#8a1be0")
	var magic_sg_tag := _colored_tag("Mágico", "#8a1be0")

	match day:
		1:
			_append_book_tokens(rtl, [
				"Los objetos de [",
				_colored_tag("Paladín ", "#9e6b00"), Vector2i(0, 0), ", ",
				_colored_tag("Druida ", "#157524"), Vector2i(1, 2), ", ",
				_colored_tag("Económicos ", "#997a00"), Vector2i(2, 2),
				"] no pueden pasar, a no ser que sean [Consumibles ", pocion_icon,
				"] o [%s (Lente)]. Todo lo demás, pasa." % magic_tag,
			])
		2:
			_append_book_tokens(rtl, [
				"Prohibidos los objetos peligrosos (",
				Vector2i(1, 1), " ", Vector2i(2, 1), " ", Vector2i(1, 0), " ", Vector2i(0, 1),
				"), salvo [Educación ", libro_icon, "]. Todo lo demás, pasa.",
			])
		3:
			_append_book_tokens(rtl, [
				"Los objetos valiosos (", Vector2i(0, 2), " ", Vector2i(2, 2),
				") solo pasan si son [%s (Lente)]. Los de [" % magic_tag,
				_colored_tag("Clérigo ", "#006e9e"), Vector2i(2, 0), "] siempre pasan.",
			])
		4:
			_append_book_tokens(rtl, [
				"Prohibidas las [", _colored_tag("Armas ", "#4f5b66"), escudo_icon,
				"] y objetos de [", _colored_tag("Brujo ", "#5a5a5a"), Vector2i(1, 0),
				"], excepto si llevan ", Vector2i(2, 1), ". Todo lo demás, pasa.",
			])
		5:
			_append_book_tokens(rtl, [
				"Solo pasan los objetos sagrados (",
				Vector2i(2, 0), " ", Vector2i(0, 0), " ", Vector2i(0, 2),
				") que NO sean [%s (Lente)]. Todo lo demás debe ser arrestado." % magic_sg_tag,
			])

	page.add_child(rtl)

func _on_book_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_book()

func _show_day_summary(timed_out: bool = false) -> void:
	is_day_ending = true
	GameManager.last_day_timed_out = timed_out
	GameManager.arrests_today = arrests_today
	GameManager.charges_today = charges_today
	GameManager.current_npc_index = current_npc_index
	GameManager.save_game()
	get_tree().change_scene_to_file("res://Scenes/Flow/Day_Summary.tscn")
