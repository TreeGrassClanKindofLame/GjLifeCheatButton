extends Control

const GameManagerLib := preload("res://scripts/game_manager.gd")
const PayoffCalculatorLib := preload("res://scripts/payoff_calculator.gd")
const PayoffConfigLib := preload("res://scripts/payoff_config.gd")
const StrategyBaseLib := preload("res://scripts/strategy_base.gd")

var manager := GameManagerLib.new()
var participant_count_input: LineEdit
var total_rounds_input: LineEdit
var auto_delay_input: LineEdit
var payoff_mode_option: OptionButton
var full_payoff_input: LineEdit
var betrayal_cooperator_payoff_input: LineEdit
var all_defect_payoff_input: LineEdit
var betrayal_efficiency_input: LineEdit
var collapse_severity_input: LineEdit
var min_pool_ratio_input: LineEdit
var temptation_multiplier_input: LineEdit
var custom_table_input: LineEdit
var force_all_coop_best_total_check: CheckBox
var force_all_defect_zero_check: CheckBox
var force_defector_above_full_coop_payoff_check: CheckBox
var payoff_warning_output: RichTextLabel
var stats_labels := {}
var strategy_controls_box: VBoxContainer
var participant_stats_output: RichTextLabel
var history_output: RichTextLabel
var payoff_title_label: Label
var payoff_tables_box: VBoxContainer
var auto_timer: Timer
var is_refreshing_strategy_controls := false
var is_building_payoff_ui := false


func _ready() -> void:
	randomize()
	_build_ui()
	_on_generate_participants_pressed()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.23, 0.23, 0.23, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	auto_timer = Timer.new()
	auto_timer.one_shot = false
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	add_child(auto_timer)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "多人匿名囚徒困境模型验证器"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	_build_settings_section(root)
	_build_payoff_section(root)
	_build_controls_section(root)
	_build_stats_section(root)
	_build_strategy_controls_section(root)
	_build_participant_stats_section(root)
	_build_history_section(root)


func _build_settings_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "设置"
	root.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	participant_count_input = _add_labeled_input(grid, "参与人数", "10")
	participant_count_input.text_changed.connect(_on_payoff_config_changed)
	total_rounds_input = _add_labeled_input(grid, "总模拟轮数", "100")
	auto_delay_input = _add_labeled_input(grid, "自动运行间隔", "0.25")

	var generate_button := Button.new()
	generate_button.text = "生成参与者"
	generate_button.pressed.connect(_on_generate_participants_pressed)
	root.add_child(generate_button)


func _build_controls_section(root: VBoxContainer) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var start_button := Button.new()
	start_button.text = "开始自动模拟"
	start_button.pressed.connect(_on_start_auto_pressed)
	row.add_child(start_button)

	var pause_button := Button.new()
	pause_button.text = "暂停"
	pause_button.pressed.connect(_on_pause_pressed)
	row.add_child(pause_button)

	var step_button := Button.new()
	step_button.text = "单步执行一轮"
	step_button.pressed.connect(_on_step_pressed)
	row.add_child(step_button)

	var reset_button := Button.new()
	reset_button.text = "重置"
	reset_button.pressed.connect(_on_reset_pressed)
	row.add_child(reset_button)


func _build_stats_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "回合概览"
	root.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	for key in [
		"当前轮数",
		"本轮合作人数",
		"本轮背叛人数",
		"本轮合作率",
		"本轮全体总收益",
		"本轮平均收益",
		"历史平均合作率",
		"当前最高分参与者",
		"当前最低分参与者",
	]:
		var name_label := Label.new()
		name_label.text = key
		grid.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "-"
		stats_labels[key] = value_label
		grid.add_child(value_label)


func _build_strategy_controls_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "参与者策略"
	root.add_child(title)

	strategy_controls_box = VBoxContainer.new()
	strategy_controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(strategy_controls_box)


func _build_participant_stats_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "参与者列表"
	root.add_child(title)

	participant_stats_output = RichTextLabel.new()
	participant_stats_output.custom_minimum_size = Vector2(0, 220)
	participant_stats_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(participant_stats_output)


func _build_history_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "最近 20 轮"
	root.add_child(title)

	history_output = RichTextLabel.new()
	history_output.custom_minimum_size = Vector2(0, 180)
	history_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(history_output)


