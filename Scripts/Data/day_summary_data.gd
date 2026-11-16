class_name DaySummaryData
extends RefCounted

const FAMILY_MEMBERS: Array[String] = ["Esposa", "Hijo", "Hija"]
const ILLNESS_MIN_COST := 8
const ILLNESS_MAX_COST := 14
const ILLNESS_PROBABILITY := 0.25

const EXTERNAL_EVENTS: Array[Dictionary] = [
	{"name": "Deuda pendiente", "min_cost": 6, "max_cost": 12, "prob": 0.30},
	{"name": "Robo en casa", "min_cost": 5, "max_cost": 10, "prob": 0.30},
]

const COLOR_NAMES: Array[String] = ["Azul", "Rojo", "Verde", "Morado", "Dorado", "Turquesa", "Magenta", "Gris"]

const CONFISCATE_LABELS: Dictionary = {
	"libro": "Educación (Libros)",
	"escudo": "Seguridad (Escudos)",
	"pocion": "Logística (Botellas)",
}

const CATEGORY_LABELS: Dictionary = {
	"sagrados": "Objetos sagrados",
	"peligrosos": "Objetos peligrosos",
	"valiosos": "Objetos valiosos",
	"naturistas": "Objetos naturistas",
}

const GAME_OVER_TIPS: Array[String] = [
	"[color=#8a1c1c]INFORME DE BANCARROTA:[/color]",
	"• Tus arcas se han vaciado.",
	"• El alguacil clausuro la notaria",
	"  y confisco tus bienes.",
	"",
	"[color=#8a1c1c]Fin de la notaria.[/color]",
]

const GAME_WIN_TIPS: Array[String] = [
	"[color=#1e6b2c]CONDECORACION REAL:[/color]",
	"• ¡5 dias completados con exito!",
	"• El gremio reconoce tu astucia",
	"  e integridad.",
	"",
	"[color=#1e6b2c]¡Has triunfado![/color]",
]

static func calculate_day_finances(prev_money: int, day: int, arrests: int, timed_out: bool) -> Dictionary:
	var salary := floori(GameManagerClass.FIXED_DAILY_SALARY / 2.0) if timed_out else GameManagerClass.FIXED_DAILY_SALARY
	var arrest_rate: int = GameManager.arrest_reward_today if GameManager.arrest_reward_today > 0 else randi_range(4, 7)
	var arrest_bonus := arrests * arrest_rate
	var food_cost := randi_range(14, 20) if day >= 4 else randi_range(10, 16)

	var event_cost := 0
	var event_lines: Array[String] = []
	var has_sick_family := false

	for member in FAMILY_MEMBERS:
		if randf() < ILLNESS_PROBABILITY:
			var cost := randi_range(ILLNESS_MIN_COST, ILLNESS_MAX_COST)
			event_cost += cost
			event_lines.append("[color=#8a1c1c]- Enfermedad (%s): -%d[/color]" % [member, cost])
			has_sick_family = true

	for ev in EXTERNAL_EVENTS:
		if randf() < float(ev["prob"]):
			var cost := randi_range(int(ev["min_cost"]), int(ev["max_cost"]))
			event_cost += cost
			event_lines.append("[color=#8a1c1c]- %s: -%d[/color]" % [ev["name"], cost])

	var stolen_bonus: int = GameManager.stolen_value_today
	var stolen_count: int = GameManager.stolen_count_today
	var day_income := salary + arrest_bonus + stolen_bonus
	var day_expenses := food_cost + event_cost
	var new_money := prev_money + day_income - day_expenses

	var salary_line := "[color=#1e6b2c]+ Sueldo del dia: +%d[/color]" % salary
	if timed_out:
		salary_line = "[color=#1e6b2c]+ Sueldo (penalizacion): +%d[/color]" % salary

	var lines: Array[String] = [
		"Oro inicial: $%d" % prev_money,
		salary_line,
		"[color=#1e6b2c]+ Bono arresto: +%d (%dx$%d)[/color]" % [arrest_bonus, arrests, arrest_rate],
	]
	if stolen_count > 0:
		lines.append("[color=#1e6b2c]+ Venta robados: +%d (%d obj.)[/color]" % [stolen_bonus, stolen_count])
	lines.append("[color=#8a1c1c]- Comida y sustento: -%d[/color]" % food_cost)
	lines.append_array(event_lines)
	lines.append("----------------")
	lines.append("[color=#1a386b]Oro resultante: $%d | Honor: %d[/color]" % [maxi(new_money, 0), GameManager.honor])

	var is_game_over := new_money <= 0
	var is_game_win := not is_game_over and day >= GameManagerClass.MAX_DAYS

	return {
		"new_money": new_money,
		"day_income": day_income,
		"day_expenses": day_expenses,
		"event_count": event_lines.size(),
		"has_sick_family": has_sick_family,
		"finance_text": "\n".join(lines),
		"is_game_over": is_game_over,
		"is_game_win": is_game_win,
	}

static func get_daily_tips(day: int, is_game_over: bool, is_game_win: bool) -> String:
	if is_game_over:
		return "\n".join(GAME_OVER_TIPS)
	if is_game_win:
		return "\n".join(GAME_WIN_TIPS)

	var tips: Array[String] = []
	match day:
		1:
			tips = [
				"[color=#1a386b]DECRETO PARA MAÑANA (DÍA 2):[/color]",
				"• La población cayó tras",
				"  excluir un color.",
				"• Solo pasan [color=#6b2399]Personas Valiosas[/color]",
				"  (con algún objeto mágico).",
				"• Recibirás el Lente Espectral.",
			]
		2:
			var target_label: String = CONFISCATE_LABELS.get(GameManager.day3_confiscate_type, "Educación")
			tips = [
				"[color=#1a386b]DECRETO PARA MAÑANA (DÍA 3):[/color]",
				"• Tras un atentado arcano:",
				"  [color=#8a1c1c]Objetos mágicos prohibidos[/color].",
				"• Confisca: [color=#1e6b2c]%s[/color]." % target_label,
				"• Podrás robar objetos que",
				"  el rey no reclama...",
			]
		3:
			var cat4: String = CATEGORY_LABELS.get(GameManager.day4_confiscate_category, "Objetos")
			tips = [
				"[color=#1a386b]DECRETO PARA MAÑANA (DÍA 4):[/color]",
				"• El reino cierra sus puertas:",
				"  [color=#8a1c1c]TODO viajero es arrestado[/color].",
				"• Confisca: [color=#1e6b2c]%s[/color]." % cat4,
				"• Vacía la mesa antes de cerrar.",
			]
		4:
			var cat5: String = CATEGORY_LABELS.get(GameManager.day5_prohibited_category, "Objetos")
			tips = [
				"[color=#1a386b]DECRETO PARA MAÑANA (DÍA 5):[/color]",
				"• Hay espías en el reino.",
				"• Arresta a quienes porten:",
				"  [color=#8a1c1c]%s[/color]." % cat5,
				"• Confisca objetos [color=#6b2399]Mágicos[/color].",
			]
		_:
			var c_name: String = COLOR_NAMES[clampi(GameManager.day1_banned_color_index, 0, COLOR_NAMES.size() - 1)]
			tips = [
				"[color=#1a386b]DECRETO REAL:[/color]",
				"• Prohibido vestir de %s." % c_name,
			]
	return "\n".join(tips)
