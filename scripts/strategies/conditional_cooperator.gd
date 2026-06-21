class_name ConditionalCooperatorStrategy
extends StrategyBase

var memory_window: int = 5
var cooperation_threshold: float = 0.6


func _init() -> void:
	strategy_name = "条件合作者"


func decide_action(public_info: RoundPublicInfo) -> int:
	if public_info.recent_cooperation_rates.size() < memory_window:
		return COOPERATE
	if _average_recent(public_info.recent_cooperation_rates, memory_window) >= cooperation_threshold:
		return COOPERATE
	return DEFECT


func _average_recent(values: Array[float], window: int) -> float:
	var start_index: int = max(0, values.size() - window)
	var total := 0.0
	var count := 0
	for i in range(start_index, values.size()):
		total += values[i]
		count += 1
	if count == 0:
		return 1.0
	return total / float(count)
