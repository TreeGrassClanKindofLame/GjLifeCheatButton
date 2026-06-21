class_name AlwaysDefectStrategy
extends StrategyBase


func _init() -> void:
	strategy_name = "永远背叛"


func decide_action(_public_info: RoundPublicInfo) -> int:
	return DEFECT
