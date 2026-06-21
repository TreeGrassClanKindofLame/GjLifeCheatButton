class_name WinStayLoseShiftStrategy
extends StrategyBase

var aspiration_level: float = -1.0


func _init() -> void:
	strategy_name = "赢留输变"


func decide_action(public_info: RoundPublicInfo) -> int:
	if public_info.my_last_action != COOPERATE and public_info.my_last_action != DEFECT:
		return COOPERATE

	var target := aspiration_level
	if target < 0.0:
		target = public_info.full_cooperation_payoff

	if public_info.my_last_payoff >= target:
		return public_info.my_last_action

	if public_info.my_last_action == COOPERATE:
		return DEFECT
	return COOPERATE
