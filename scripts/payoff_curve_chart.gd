class_name PayoffCurveChart
extends Control

var chart_title: String = ""
var x_values: Array[float] = []
var y_values: Array[float] = []
var line_color: Color = Color(0.35, 0.75, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(0, 150)


func set_data(new_title: String, new_x_values: Array[float], new_y_values: Array[float], new_line_color: Color) -> void:
	chart_title = new_title
	x_values = new_x_values
	y_values = new_y_values
	line_color = new_line_color
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.17, 0.17, 0.17, 1.0), true)
	draw_rect(rect, Color(0.36, 0.36, 0.36, 1.0), false, 1.0)

	var title_font := get_theme_default_font()
	var title_size := 15
	draw_string(title_font, Vector2(10, 22), chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE)

	var plot := Rect2(42, 34, max(1.0, size.x - 58.0), max(1.0, size.y - 58.0))
	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, Color(0.72, 0.72, 0.72, 1.0), 1.0)
	draw_line(plot.position, Vector2(plot.position.x, plot.end.y), Color(0.72, 0.72, 0.72, 1.0), 1.0)

	if x_values.is_empty() or y_values.is_empty():
		draw_string(title_font, plot.position + Vector2(12, 32), "暂无数据", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8, 1.0))
		return

	var min_x := x_values[0]
	var max_x := x_values[0]
	var min_y := y_values[0]
	var max_y := y_values[0]
	for i in range(x_values.size()):
		min_x = min(min_x, x_values[i])
		max_x = max(max_x, x_values[i])
		min_y = min(min_y, y_values[i])
		max_y = max(max_y, y_values[i])

	if is_equal_approx(max_x, min_x):
		max_x = min_x + 1.0
	if is_equal_approx(max_y, min_y):
		max_y = min_y + 1.0
	if min_y > 0.0:
		min_y = 0.0

	var points: Array[Vector2] = []
	for i in range(x_values.size()):
		var x_rate := (x_values[i] - min_x) / (max_x - min_x)
		var y_rate := (y_values[i] - min_y) / (max_y - min_y)
		var point := Vector2(
			plot.position.x + x_rate * plot.size.x,
			plot.end.y - y_rate * plot.size.y
		)
		points.append(point)

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, 2.0)
	for point in points:
		draw_circle(point, 3.0, line_color)

	var label_color := Color(0.82, 0.82, 0.82, 1.0)
	draw_string(title_font, Vector2(plot.position.x, size.y - 8), "合作人数", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_color)
	draw_string(title_font, Vector2(6, plot.position.y + 12), PayoffCalculator.format_amount(max_y), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_color)
	draw_string(title_font, Vector2(6, plot.end.y), PayoffCalculator.format_amount(min_y), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_color)
	draw_string(title_font, Vector2(plot.position.x, plot.end.y + 16), PayoffCalculator.format_amount(min_x), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_color)
	draw_string(title_font, Vector2(plot.end.x - 24, plot.end.y + 16), PayoffCalculator.format_amount(max_x), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_color)

