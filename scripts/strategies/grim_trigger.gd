class_name GrimTriggerStrategy
extends StrategyBase

var cooperation_threshold: float = 1.0
var triggered: bool = false


func _init() -> void:
	strategy_name = "冷酷触发"


func reset() -> void:
	triggered = false


func decide_action(public_info: RoundPublicInfo) -> int:
	if triggered:
		return DEFECT
	if public_info.recent_cooperation_rates.is_empty():
		return COOPERATE
	if public_info.last_cooperation_rate < cooperation_threshold:
		triggered = true
		return DEFECT
	return COOPERATE
