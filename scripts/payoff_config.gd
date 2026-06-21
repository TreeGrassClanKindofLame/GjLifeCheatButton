class_name PayoffConfig
extends RefCounted

enum PayoffMode {
	ORIGINAL_EXTREME,
	LINEAR_DECAY,
	EXPONENTIAL_DECAY,
	CUSTOM_TABLE,
}

var full_cooperation_payoff: float = 50.0
var betrayal_cooperator_payoff: float = 0.0
var all_defect_payoff: float = 0.0

var payoff_mode: int = PayoffMode.EXPONENTIAL_DECAY

var betrayal_efficiency: float = 0.75
var collapse_severity: float = 1.0
var min_pool_ratio: float = 0.0
var temptation_multiplier: float = 1.5

var force_all_coop_best_total: bool = true
var force_all_defect_zero: bool = true
var force_defector_above_full_coop_payoff: bool = false

var custom_total_pool_ratios: Array[float] = [1.0, 0.9, 0.65, 0.35, 0.1, 0.0]


func duplicate_config():
	var config = get_script().new()
	config.full_cooperation_payoff = full_cooperation_payoff
	config.betrayal_cooperator_payoff = betrayal_cooperator_payoff
	config.all_defect_payoff = all_defect_payoff
	config.payoff_mode = payoff_mode
	config.betrayal_efficiency = betrayal_efficiency
	config.collapse_severity = collapse_severity
	config.min_pool_ratio = min_pool_ratio
	config.temptation_multiplier = temptation_multiplier
	config.force_all_coop_best_total = force_all_coop_best_total
	config.force_all_defect_zero = force_all_defect_zero
	config.force_defector_above_full_coop_payoff = force_defector_above_full_coop_payoff
	config.custom_total_pool_ratios = custom_total_pool_ratios.duplicate()
	return config
