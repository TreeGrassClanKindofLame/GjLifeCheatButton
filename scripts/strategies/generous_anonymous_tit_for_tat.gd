class_name GenerousAnonymousTitForTatStrategy
extends StrategyBase

var cooperation_threshold: float = 0.6
var bad_round_threshold: int = 2
var forgiveness_probability: float = 0.3
var bad_round_count: int = 0


func _init() -> void:
	strategy_name = "宽容匿名针锋相对"


func reset() -> void:
	bad_round_count = 0


func decide_action(public_info: RoundPublicInfo) -> int:
	if public_info.recent_cooperation_rates.is_empty():
		return COOPERATE

	if public_info.last_cooperation_rate >= cooperation_threshold:
		bad_round_count = 0
		return COOPERATE

	bad_round_count += 1
	if bad_round_count < bad_round_threshold and randf() < forgiveness_probability:
		return COOPERATE
	return DEFECT
