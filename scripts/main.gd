extends Control

const GameManagerLib := preload("res://scripts/game_manager.gd")
const PayoffCalculatorLib := preload("res://scripts/payoff_calculator.gd")
const StrategyBaseLib := preload("res://scripts/strategy_base.gd")

var manager := GameManagerLib.new()
var participant_count_input: LineEdit
var total_rounds_input: LineEdit
var full_payoff_input: LineEdit
var auto_delay_input: LineEdit
var stats_labels := {}
var strategy_controls_box: VBoxContainer
var participant_stats_output: TextEdit
var history_output: TextEdit
var payoff_title_label: Label
var payoff_table_grid: GridContainer
var auto_timer: Timer
var is_refreshing_strategy_controls := false


func _ready() -> void:
	randomize()
	_build_ui()
	_on_generate_participants_pressed()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

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
	total_rounds_input = _add_labeled_input(grid, "总模拟轮数", "100")
	full_payoff_input = _add_labeled_input(grid, "全员合作收益", "10.0")
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

	participant_stats_output = TextEdit.new()
	participant_stats_output.editable = false
	participant_stats_output.custom_minimum_size = Vector2(0, 220)
	participant_stats_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(participant_stats_output)


func _build_history_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "最近 20 轮"
	root.add_child(title)

	history_output = TextEdit.new()
	history_output.editable = false
	history_output.custom_minimum_size = Vector2(0, 180)
	history_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(history_output)


func _build_payoff_section(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "收益表"
	root.add_child(title)

	var payoff_button := Button.new()
	payoff_button.text = "生成当前人数收益表"
	payoff_button.pressed.connect(_on_generate_payoff_table_pressed)
	root.add_child(payoff_button)

	payoff_title_label = Label.new()
	payoff_title_label.text = "点击“生成当前人数收益表”查看数据"
	root.add_child(payoff_title_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)

	payoff_table_grid = GridContainer.new()
	payoff_table_grid.columns = 6
	payoff_table_grid.add_theme_constant_override("h_separation", 14)
	payoff_table_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(payoff_table_grid)


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


func _on_generate_participants_pressed() -> void:
	auto_timer.stop()
	var selected_names := _collect_selected_strategy_names()
	manager.setup(
		_read_int(participant_count_input, 10, 1),
		_read_int(total_rounds_input, 100, 1),
		_read_float(full_payoff_input, 10.0, 0.0),
		selected_names
	)
	_rebuild_strategy_controls()
	_refresh_all()


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
	_refresh_payoff_table()


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
	manager.total_rounds = _read_int(total_rounds_input, manager.total_rounds, 1)
	manager.full_cooperation_payoff = _read_float(full_payoff_input, manager.full_cooperation_payoff, 0.0)


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


func _refresh_payoff_table() -> void:
	for child in payoff_table_grid.get_children():
		child.queue_free()

	payoff_title_label.text = "%d 人收益表（全员合作收益 C = %s）" % [
		manager.participant_count,
		PayoffCalculatorLib.format_amount(manager.full_cooperation_payoff),
	]

	for header in ["总人数", "合作人数", "背叛人数", "合作者每人收益", "背叛者每人收益", "全体总收益"]:
		_add_payoff_cell(header, true)

	for row in manager.build_payoff_table_rows():
		_add_payoff_cell(str(row["participant_count"]), false)
		_add_payoff_cell(str(row["cooperators_count"]), false)
		_add_payoff_cell(str(row["defectors_count"]), false)
		_add_payoff_cell(str(row["cooperator_each"]), false)
		_add_payoff_cell(str(row["defector_each"]), false)
		_add_payoff_cell(str(row["total_payoff"]), false)


func _add_payoff_cell(text: String, is_header: bool) -> void:
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
	payoff_table_grid.add_child(label)


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
