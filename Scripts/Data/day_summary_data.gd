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

const DAILY_TIPS: Dictionary = {
	1: [
		"[color=#1a386b]DECRETO INAUGURAL:[/color]",
		"• Usa el Lente Espectral.",
		"• Sin anomalias: [color=#1e6b2c]COBRAR[/color].",
		"• Con runas: [color=#8a1c1c]ARRESTAR[/color].",
		"",
		"Cada arresto da oro extra.",
	],
	2: [
		"[color=#1a386b]AVISO DE SEGURIDAD:[/color]",
		"• Ojo al reloj: tiempo 0",
		"  retiene el [color=#8a1c1c]50% de sueldo[/color].",
		"• Mueve los objetos en mesa.",
		"",
		"No tardes con cada cliente.",
	],
	3: [
		"[color=#1a386b]INFORME FAMILIAR:[/color]",
		"• Los costos aumentan.",
		"• Tu familia puede enfermar.",
		"• Reserva de [color=#1e6b2c]$15-$20[/color].",
		"• No dejes pasar anomalias.",
	],
	4: [
		"[color=#1a386b]ALERTA DE CARGAS:[/color]",
		"• Traen hasta 3 objetos.",
		"• Revisa uno por uno.",
		"• Una sola runa amerita",
		"  [color=#8a1c1c]ARRESTO INMEDIATO[/color].",
		"• Sepáralos en la mesa.",
	],
	5: [
		"[color=#1a386b]AUDITORIA REAL FINAL:[/color]",
		"• Ultimo dia de inspeccion.",
		"• Si tu oro llega a $0,",
		"  vas a prision por deudas.",
		"• Asegura cada cobro.",
	],
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
	var food_cost := randi_range(10, 16)

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

	var day_income := salary + arrest_bonus
	var day_expenses := food_cost + event_cost
	var new_money := prev_money + day_income - day_expenses

	var salary_line := "[color=#1e6b2c]+ Sueldo del dia: +%d[/color]" % salary
	if timed_out:
		salary_line = "[color=#1e6b2c]+ Sueldo (penalizacion): +%d[/color]" % salary

	var lines: Array[String] = [
		"Oro inicial: $%d" % prev_money,
		salary_line,
		"[color=#1e6b2c]+ Bono arresto: +%d (%dx$%d)[/color]" % [arrest_bonus, arrests, arrest_rate],
		"[color=#8a1c1c]- Comida y sustento: -%d[/color]" % food_cost,
	]
	lines.append_array(event_lines)
	lines.append("----------------")
	lines.append("[color=#1a386b]Oro resultante: $%d[/color]" % maxi(new_money, 0))

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

	var tips: Array = DAILY_TIPS.get(day, DAILY_TIPS[1])
	return "\n".join(tips)