func _build_payoff_section(root: VBoxContainer) -> void:
	is_building_payoff_ui = true

	var title := Label.new()
	title.text = "收益规则设置"
	root.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	var mode_label := Label.new()
	mode_label.text = "收益模式"
	grid.add_child(mode_label)

	payoff_mode_option = OptionButton.new()
	payoff_mode_option.add_item("Original Extreme（原始极端）", PayoffConfigLib.PayoffMode.ORIGINAL_EXTREME)
	payoff_mode_option.add_item("Linear Decay（线性衰减）", PayoffConfigLib.PayoffMode.LINEAR_DECAY)
	payoff_mode_option.add_item("Exponential Decay（指数衰减）", PayoffConfigLib.PayoffMode.EXPONENTIAL_DECAY)
	payoff_mode_option.add_item("Custom Table（自定义表）", PayoffConfigLib.PayoffMode.CUSTOM_TABLE)
	payoff_mode_option.select(2)
	payoff_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	payoff_mode_option.item_selected.connect(_on_payoff_config_changed)
	grid.add_child(payoff_mode_option)

	full_payoff_input = _add_labeled_input(grid, "full_cooperation_payoff", "50.0")
	betrayal_cooperator_payoff_input = _add_labeled_input(grid, "betrayal_cooperator_payoff", "0.0")
	all_defect_payoff_input = _add_labeled_input(grid, "all_defect_payoff", "0.0")
	betrayal_efficiency_input = _add_labeled_input(grid, "betrayal_efficiency", "0.75")
	collapse_severity_input = _add_labeled_input(grid, "collapse_severity", "1.0")
	min_pool_ratio_input = _add_labeled_input(grid, "min_pool_ratio", "0.0")
	temptation_multiplier_input = _add_labeled_input(grid, "temptation_multiplier", "1.5")
	custom_table_input = _add_labeled_input(grid, "custom_total_pool_ratios", "1.0, 0.9, 0.65, 0.35, 0.1, 0.0")

	for input in [
		full_payoff_input,
		betrayal_cooperator_payoff_input,
		all_defect_payoff_input,
		betrayal_efficiency_input,
		collapse_severity_input,
		min_pool_ratio_input,
		temptation_multiplier_input,
		custom_table_input,
	]:
		input.text_changed.connect(_on_payoff_config_changed)

	var checks := VBoxContainer.new()
	checks.add_theme_constant_override("separation", 4)
	root.add_child(checks)

	force_all_coop_best_total_check = _add_payoff_checkbox(checks, "全员合作总收益必须最高", true)
	force_all_defect_zero_check = _add_payoff_checkbox(checks, "强制全员背叛收益为 0", true)
	force_defector_above_full_coop_payoff_check = _add_payoff_checkbox(checks, "要求部分背叛时背叛者每人收益高于 C", false)

	var button_row := HFlowContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	var current_payoff_button := Button.new()
	current_payoff_button.text = "生成当前人数收益表"
	current_payoff_button.pressed.connect(_on_generate_payoff_table_pressed)
	button_row.add_child(current_payoff_button)

	var warning_title := Label.new()
	warning_title.text = "参数警告"
	root.add_child(warning_title)

	payoff_warning_output = RichTextLabel.new()
	payoff_warning_output.custom_minimum_size = Vector2(0, 86)
	payoff_warning_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(payoff_warning_output)

	var table_title := Label.new()
	table_title.text = "收益表预览"
	root.add_child(table_title)

	payoff_title_label = Label.new()
	payoff_title_label.text = "点击“生成当前人数收益表”查看数据"
	root.add_child(payoff_title_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)

	payoff_tables_box = VBoxContainer.new()
	payoff_tables_box.add_theme_constant_override("separation", 12)
	scroll.add_child(payoff_tables_box)

	is_building_payoff_ui = false


func _add_labeled_input(parent: GridContainer, label_text: String, default_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)

	var input := LineEdit.new()
	input.text = default_text
	input.custom_minimum_size = Vector2(180, 0)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(input)
	return input


func _add_payoff_checkbox(parent: VBoxContainer, text: String, pressed: bool) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = pressed
	checkbox.toggled.connect(_on_payoff_config_changed)
	parent.add_child(checkbox)
	return checkbox


func _on_generate_participants_pressed() -> void:
	auto_timer.stop()
	var selected_names := _collect_selected_strategy_names()
	manager.setup(
		_read_int(participant_count_input, 10, 1),
		_read_int(total_rounds_input, 100, 1),
		_read_payoff_config_from_ui(),
		selected_names
	)
	_rebuild_strategy_controls()
	_refresh_all()
	_refresh_payoff_preview_current()


func _on_start_auto_pressed() -> void:
	_sync_settings_without_regenerating()
	if manager.is_finished():
		return
	auto_timer.wait_time = _read_float(auto_delay_input, 0.25, 0.01)
	auto_timer.start()


func _on_pause_pressed() -> void:
	auto_timer.stop()


func _on_step_pressed() -> void:
	auto_timer.stop()
	_run_one_step()


