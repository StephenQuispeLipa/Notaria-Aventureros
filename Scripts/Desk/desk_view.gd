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
const BOOK_PEEK_Y: float = 276.0
const BOOK_HOVER_Y: float = 248.0
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
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _dragging_item_entry: Dictionary = {}
var _desk_items: Array[Dictionary] = []
var _current_npc_items: Array[Dictionary] = []
var _selected_item: Dictionary = {}
var _runes: Array[Dictionary] = []
var _item_lens_shader_mat: ShaderMaterial = null
var _rune_mask_shader_mat: ShaderMaterial = null
var _vignette_tween: Tween = null
var current_book_page: int = 1

@onready var day_progress_label: Label = %DayProgressLabel
@onready var npc_rect: Control = %NPCRect
@onready var npc_interior: TextureRect = %NPCInterior
@onready var item_rect: Control = %ItemRect
@onready var rune_label: Label = %RuneLabel
@onready var magic_lens: TextureRect = %MagicLens
@onready var item_action_popup: VBoxContainer = %ItemActionPopup
@onready var btn_confiscar: Button = %BtnConfiscar
@onready var btn_robar: Button = %BtnRobar

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

	btn_confiscar.pressed.connect(_on_confiscar_pressed)
	btn_robar.pressed.connect(_on_robar_pressed)

	magic_lens.gui_input.connect(_on_draggable_gui_input.bind(magic_lens, {}))

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
		_sync_desk_items_to_save()
		GameManager.save_game()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if item_action_popup.visible:
			var click_pos := get_global_mouse_position()
			if not item_action_popup.get_global_rect().has_point(click_pos):
				_hide_item_action_popup()

func _on_draggable_gui_input(event: InputEvent, target: Control, item_entry: Dictionary) -> void:
	if is_day_ending or day_end_overlay.visible or book_overlay.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_hide_item_action_popup()
			_dragging_node = target
			_dragging_item_entry = item_entry
			_drag_start_mouse = get_global_mouse_position()
			_drag_moved = false
			_drag_offset = target.global_position - _drag_start_mouse
			get_viewport().set_input_as_handled()
		elif _dragging_node == target:
			var was_quick_click := not _drag_moved and not item_entry.is_empty()
			_dragging_node = null
			_dragging_item_entry = {}
			if was_quick_click:
				_open_item_action_popup(item_entry, target)
			else:
				_sync_desk_items_to_save()
				GameManager.save_game()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging_node == target:
		if not _drag_moved and get_global_mouse_position().distance_to(_drag_start_mouse) > 5.0:
			_drag_moved = true
		if _drag_moved:
			var new_pos := get_global_mouse_position() + _drag_offset
			var max_bounds := VIEWPORT_SIZE if target == magic_lens else Vector2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y + 16.0)
			new_pos = new_pos.clamp(Vector2.ZERO, max_bounds - target.size)
			target.global_position = new_pos
			_update_magic_lens_shaders()
		get_viewport().set_input_as_handled()

func _update_magic_lens_shaders() -> void:
	var lens_center_global := magic_lens.global_position + magic_lens.size * 0.5
	if _item_lens_shader_mat:
		_item_lens_shader_mat.set_shader_parameter("lens_center_px", lens_center_global)
		_item_lens_shader_mat.set_shader_parameter("lens_radius_px", LENS_GLASS_RADIUS)
	if _rune_mask_shader_mat:
		_rune_mask_shader_mat.set_shader_parameter("lens_center_px", lens_center_global)
		_rune_mask_shader_mat.set_shader_parameter("lens_radius_px", LENS_GLASS_RADIUS)

func _setup_items() -> void:
	var template_interior := item_rect.get_node("ItemInterior") as TextureRect
	_item_lens_shader_mat = template_interior.material as ShaderMaterial
	_rune_mask_shader_mat = rune_label.material as ShaderMaterial
	item_rect.visible = false
	item_action_popup.visible = false

func _clear_all_desk_items() -> void:
	_hide_item_action_popup()
	for entry in _desk_items:
		var ctrl := entry["ctrl"] as Control
		if is_instance_valid(ctrl):
			ctrl.queue_free()
	_desk_items.clear()
	_current_npc_items.clear()
	_runes.clear()

