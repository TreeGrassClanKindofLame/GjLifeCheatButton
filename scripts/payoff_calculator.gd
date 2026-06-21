class_name PayoffCalculator
extends RefCounted


static func calculate_payoffs(actions: Array[int], full_cooperation_payoff: float) -> Array[float]:
	var payoffs: Array[float] = []
	var participant_count := actions.size()
	if participant_count == 0:
		return payoffs

	var defectors_count := 0
	for action in actions:
		if action == StrategyBase.DEFECT:
			defectors_count += 1

	if defectors_count == 0:
		for _i in range(participant_count):
			payoffs.append(full_cooperation_payoff)
		return payoffs

	if defectors_count == participant_count:
		for _i in range(participant_count):
			payoffs.append(0.0)
		return payoffs

	# Partial defection: cooperators get zero. Defectors split a shrinking pool,
	# so more defectors reduce both total value and per-defector value.
	var n := float(participant_count)
	var d := float(defectors_count)
	var betrayal_pool := full_cooperation_payoff * n - d * (full_cooperation_payoff / (2.0 * n))
	var defector_payoff := betrayal_pool / d

	for action in actions:
		if action == StrategyBase.DEFECT:
			payoffs.append(defector_payoff)
		else:
			payoffs.append(0.0)

	return payoffs


static func build_payoff_table_text(full_cooperation_payoff: float = 10.0) -> String:
	var lines: Array[String] = []
	for participant_count in range(2, 6):
		lines.append(build_payoff_table_for_count(participant_count, full_cooperation_payoff))
	return "\n".join(lines)


static func build_payoff_table_for_count(participant_count: int, full_cooperation_payoff: float = 10.0) -> String:
	participant_count = max(1, participant_count)

	var lines: Array[String] = []
	lines.append("%d 人" % participant_count)
	lines.append("总人数\t合作人数\t背叛人数\t合作者每人收益\t背叛者每人收益\t全体总收益")
	for defectors_count in range(0, participant_count + 1):
		var actions: Array[int] = []
		for i in range(participant_count):
			if i < defectors_count:
				actions.append(StrategyBase.DEFECT)
			else:
				actions.append(StrategyBase.COOPERATE)

		var payoffs := calculate_payoffs(actions, full_cooperation_payoff)
		var cooperators_count := participant_count - defectors_count
		var cooperator_each := "-"
		var defector_each := "-"
		if cooperators_count > 0:
			cooperator_each = format_amount(payoffs[defectors_count])
		if defectors_count > 0:
			defector_each = format_amount(payoffs[0])

		var total_payoff := 0.0
		for payoff in payoffs:
			total_payoff += payoff

		lines.append("%d\t%d\t%d\t%s\t%s\t%s" % [
			participant_count,
			cooperators_count,
			defectors_count,
			cooperator_each,
			defector_each,
			format_amount(total_payoff),
		])
	return "\n".join(lines)


static func build_payoff_table_rows_for_count(participant_count: int, full_cooperation_payoff: float = 10.0) -> Array:
	participant_count = max(1, participant_count)

	var rows: Array = []
	for defectors_count in range(0, participant_count + 1):
		var actions: Array[int] = []
		for i in range(participant_count):
			if i < defectors_count:
				actions.append(StrategyBase.DEFECT)
			else:
				actions.append(StrategyBase.COOPERATE)

		var payoffs := calculate_payoffs(actions, full_cooperation_payoff)
		var cooperators_count := participant_count - defectors_count
		var cooperator_each := "-"
		var defector_each := "-"
		if cooperators_count > 0:
			cooperator_each = format_amount(payoffs[defectors_count])
		if defectors_count > 0:
			defector_each = format_amount(payoffs[0])

		var total_payoff := 0.0
		for payoff in payoffs:
			total_payoff += payoff

		rows.append({
			"participant_count": participant_count,
			"cooperators_count": cooperators_count,
			"defectors_count": defectors_count,
			"cooperator_each": cooperator_each,
			"defector_each": defector_each,
			"total_payoff": format_amount(total_payoff),
		})
	return rows


static func format_amount(value: float) -> String:
	var text := "%.2f" % snappedf(value, 0.01)
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text
