extends GutTest

var eraser: Eraser


func before_each():
	eraser = Eraser.new()
	eraser.original_stamp = load("res://assets/brush_templates/big_circle.png")


func test_default_width_is_int():
	assert_typeof(eraser.width, TYPE_INT, "Eraser width is an integer")


func test_width_truncates_float():
	eraser.width = 2.9
	assert_eq(eraser.width, 2, "Float assignment is stored as an integer")


func test_filter_size_is_whole_pixels():
	for w in [1, 3, 17]:
		eraser.width = w
		var tex = eraser.generate_filter()
		var expected = 8 * max(w * 2, 10)
		assert_eq(tex.get_width(), expected, "Filter width at %dpx" % w)
		assert_eq(tex.get_height(), expected, "Filter height at %dpx" % w)