func _on_reset_pressed() -> void:
	auto_timer.stop()
	_sync_settings_without_regenerating()
	manager.reset_simulation()
	_refresh_all()


func _on_generate_payoff_table_pressed() -> void:
	_sync_settings_without_regenerating()
	_refresh_payoff_preview_current()


func _on_auto_timer_timeout() -> void:
	_run_one_step()
	if manager.is_finished():
		auto_timer.stop()


func _run_one_step() -> void:
	_sync_settings_without_regenerating()
	if manager.is_finished():
		return
	manager.step_round()
	_refresh_all()


func _sync_settings_without_regenerating() -> void:
	manager.participant_count = _read_int(participant_count_input, manager.participant_count, 1)
	manager.total_rounds = _read_int(total_rounds_input, manager.total_rounds, 1)
	manager.payoff_config = _read_payoff_config_from_ui()


func _collect_selected_strategy_names() -> Array[String]:
	var names: Array[String] = []
	if strategy_controls_box == null:
		return names
	for row in strategy_controls_box.get_children():
		for child in row.get_children():
			if child is OptionButton:
				var option := child as OptionButton
				names.append(option.get_item_text(option.selected))
	return names


func _rebuild_strategy_controls() -> void:
	is_refreshing_strategy_controls = true
	for child in strategy_controls_box.get_children():
		child.queue_free()

	for i in range(manager.participants.size()):
		var participant = manager.participants[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		strategy_controls_box.add_child(row)

		var label := Label.new()
		label.text = "参与者%d" % participant.id
		label.custom_minimum_size = Vector2(44, 0)
		row.add_child(label)

		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for strategy_name in GameManagerLib.STRATEGY_NAMES:
			option.add_item(strategy_name)
		var selected_index := GameManagerLib.STRATEGY_NAMES.find(participant.strategy.strategy_name)
		option.selected = max(0, selected_index)
		option.item_selected.connect(_on_strategy_selected.bind(i, option))
		row.add_child(option)

	is_refreshing_strategy_controls = false


func _on_strategy_selected(_selected_item: int, participant_index: int, option: OptionButton) -> void:
	if is_refreshing_strategy_controls:
		return
	manager.set_strategy_for_participant(participant_index, option.get_item_text(option.selected))
	_refresh_all()


func _refresh_all() -> void:
	_refresh_stats()
	_refresh_participant_stats()
	_refresh_history()
	_refresh_payoff_warnings()


func _refresh_stats() -> void:
	var result = manager.last_result
	stats_labels["当前轮数"].text = "%d / %d" % [manager.current_round, manager.total_rounds]
	stats_labels["本轮合作人数"].text = str(result.cooperators_count if result != null else 0)
	stats_labels["本轮背叛人数"].text = str(result.defectors_count if result != null else 0)
	stats_labels["本轮合作率"].text = _format_percent(result.cooperation_rate if result != null else 0.0)
	stats_labels["本轮全体总收益"].text = PayoffCalculatorLib.format_amount(result.total_payoff if result != null else 0.0)
	stats_labels["本轮平均收益"].text = PayoffCalculatorLib.format_amount(result.average_payoff if result != null else 0.0)
	stats_labels["历史平均合作率"].text = _format_percent(manager.get_historical_average_cooperation_rate())

	var highest = manager.get_highest_score_participant()
	var lowest = manager.get_lowest_score_participant()
	stats_labels["当前最高分参与者"].text = _participant_score_text(highest)
	stats_labels["当前最低分参与者"].text = _participant_score_text(lowest)


func _refresh_participant_stats() -> void:
	var lines: Array[String] = []
	lines.append("编号\t策略\t总分\t合作次数\t背叛次数\t最近行动\t最近收益")
	for participant in manager.participants:
		lines.append("%d\t%s\t%s\t%d\t%d\t%s\t%s" % [
			participant.id,
			participant.strategy.strategy_name,
			PayoffCalculatorLib.format_amount(participant.total_score),
			participant.cooperation_count,
			participant.defection_count,
			StrategyBaseLib.action_to_string(participant.last_action),
			PayoffCalculatorLib.format_amount(participant.last_payoff),
		])
	participant_stats_output.text = "\n".join(lines)


func _refresh_history() -> void:
	var lines: Array[String] = []
	lines.append("轮数\t合作人数\t背叛人数\t合作率\t全体总收益\t平均收益")
	for result in manager.get_recent_history(20):
		lines.append("%d\t%d\t%d\t%s\t%s\t%s" % [
			result.round_index,
			result.cooperators_count,
			result.defectors_count,
			_format_percent(result.cooperation_rate),
			PayoffCalculatorLib.format_amount(result.total_payoff),
			PayoffCalculatorLib.format_amount(result.average_payoff),
		])
	history_output.text = "\n".join(lines)


func _on_payoff_config_changed(_value = null) -> void:
	if is_building_payoff_ui:
		return
	_sync_settings_without_regenerating()
	_refresh_payoff_preview_current()
	_refresh_payoff_warnings()


func _refresh_payoff_preview_current() -> void:
	_clear_payoff_tables()
	_render_payoff_table(manager.participant_count)
	_refresh_payoff_warnings()


func _clear_payoff_tables() -> void:
	for child in payoff_tables_box.get_children():
		child.queue_free()


func _render_payoff_table(count: int) -> void:
	var title := Label.new()
	title.text = "%d 人收益表（C = %s，模式 = %s）" % [
		count,
		PayoffCalculatorLib.format_amount(manager.payoff_config.full_cooperation_payoff),
		_get_selected_payoff_mode_name(),
	]
	payoff_tables_box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	payoff_tables_box.add_child(grid)

	payoff_title_label.text = "%d 人收益表（全员合作收益 C = %s）" % [
		manager.participant_count,
		PayoffCalculatorLib.format_amount(manager.payoff_config.full_cooperation_payoff),
	]

	for header in ["总人数", "合作人数", "背叛人数", "合作者每人收益", "背叛者每人收益", "全体总收益"]:
		_add_payoff_cell(grid, header, true)

	for row in manager.build_payoff_table_rows_for_count(count):
		_add_payoff_cell(grid, str(row["participant_count"]), false)
		_add_payoff_cell(grid, str(row["cooperators_count"]), false)
		_add_payoff_cell(grid, str(row["defectors_count"]), false)
		_add_payoff_cell(grid, str(row["cooperator_each"]), false)
		_add_payoff_cell(grid, str(row["defector_each"]), false)
		_add_payoff_cell(grid, str(row["total_payoff"]), false)


func _add_payoff_cell(grid: GridContainer, text: String, is_header: bool) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(116, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.add_theme_font_size_override("font_size", 15)
	else:
		label.add_theme_font_size_override("font_size", 14)
	grid.add_child(label)


func _refresh_payoff_warnings() -> void:
	if payoff_warning_output == null:
		return
	var warnings := manager.validate_payoff_config_for_count(_read_int(participant_count_input, manager.participant_count, 1))
	payoff_warning_output.text = "\n".join(warnings)


func _read_payoff_config_from_ui():
	var config := PayoffConfigLib.new()
	config.full_cooperation_payoff = _read_float(full_payoff_input, 50.0, 0.0)
	config.betrayal_cooperator_payoff = _read_float(betrayal_cooperator_payoff_input, 0.0, -INF)
	config.all_defect_payoff = _read_float(all_defect_payoff_input, 0.0, -INF)
	config.payoff_mode = payoff_mode_option.get_selected_id()
	config.betrayal_efficiency = _read_float(betrayal_efficiency_input, 0.75, 0.0)
	config.collapse_severity = _read_float(collapse_severity_input, 1.0, 0.0)
	config.min_pool_ratio = _read_float(min_pool_ratio_input, 0.0, 0.0)
	config.temptation_multiplier = _read_float(temptation_multiplier_input, 1.5, 0.0)
	config.force_all_coop_best_total = force_all_coop_best_total_check.button_pressed
	config.force_all_defect_zero = force_all_defect_zero_check.button_pressed
	config.force_defector_above_full_coop_payoff = force_defector_above_full_coop_payoff_check.button_pressed
	config.custom_total_pool_ratios = _parse_custom_ratios(custom_table_input.text)
	return config


func _parse_custom_ratios(text: String) -> Array[float]:
	var ratios: Array[float] = []
	for part in text.split(",", false):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			ratios.append(max(0.0, trimmed.to_float()))
	if ratios.is_empty():
		ratios = [1.0, 0.9, 0.65, 0.35, 0.1, 0.0]
	return ratios


func _get_selected_payoff_mode_name() -> String:
	if payoff_mode_option == null:
		return "-"
	return payoff_mode_option.get_item_text(payoff_mode_option.selected)


func _participant_score_text(participant) -> String:
	if participant == null:
		return "-"
	return "参与者%d（%s）" % [participant.id, PayoffCalculatorLib.format_amount(participant.total_score)]


func _format_percent(value: float) -> String:
	return "%s%%" % PayoffCalculatorLib.format_amount(value * 100.0)


func _read_int(input: LineEdit, fallback: int, minimum: int) -> int:
	if input == null:
		return fallback
	return max(minimum, input.text.to_int())


func _read_float(input: LineEdit, fallback: float, minimum: float) -> float:
	if input == null:
		return fallback
	var value := input.text.to_float()
	if is_nan(value):
		return fallback
	return max(minimum, value)
