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
const LENS_GLASS_RADIUS: float = 28.0
const RUNE_ALPHABET := "abcdefghijklmnopqrstuvwxyz"
const RUNES_PER_ITEM := 10
const MAX_ITEMS_PER_NPC := 3
const MAX_BOOK_PAGES := 5

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
	btn_book.mouse_entered.connect(_on_book_mouse_entered)
	btn_book.mouse_exited.connect(_on_book_mouse_exited)
	btn_close_book.pressed.connect(_close_book)
	btn_prev_page.pressed.connect(_on_prev_page_pressed)
	btn_next_page.pressed.connect(_on_next_page_pressed)
	book_backdrop.gui_input.connect(_on_book_backdrop_gui_input)

	btn_cobrar.pressed.connect(_on_cobrar_pressed)
	btn_arrestar.pressed.connect(_on_arrestar_pressed)

	btn_next_day.pressed.connect(_on_next_day_pressed)
	btn_restart_day.pressed.connect(_on_restart_game_pressed)
	btn_back_menu.pressed.connect(_on_back_menu_pressed)

	magic_lens.gui_input.connect(_on_draggable_gui_input.bind(magic_lens))

	_setup_items()
	_start_current_day()

func _process(delta: float) -> void:
	if day_end_overlay.visible or is_day_ending:
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
	if not day_end_overlay.visible and not is_day_ending and GameManager.has_save():
		GameManager.day_time_remaining = time_remaining
		GameManager.current_npc_index = current_npc_index
		GameManager.arrests_today = arrests_today
		GameManager.charges_today = charges_today
		GameManager.save_game()

func _input(event: InputEvent) -> void:
	if _dragging_node != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging_node = null

func _on_draggable_gui_input(event: InputEvent, target: Control) -> void:
	if is_day_ending or day_end_overlay.visible or book_overlay.visible:
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
		if not day_end_overlay.visible and not is_day_ending:
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
	day_end_overlay.visible = false
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
			interior.self_modulate = deco_info["color"]
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

func _on_next_page_pressed() -> void:
	if current_book_page >= MAX_BOOK_PAGES:
		return
	current_book_page += 1
	GameManager.book_page = current_book_page
	GameManager.save_game()
	_update_book_page_ui()
	AudioManager.play_sfx(LIBRO_OPEN_SFX)

func _update_book_page_ui() -> void:
	book_page_label.text = "Página %d/%d" % [current_book_page, MAX_BOOK_PAGES]
	btn_prev_page.disabled = current_book_page <= 1
	btn_next_page.disabled = current_book_page >= MAX_BOOK_PAGES

func _on_book_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_book()

func _show_day_summary(timed_out: bool = false) -> void:
	is_day_ending = true
	var prev_money := GameManager.money
	var salary := floori(GameManagerClass.FIXED_DAILY_SALARY / 2.0) if timed_out else GameManagerClass.FIXED_DAILY_SALARY
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