func _sync_desk_items_to_save() -> void:
	var arr: Array = []
	for entry in _desk_items:
		var ctrl := entry["ctrl"] as Control
		if not is_instance_valid(ctrl) or entry.get("removing", false):
			continue
		arr.append({
			"type_id": entry["type_id"],
			"deco": entry["deco"],
			"is_magic": entry["is_magic"],
			"x": ctrl.position.x,
			"y": ctrl.position.y,
			"from_current_npc": entry in _current_npc_items,
		})
	GameManager.desk_items = arr

func _find_template_by_id(type_id: String) -> Dictionary:
	for tpl in ITEM_TEMPLATES:
		if tpl["id"] == type_id:
			return tpl
	return ITEM_TEMPLATES[0]

func _find_deco_by_name(deco_name: String) -> Dictionary:
	for d in ITEM_DECORATIONS:
		if d["name"] == deco_name:
			return d
	return ITEM_DECORATIONS[0]

func _spawn_desk_item(type_id: String, deco_name: String, is_magic: bool, pos: Vector2, fade_in: bool = true) -> Dictionary:
	var ctrl := item_rect.duplicate() as Control
	var parent_node := item_rect.get_parent()
	parent_node.add_child(ctrl)
	parent_node.move_child(ctrl, magic_lens.get_index())

	var tpl := _find_template_by_id(type_id)
	var deco_info := _find_deco_by_name(deco_name)
	var interior := ctrl.get_node("ItemInterior") as TextureRect
	var borde := ctrl.get_node("ItemBorde") as TextureRect
	var deco := ctrl.get_node("ItemDecoracion") as TextureRect
	var first_rune := interior.get_node("RuneLabel") as Label

	interior.texture = tpl["interior"]
	var item_color: Color = deco_info["color"]
	if type_id == "libro":
		item_color = item_color.darkened(0.22)
	elif type_id == "pocion":
		item_color.a = 0.70
	interior.self_modulate = item_color
	borde.texture = tpl["borde"]

	var atlas := AtlasTexture.new()
	atlas.atlas = DECORACIONES_SHEET
	var cell: Vector2i = deco_info["cell"]
	atlas.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
	deco.texture = atlas
	deco.position = tpl["deco_pos"]

	if is_magic:
		interior.material = _item_lens_shader_mat
		deco.material = _item_lens_shader_mat
		first_rune.visible = true
		first_rune.size = Vector2(14.0, 18.0)
	else:
		interior.material = null
		deco.material = null
		first_rune.visible = false

	ctrl.position = pos
	ctrl.visible = true
	if fade_in:
		ctrl.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(ctrl, "modulate:a", 1.0, 0.25)

	var entry := {
		"ctrl": ctrl,
		"type_id": type_id,
		"deco": deco_name,
		"is_magic": is_magic,
		"removing": false,
	}
	ctrl.gui_input.connect(_on_draggable_gui_input.bind(ctrl, entry))
	_desk_items.append(entry)

	if is_magic:
		var r1 := {"label": first_rune, "owner": ctrl, "vel": Vector2.ZERO, "dir": 0}
		_runes.append(r1)
		_reset_rune(r1, true)
		for _r in range(RUNES_PER_ITEM - 1):
			var lbl := first_rune.duplicate() as Label
			interior.add_child(lbl)
			var r_entry := {"label": lbl, "owner": ctrl, "vel": Vector2.ZERO, "dir": 0}
			_runes.append(r_entry)
			_reset_rune(r_entry, true)

	return entry

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
	if get_tree().paused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and _dragging_node != null:
			_dragging_node = null
			_dragging_item_entry = {}
			_sync_desk_items_to_save()
			GameManager.save_game()
			return
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
	magic_lens.visible = GameManager.current_day >= 2
	_hide_item_action_popup()
	_clear_all_desk_items()

	for d in GameManager.desk_items:
		if d is Dictionary:
			var pos := Vector2(float(d.get("x", 160.0)), float(d.get("y", 190.0)))
			var entry := _spawn_desk_item(str(d.get("type_id", "libro")), str(d.get("deco", "corona")), bool(d.get("is_magic", false)), pos, false)
			if bool(d.get("from_current_npc", false)):
				_current_npc_items.append(entry)

	_update_day_progress_label()
	_update_book_page_ui()

	if current_npc_index >= total_npcs:
		_show_day_summary(false)
	elif time_remaining <= 0.0:
		_show_day_summary(true)
	elif _current_npc_items.is_empty():
		_spawn_current_npc()
	else:
		is_transitioning = false
		_set_actions_enabled(true)
		npc_interior.modulate = WIZARD_COLORS.pick_random()
		npc_rect.position.x = NPC_CENTER_X
		npc_rect.modulate.a = 1.0
		_update_magic_lens_shaders()

