class_name RoundPublicInfo
extends RefCounted

var round_index: int = 0
var participant_count: int = 0
var last_cooperators_count: int = 0
var last_defectors_count: int = 0
var last_cooperation_rate: float = 0.0
var last_total_payoff: float = 0.0
var last_average_payoff: float = 0.0
var historical_average_cooperation_rate: float = 0.0
var recent_cooperation_rates: Array[float] = []
var my_last_action: int = -1
var my_last_payoff: float = 0.0
var my_total_score: float = 0.0
var my_cooperation_count: int = 0
var my_defection_count: int = 0
var full_cooperation_payoff: float = 10.0

