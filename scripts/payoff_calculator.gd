class_name PayoffCalculator
extends RefCounted

const PayoffConfigLib := preload("res://scripts/payoff_config.gd")


static func calculate_payoffs(actions: Array[int], config) -> Array[float]:
	var payoffs: Array[float] = []
	var participant_count := actions.size()
	if participant_count == 0:
		return payoffs

	var defectors_count := 0
	for action in actions:
		if action == StrategyBase.DEFECT:
			defectors_count += 1

	var full_cooperation_payoff: float = max(0.0, config.full_cooperation_payoff)
	if defectors_count == 0:
		for _i in range(participant_count):
			payoffs.append(full_cooperation_payoff)
		return payoffs

	if defectors_count == participant_count:
		var all_defect_payoff: float = config.all_defect_payoff
		if config.force_all_defect_zero:
			all_defect_payoff = 0.0
		for _i in range(participant_count):
			payoffs.append(all_defect_payoff)
		return payoffs

	var cooperators_count := participant_count - defectors_count
	var cooperator_payoff: float = config.betrayal_cooperator_payoff
	var defector_payoff := _calculate_defector_payoff(participant_count, defectors_count, cooperators_count, config)

	for action in actions:
		if action == StrategyBase.DEFECT:
			payoffs.append(defector_payoff)
		else:
			payoffs.append(cooperator_payoff)

	return payoffs


static func calculate_payoffs_for_counts(participant_count: int, defectors_count: int, config) -> Array[float]:
	var actions: Array[int] = []
	for i in range(max(1, participant_count)):
		if i < defectors_count:
			actions.append(StrategyBase.DEFECT)
		else:
			actions.append(StrategyBase.COOPERATE)
	return calculate_payoffs(actions, config)


static func build_payoff_table_text(config) -> String:
	var lines: Array[String] = []
	for participant_count in range(2, 6):
		lines.append(build_payoff_table_for_count(participant_count, config))
	return "\n".join(lines)


static func build_payoff_table_for_count(participant_count: int, config) -> String:
	participant_count = max(1, participant_count)

	var lines: Array[String] = []
	lines.append("%d 人" % participant_count)
	lines.append("总人数\t合作人数\t背叛人数\t合作者每人收益\t背叛者每人收益\t全体总收益")
	for row in build_payoff_table_rows_for_count(participant_count, config):
		lines.append("%d\t%d\t%d\t%s\t%s\t%s" % [
			row["participant_count"],
			row["cooperators_count"],
			row["defectors_count"],
			row["cooperator_each"],
			row["defector_each"],
			row["total_payoff"],
		])
	return "\n".join(lines)


static func build_payoff_table_rows_for_count(participant_count: int, config) -> Array:
	participant_count = max(1, participant_count)

	var rows: Array = []
	for defectors_count in range(0, participant_count + 1):
		var payoffs := calculate_payoffs_for_counts(participant_count, defectors_count, config)
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


static func validate_payoff_config(participant_count: int, config) -> Array[String]:
	participant_count = max(1, participant_count)
	var warnings: Array[String] = []
	var full_coop_total: float = config.full_cooperation_payoff * float(participant_count)
	var previous_total: float = INF
	var previous_defector_each: float = INF
	var has_previous_defector := false

	for defectors_count in range(0, participant_count + 1):
		var row := _summarize_count_case(participant_count, defectors_count, config)
		var total_payoff: float = row["total_payoff_value"]
		var defector_each: float = row["defector_each_value"]

		if config.force_all_coop_best_total and total_payoff > full_coop_total + 0.001:
			warnings.append("D=%d 时全体总收益 %s 高于全员合作总收益 %s。" % [
				defectors_count,
				format_amount(total_payoff),
				format_amount(full_coop_total),
			])

		if defectors_count > 0 and total_payoff > previous_total + 0.001:
			warnings.append("D=%d 时全体总收益没有随背叛人数增加而递减。" % defectors_count)

		if defectors_count > 0 and defectors_count < participant_count:
			if has_previous_defector and defector_each > previous_defector_each + 0.001:
				warnings.append("D=%d 时背叛者每人收益异常升高。" % defectors_count)
			if config.force_defector_above_full_coop_payoff and defector_each <= config.full_cooperation_payoff + 0.001:
				warnings.append("D=%d 时背叛者每人收益没有高于全员合作收益 C。" % defectors_count)
			previous_defector_each = defector_each
			has_previous_defector = true

		previous_total = total_payoff

	var all_defect_row := _summarize_count_case(participant_count, participant_count, config)
	if config.force_all_defect_zero and absf(all_defect_row["total_payoff_value"]) > 0.001:
		warnings.append("全员背叛总收益不是 0。")

	if warnings.is_empty():
		warnings.append("当前收益规则未发现约束警告。")
	return warnings


static func _calculate_defector_payoff(
	participant_count: int,
	defectors_count: int,
	cooperators_count: int,
	config
) -> float:
	var n := float(participant_count)
	var d := float(defectors_count)
	var k := float(cooperators_count)
	var full_cooperation_payoff: float = max(0.0, config.full_cooperation_payoff)
	var betrayal_pool := 0.0

	match config.payoff_mode:
		PayoffConfigLib.PayoffMode.ORIGINAL_EXTREME:
			betrayal_pool = full_cooperation_payoff * n - d * (full_cooperation_payoff / (2.0 * n))
		PayoffConfigLib.PayoffMode.LINEAR_DECAY:
			var pool_ratio: float = 1.0 - config.collapse_severity * d / n
			pool_ratio = max(pool_ratio, config.min_pool_ratio)
			betrayal_pool = full_cooperation_payoff * n * pool_ratio
		PayoffConfigLib.PayoffMode.EXPONENTIAL_DECAY:
			betrayal_pool = full_cooperation_payoff * n * pow(config.betrayal_efficiency, d)
		PayoffConfigLib.PayoffMode.CUSTOM_TABLE:
			var custom_ratio := _get_custom_pool_ratio(defectors_count, participant_count, config)
			betrayal_pool = full_cooperation_payoff * n * custom_ratio
		_:
			betrayal_pool = full_cooperation_payoff * n * pow(config.betrayal_efficiency, d)

	var cooperator_total: float = config.betrayal_cooperator_payoff * k
	var defector_pool: float = max(betrayal_pool - cooperator_total, 0.0)
	return defector_pool / d


static func _get_custom_pool_ratio(defectors_count: int, participant_count: int, config) -> float:
	var ratios: Array[float] = config.custom_total_pool_ratios
	if defectors_count == 0:
		return 1.0
	if defectors_count == participant_count:
		return 0.0
	if defectors_count < ratios.size():
		return max(0.0, ratios[defectors_count])
	return max(0.0, 1.0 - float(defectors_count) / float(participant_count))


static func _summarize_count_case(participant_count: int, defectors_count: int, config) -> Dictionary:
	var payoffs := calculate_payoffs_for_counts(participant_count, defectors_count, config)
	var total_payoff := 0.0
	for payoff in payoffs:
		total_payoff += payoff
	var defector_each := 0.0
	if defectors_count > 0:
		defector_each = payoffs[0]
	return {
		"total_payoff_value": total_payoff,
		"defector_each_value": defector_each,
	}


static func format_amount(value: float) -> String:
	return "%.2f" % snappedf(value, 0.01)
