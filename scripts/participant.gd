class_name Participant
extends RefCounted

var id: int = 0
var strategy: StrategyBase
var total_score: float = 0.0
var cooperation_count: int = 0
var defection_count: int = 0
var last_action: int = -1
var last_payoff: float = 0.0


func _init(participant_id: int = 0, assigned_strategy: StrategyBase = null) -> void:
	id = participant_id
	strategy = assigned_strategy
	if strategy == null:
		strategy = StrategyBase.new()


func reset_stats() -> void:
	total_score = 0.0
	cooperation_count = 0
	defection_count = 0
	last_action = -1
	last_payoff = 0.0
	if strategy != null:
		strategy.reset()


func decide(public_info: RoundPublicInfo) -> int:
	var action := strategy.decide_action(public_info)
	if action != StrategyBase.COOPERATE and action != StrategyBase.DEFECT:
		return StrategyBase.COOPERATE
	return action


func apply_result(action: int, payoff: float) -> void:
	last_action = action
	last_payoff = payoff
	total_score += payoff
	if action == StrategyBase.COOPERATE:
		cooperation_count += 1
	elif action == StrategyBase.DEFECT:
		defection_count += 1

