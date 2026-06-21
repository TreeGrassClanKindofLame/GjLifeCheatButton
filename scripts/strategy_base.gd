class_name StrategyBase
extends RefCounted

const COOPERATE := 0
const DEFECT := 1

var strategy_name: String = "基础策略"


func decide_action(_public_info: RoundPublicInfo) -> int:
	return COOPERATE


func reset() -> void:
	pass


static func action_to_string(action: int) -> String:
	if action == COOPERATE:
		return "合作"
	if action == DEFECT:
		return "背叛"
	return "无"