func _update_day_progress_label() -> void:
	var sec := maxi(ceili(time_remaining), 0)
	var mins := floori(sec / 60.0)
	var rem_sec := sec % 60
	var remaining_npcs := maxi(total_npcs - current_npc_index, 0)
	day_progress_label.text = "Día %d/%d  |  %02d:%02d  |  $%d\nTamaño de la fila: %d  |  Honor: %d" % [
		GameManager.current_day,
		GameManagerClass.MAX_DAYS,
		mins,
		rem_sec,
		GameManager.money,
		remaining_npcs,
		GameManager.honor,
	]

func _spawn_current_npc() -> void:
	is_transitioning = false
	_set_actions_enabled(true)
	_hide_item_action_popup()
	_current_npc_items.clear()
	_update_day_progress_label()

	npc_interior.modulate = WIZARD_COLORS.pick_random()

	npc_rect.position.x = NPC_CENTER_X
	npc_rect.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "modulate:a", 1.0, 0.25)

	var item_count := randi_range(1, MAX_ITEMS_PER_NPC)
	var slot_positions: Array = ITEM_SLOT_POSITIONS[item_count]
	for i in range(item_count):
		var tpl: Dictionary = ITEM_TEMPLATES.pick_random()
		var deco_info: Dictionary = ITEM_DECORATIONS.pick_random()
		var is_magic := (GameManager.current_day >= 2) and (randf() < 0.45)
		var entry := _spawn_desk_item(str(tpl["id"]), str(deco_info["name"]), is_magic, slot_positions[i], true)
		_current_npc_items.append(entry)

	_sync_desk_items_to_save()
	_update_magic_lens_shaders()
	GameManager.save_game()

func _on_cobrar_pressed() -> void:
	if is_transitioning or is_day_ending:
		return
	var has_prohibited := _has_prohibited_npc_item()
	var honor_delta := -10 if has_prohibited else 5
	charges_today += 1
	current_npc_index += 1
	GameManager.charges_today = charges_today
	GameManager.current_npc_index = current_npc_index
	GameManager.total_charged += 1
	GameManager.day_time_remaining = time_remaining
	_apply_honor_change(honor_delta, false)
	_resolve_npc(NPC_EXIT_OFFSET, true)

func _on_arrestar_pressed() -> void:
	if is_transitioning or is_day_ending:
		return
	var has_prohibited := _has_prohibited_npc_item()
	var honor_delta := 8 if has_prohibited else -12
	arrests_today += 1
	current_npc_index += 1
	GameManager.arrests_today = arrests_today
	GameManager.current_npc_index = current_npc_index
	GameManager.total_arrested += 1
	GameManager.day_time_remaining = time_remaining
	_apply_honor_change(honor_delta, true)
	GameManager.save_game()
	_resolve_npc(-NPC_EXIT_OFFSET, false)

