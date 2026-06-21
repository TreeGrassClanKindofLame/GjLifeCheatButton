class_name RandomDecisionStrategy
extends StrategyBase

var cooperate_probability: float = 0.5


func _init() -> void:
	strategy_name = "随机策略"


func decide_action(_public_info: RoundPublicInfo) -> int:
	if randf() < cooperate_probability:
		return COOPERATE
	return DEFECT
