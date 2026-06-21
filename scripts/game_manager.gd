class_name GameManager
extends RefCounted

const ParticipantLib := preload("res://scripts/participant.gd")
const RoundPublicInfoLib := preload("res://scripts/round_public_info.gd")
const RoundResultLib := preload("res://scripts/round_result.gd")
const PayoffCalculatorLib := preload("res://scripts/payoff_calculator.gd")
const PayoffConfigLib := preload("res://scripts/payoff_config.gd")
const StrategyBaseLib := preload("res://scripts/strategy_base.gd")
const AlwaysCooperateLib := preload("res://scripts/strategies/always_cooperate.gd")

const STRATEGY_NAMES: Array[String] = [
	"永远合作",
	"永远背叛",
	"随机策略",
	"条件合作者",
	"谨慎条件合作者",
	"宽容匿名针锋相对",
	"有限触发",
	"冷酷触发",
	"赢留输变",
	"试探者",
]

const STRATEGY_SCRIPT_PATHS := {
	"永远合作": "res://scripts/strategies/always_cooperate.gd",
	"永远背叛": "res://scripts/strategies/always_defect.gd",
	"随机策略": "res://scripts/strategies/random_strategy.gd",
	"条件合作者": "res://scripts/strategies/conditional_cooperator.gd",
	"谨慎条件合作者": "res://scripts/strategies/cautious_conditional_cooperator.gd",
	"宽容匿名针锋相对": "res://scripts/strategies/generous_anonymous_tit_for_tat.gd",
	"有限触发": "res://scripts/strategies/limited_trigger.gd",
	"冷酷触发": "res://scripts/strategies/grim_trigger.gd",
	"赢留输变": "res://scripts/strategies/win_stay_lose_shift.gd",
	"试探者": "res://scripts/strategies/tester_prober.gd",
}

var participant_count: int = 10
var total_rounds: int = 100
var payoff_config = PayoffConfigLib.new()
var current_round: int = 0
var participants: Array = []
var history: Array = []
var last_result = null


func setup(
	new_participant_count: int = 10,
	new_total_rounds: int = 100,
	new_payoff_config = null,
	selected_strategy_names: Array[String] = []
) -> void:
	participant_count = max(1, new_participant_count)
	total_rounds = max(1, new_total_rounds)
	if new_payoff_config != null:
		payoff_config = new_payoff_config.duplicate_config()
	current_round = 0
	history.clear()
	last_result = null
	participants.clear()

	for i in range(participant_count):
		var strategy_name: String = STRATEGY_NAMES[i % STRATEGY_NAMES.size()]
		if i < selected_strategy_names.size() and selected_strategy_names[i] in STRATEGY_SCRIPT_PATHS:
			strategy_name = selected_strategy_names[i]
		participants.append(ParticipantLib.new(i + 1, create_strategy_by_name(strategy_name)))


func reset_simulation() -> void:
	current_round = 0
	history.clear()
	last_result = null
	for participant in participants:
		participant.reset_stats()


func create_strategy_by_name(strategy_name: String):
	var path: String = STRATEGY_SCRIPT_PATHS.get(strategy_name, STRATEGY_SCRIPT_PATHS["永远合作"])
	var script: Resource = load(path)
	if script == null:
		return AlwaysCooperateLib.new()
	var strategy = script.new()
	return strategy


func set_strategy_for_participant(index: int, strategy_name: String) -> void:
	if index < 0 or index >= participants.size():
		return
	participants[index].strategy = create_strategy_by_name(strategy_name)


func step_round():
	if participants.is_empty():
		setup(participant_count, total_rounds, payoff_config)
	if current_round >= total_rounds:
		return last_result

	var actions: Array[int] = []
	for participant in participants:
		var public_info = _build_public_info_for(participant)
		actions.append(participant.decide(public_info))

	var payoffs := PayoffCalculatorLib.calculate_payoffs(actions, payoff_config)
	var cooperators_count := 0
	var defectors_count := 0
	var total_payoff := 0.0

	for i in range(participants.size()):
		var action := actions[i]
		var payoff := payoffs[i]
		participants[i].apply_result(action, payoff)
		total_payoff += payoff
		if action == StrategyBaseLib.COOPERATE:
			cooperators_count += 1
		elif action == StrategyBaseLib.DEFECT:
			defectors_count += 1

	current_round += 1

	var result := RoundResultLib.new()
	result.round_index = current_round
	result.cooperators_count = cooperators_count
	result.defectors_count = defectors_count
	result.cooperation_rate = float(cooperators_count) / float(participants.size())
	result.total_payoff = total_payoff
	result.average_payoff = total_payoff / float(participants.size())
	result.actions = actions
	result.payoffs = payoffs

	last_result = result
	history.append(result)
	return result


func build_payoff_table_text() -> String:
	return PayoffCalculatorLib.build_payoff_table_for_count(participant_count, payoff_config)


func build_payoff_table_rows() -> Array:
	return PayoffCalculatorLib.build_payoff_table_rows_for_count(participant_count, payoff_config)


func build_payoff_table_rows_for_count(count: int) -> Array:
	return PayoffCalculatorLib.build_payoff_table_rows_for_count(count, payoff_config)


func validate_payoff_config_for_count(count: int = -1) -> Array[String]:
	var target_count := participant_count
	if count > 0:
		target_count = count
	return PayoffCalculatorLib.validate_payoff_config(target_count, payoff_config)


func get_recent_history(limit: int = 20) -> Array:
	var results: Array = []
	var start_index: int = max(0, history.size() - limit)
	for i in range(start_index, history.size()):
		results.append(history[i])
	return results


func get_historical_average_cooperation_rate() -> float:
	if history.is_empty():
		return 0.0
	var total := 0.0
	for result in history:
		total += result.cooperation_rate
	return total / float(history.size())


func get_highest_score_participant():
	if participants.is_empty():
		return null
	var best = participants[0]
	for participant in participants:
		if participant.total_score > best.total_score:
			best = participant
	return best


func get_lowest_score_participant():
	if participants.is_empty():
		return null
	var worst = participants[0]
	for participant in participants:
		if participant.total_score < worst.total_score:
			worst = participant
	return worst


func is_finished() -> bool:
	return current_round >= total_rounds


func _build_public_info_for(participant):
	var public_info := RoundPublicInfoLib.new()
	public_info.round_index = current_round + 1
	public_info.participant_count = participants.size()
	public_info.historical_average_cooperation_rate = get_historical_average_cooperation_rate()
	public_info.recent_cooperation_rates = _get_recent_cooperation_rates(20)
	public_info.my_last_action = participant.last_action
	public_info.my_last_payoff = participant.last_payoff
	public_info.my_total_score = participant.total_score
	public_info.my_cooperation_count = participant.cooperation_count
	public_info.my_defection_count = participant.defection_count
	public_info.full_cooperation_payoff = payoff_config.full_cooperation_payoff

	if last_result != null:
		public_info.last_cooperators_count = last_result.cooperators_count
		public_info.last_defectors_count = last_result.defectors_count
		public_info.last_cooperation_rate = last_result.cooperation_rate
		public_info.last_total_payoff = last_result.total_payoff
		public_info.last_average_payoff = last_result.average_payoff

	return public_info


func _get_recent_cooperation_rates(limit: int) -> Array[float]:
	var rates: Array[float] = []
	var start_index: int = max(0, history.size() - limit)
	for i in range(start_index, history.size()):
		rates.append(history[i].cooperation_rate)
	return rates
