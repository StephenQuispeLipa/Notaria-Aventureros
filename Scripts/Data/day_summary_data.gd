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
		"[b]DECRETO INAUGURAL:[/b]",
		"• Inspecciona cada objeto con el [color=#1a386b]Lente Espectral[/color].",
		"• Si el objeto no presenta anomalías ni sellos prohibidos, pulsa [color=#1e6b2c]COBRAR[/color].",
		"• Si detectas runas arcanas o contrabando, pulsa [color=#8a1c1c]ARRESTAR[/color] de inmediato.",
		"",
		"[i]Nota: Cada arresto legítimo otorga una recompensa en oro.[/i]",
	],
	2: [
		"[b]AVISO DE SEGURIDAD:[/b]",
		"• Cuidado con el reloj de arena: si se agota el tiempo del día, el gremio retendrá el [color=#8a1c1c]50% de tu sueldo[/color].",
		"• Arrastra los objetos por la mesa para examinar sus bordes e inscripciones con detalle.",
		"",
		"[i]Consejo: No tardes demasiado con cada aventurero.[/i]",
	],
	3: [
		"[b]INFORME FAMILIAR Y DEUDAS:[/b]",
		"• Los costos de manutención aumentan y la ciudad cobra impuestos.",
		"• Tu familia puede enfermarse en cualquier momento. Mantén siempre una reserva de al menos [color=#1a386b]$15-$20[/color].",
		"• No permitas que pasen objetos con anomalías ocultas.",
	],
	4: [
		"[b]ALERTA DE MAGOS Y CARGAS:[/b]",
		"• Los clientes traerán hasta [color=#1a386b]3 objetos[/color] a la vez.",
		"• Revisa uno por uno. Basta con que [b]un solo objeto[/b] tenga runas prohibidas para ordenar el arresto.",
		"• Sepáralos en la mesa para ver qué ocultan detrás.",
	],
	5: [
		"[b]AUDITORÍA REAL FINAL:[/b]",
		"• Es el último día de inspección. La guardia real revisará tus libros de cuentas.",
		"• ¡Si tu oro cae a cero en los gastos de hoy, irás a prisión por insolvencia!",
		"• Asegura cada cobro y cada captura para alcanzar el final del turno.",
	],
}

const GAME_OVER_TIPS: Array[String] = [
	"[b]INFORME DE BANCARROTA:[/b]",
	"• Tus arcas se han vaciado por completo.",
	"• El alguacil real ha clausurado la notaría y confiscado tus pertenencias para saldar deudas.",
	"",
	"[color=#8a1c1c]Has fracasado en mantener la oficina a flote.[/color]",
]

const GAME_WIN_TIPS: Array[String] = [
	"[b]CONDECORACIÓN REAL:[/b]",
	"• ¡Has completado los 5 días de auditoría con honores!",
	"• El gremio de notarios reconoce tu astucia e integridad protegiendo la ciudad.",
	"",
	"[color=#1e6b2c]¡La Notaría de Aventureros ha prosperado gracias a ti![/color]",
]

static func calculate_day_finances(prev_money: int, day: int, arrests: int, timed_out: bool) -> Dictionary:
	var salary := floori(GameManagerClass.FIXED_DAILY_SALARY / 2.0) if timed_out else GameManagerClass.FIXED_DAILY_SALARY
	var arrest_rate := randi_range(4, 7)
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

	var salary_line := "[color=#1e6b2c]+ Sueldo del día: +%d[/color]" % salary
	if timed_out:
		salary_line = "[color=#1e6b2c]+ Sueldo (penalización tiempo): +%d[/color]" % salary

	var lines: Array[String] = [
		"Oro inicial: %d" % prev_money,
		salary_line,
		"[color=#1e6b2c]+ Bono por arrestos: +%d (%d x $%d)[/color]" % [arrest_bonus, arrests, arrest_rate],
		"[color=#8a1c1c]- Comida y sustento: -%d[/color]" % food_cost,
	]
	lines.append_array(event_lines)
	lines.append("----------------------------")
	lines.append("[b]Oro resultante: %d[/b]" % maxi(new_money, 0))

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