func _resolve_npc(exit_offset_x: float, clear_npc_items: bool) -> void:
	is_transitioning = true
	_set_actions_enabled(false)
	_hide_item_action_popup()

	var items_to_free: Array[Control] = []
	if clear_npc_items:
		for entry in _current_npc_items:
			_desk_items.erase(entry)
			var ctrl := entry.get("ctrl") as Control
			if is_instance_valid(ctrl):
				ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				items_to_free.append(ctrl)
				for i in range(_runes.size() - 1, -1, -1):
					if _runes[i].get("owner") == ctrl:
						_runes.remove_at(i)
		_current_npc_items.clear()
		_sync_desk_items_to_save()
	GameManager.save_game()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(npc_rect, "position:x", NPC_CENTER_X + exit_offset_x, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(npc_rect, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	for ctrl in items_to_free:
		tween.tween_property(ctrl, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)

	await tween.finished

	for ctrl in items_to_free:
		if is_instance_valid(ctrl):
			ctrl.queue_free()

	if is_day_ending:
		return

	if current_npc_index < total_npcs:
		_spawn_current_npc()
	else:
		is_day_ending = true
		_show_day_summary(false)

func _open_item_action_popup(entry: Dictionary, ctrl: Control) -> void:
	if is_day_ending:
		return
	var click_pos := get_global_mouse_position()
	_selected_item = entry
	btn_robar.visible = GameManager.current_day >= 3
	item_action_popup.visible = true
	await get_tree().process_frame
	if not is_instance_valid(ctrl) or not is_instance_valid(item_action_popup) or is_day_ending:
		_hide_item_action_popup()
		return
	var popup_size := item_action_popup.size
	var target_pos := Vector2(
		click_pos.x - popup_size.x * 0.5,
		click_pos.y - popup_size.y - 2.0
	)
	target_pos.x = clampf(target_pos.x, 4.0, VIEWPORT_SIZE.x - popup_size.x - 4.0)
	target_pos.y = clampf(target_pos.y, 4.0, VIEWPORT_SIZE.y - popup_size.y - 4.0)
	item_action_popup.position = target_pos

func _hide_item_action_popup() -> void:
	_selected_item = {}
	if is_instance_valid(item_action_popup):
		item_action_popup.visible = false

func _on_confiscar_pressed() -> void:
	if _selected_item.is_empty() or bool(_selected_item.get("removing", false)):
		_hide_item_action_popup()
		return
	var entry := _selected_item
	_hide_item_action_popup()
	var prohibited := _is_item_prohibited(str(entry["type_id"]), str(entry["deco"]), bool(entry["is_magic"]))
	if prohibited:
		_apply_honor_change(6, false)
	_remove_desk_item_animated(entry, true)

func _on_robar_pressed() -> void:
	if GameManager.current_day < 3 or _selected_item.is_empty() or bool(_selected_item.get("removing", false)):
		_hide_item_action_popup()
		return
	var entry := _selected_item
	_hide_item_action_popup()
	var type_id := str(entry["type_id"])
	var deco := str(entry["deco"])
	var honor_loss := -8
	var item_value := randi_range(3, 5)
	if type_id == "escudo" or deco in ["gema", "esmeralda", "moneda"]:
		honor_loss = -12
		item_value = randi_range(6, 10)
	elif type_id == "pocion":
		honor_loss = -5
		item_value = randi_range(1, 3)

	GameManager.stolen_value_today += item_value
	GameManager.stolen_count_today += 1
	_apply_honor_change(honor_loss, false)
	_remove_desk_item_animated(entry, false)

func _remove_desk_item_animated(entry: Dictionary, to_right: bool) -> void:
	entry["removing"] = true
	_desk_items.erase(entry)
	_current_npc_items.erase(entry)
	_sync_desk_items_to_save()
	GameManager.save_game()

	var ctrl := entry["ctrl"] as Control
	for i in range(_runes.size() - 1, -1, -1):
		if _runes[i].get("owner") == ctrl:
			_runes.remove_at(i)

	if not is_instance_valid(ctrl):
		return
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel(true)
	if to_right:
		tween.tween_property(ctrl, "position:x", 580.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(ctrl, "position:y", 330.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(ctrl, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(ctrl):
		ctrl.queue_free()

func _flash_vignette(color: Color) -> void:
	var mat := vignette_rect.material as ShaderMaterial
	if not mat:
		return
	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()
	mat.set_shader_parameter("vignette_color", color)
	mat.set_shader_parameter("intensity", 0.9)
	_vignette_tween = create_tween()
	_vignette_tween.tween_method(_set_vignette_intensity, 0.9, 0.0, 0.65).set_ease(Tween.EASE_IN)

func _apply_honor_change(delta: int, play_coins: bool) -> void:
	if delta > 0:
		GameManager.honor = clampi(GameManager.honor + delta, -100, 100)
		AudioManager.play_sfx(CAMPANA_PEQUE_SFX)
		_flash_vignette(VIGNETTE_WHITE)
	elif delta < 0:
		GameManager.honor = clampi(GameManager.honor + delta, -100, 100)
		AudioManager.play_sfx(CAMPANA_GRANDE_SFX)
		_flash_vignette(VIGNETTE_RED)
	if play_coins:
		AudioManager.play_sfx(BAG_OF_COINS_SFX)
	_update_day_progress_label()

func _is_item_prohibited(type_id: String, deco: String, is_magic: bool) -> bool:
	match GameManager.current_day:
		1:
			if deco in ["corona", "esmeralda", "moneda"]:
				return type_id != "pocion"
			return false
		2:
			if deco in ["espada", "fuego", "calavera", "ojo"]:
				return type_id != "libro"
			return false
		3:
			if deco in ["gema", "moneda"]:
				return not is_magic
			return false
		4:
			if type_id == "escudo" or deco == "calavera":
				return deco != "fuego"
			return false
		5:
			var is_sacred := deco in ["luna", "corona", "gema"]
			return not (is_sacred and not is_magic)
	return false

func _has_prohibited_npc_item() -> bool:
	for entry in _current_npc_items:
		if _is_item_prohibited(str(entry["type_id"]), str(entry["deco"]), bool(entry["is_magic"])):
			return true
	return false

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
				"]. Todo lo demás, pasa.",
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
				"Prohibidos los objetos de [", _colored_tag("Brujo ", "#5a5a5a"), Vector2i(1, 0),
				"] y las [", _colored_tag("Armas ", "#4f5b66"), escudo_icon,
				"] (excepto si llevan ", Vector2i(2, 1), "). Todo lo demás, pasa.",
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
	var auto_confiscated_count := 0
	var auto_confiscated_honor := 0
	for entry in _desk_items:
		if bool(entry.get("removing", false)) or (entry in _current_npc_items):
			continue
		if _is_item_prohibited(str(entry["type_id"]), str(entry["deco"]), bool(entry["is_magic"])):
			auto_confiscated_count += 1
			auto_confiscated_honor += 6
	if auto_confiscated_honor > 0:
		GameManager.honor = clampi(GameManager.honor + auto_confiscated_honor, -100, 100)
		_update_day_progress_label()

	_clear_all_desk_items()
	GameManager.desk_items = []
	var prev_money := GameManager.money
	var salary := floori(GameManagerClass.FIXED_DAILY_SALARY / 2.0) if timed_out else GameManagerClass.FIXED_DAILY_SALARY
	var arrest_rate := GameManager.arrest_reward_today
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

	var stolen_bonus := GameManager.stolen_value_today
	var stolen_count := GameManager.stolen_count_today
	var day_income := salary + arrest_bonus + stolen_bonus
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
	]
	if stolen_count > 0:
		summary_lines.append("[color=#66e066]+ Venta de objetos robados: +%d (%d obj.)[/color]" % [stolen_bonus, stolen_count])
	if auto_confiscated_count > 0:
		summary_lines.append("[color=#66e066]+ Confiscación automática al cierre: +%d Honor (%d obj.)[/color]" % [auto_confiscated_honor, auto_confiscated_count])
	summary_lines.append("[color=#e05555]- Comida para la familia: -%d[/color]" % food_cost)
	summary_lines.append_array(event_lines)
	summary_lines.append("------------------------------")
	summary_lines.append("Dinero resultante: %d | Honor: %d/100" % [maxi(new_money, 0), GameManager.honor])

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
		summary_lines.append("Honor final: %d/100" % GameManager.honor)
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
		summary_lines.append("Dinero final: %d | Honor final: %d/100 | Eventos: %d" % [new_money, GameManager.honor, GameManager.total_events])
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
