class_name AlwaysCooperateStrategy
extends StrategyBase


func _init() -> void:
	strategy_name = "永远合作"


func decide_action(_public_info: RoundPublicInfo) -> int:
	return COOPERATE
