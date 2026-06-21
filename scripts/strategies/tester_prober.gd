class_name TesterProberStrategy
extends StrategyBase

var probe_probability: float = 0.1
var exploit_threshold: float = -1.0
var memory_window: int = 5
var cooperation_threshold: float = 0.6


func _init() -> void:
	strategy_name = "试探者"


func decide_action(public_info: RoundPublicInfo) -> int:
	var base_action := COOPERATE
	if public_info.recent_cooperation_rates.size() >= memory_window:
		if _average_recent(public_info.recent_cooperation_rates, memory_window) < cooperation_threshold:
			base_action = DEFECT

	if randf() < probe_probability:
		return DEFECT
	return base_action


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
