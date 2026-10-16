extends GutTest

var brush: Brush


func before_each():
	brush = Brush.new()
	brush.original_stamp = load("res://assets/brush_templates/big_circle.png")


func test_default_width_is_int():
	assert_typeof(brush.width, TYPE_INT, "Brush width is an integer")


func test_width_truncates_float():
	brush.width = 2.9
	assert_eq(brush.width, 2, "Float assignment is stored as an integer")


func test_stamp_size_is_whole_pixels():
	for w in [1, 3, 17]:
		brush.width = w
		var tex = brush.generate_stamp()
		var expected = 8 * max(w * 2, 10)
		assert_eq(tex.get_width(), expected, "Stamp width at %dpx" % w)
		assert_eq(tex.get_height(), expected, "Stamp height at %dpx" % w)
