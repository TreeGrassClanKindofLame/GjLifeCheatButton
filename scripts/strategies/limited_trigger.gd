class_name LimitedTriggerStrategy
extends StrategyBase

var memory_window: int = 3
var cooperation_threshold: float = 0.5
var punishment_rounds: int = 3
var punishment_remaining: int = 0


func _init() -> void:
	strategy_name = "有限触发"


func reset() -> void:
	punishment_remaining = 0


func decide_action(public_info: RoundPublicInfo) -> int:
	if punishment_remaining > 0:
		punishment_remaining -= 1
		return DEFECT

	if public_info.recent_cooperation_rates.size() < memory_window:
		return COOPERATE

	if _average_recent(public_info.recent_cooperation_rates, memory_window) < cooperation_threshold:
		punishment_remaining = max(0, punishment_rounds - 1)
		return DEFECT

	return COOPERATE


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
