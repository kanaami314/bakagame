extends Node2D

var _started := false
var _blink_timer := 0.0
var _prompt: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08)
	bg.size = Vector2(320, 224)
	add_child(bg)

	var title := Label.new()
	title.text = "勇者よ、常識を疑え。"
	title.position = Vector2(30, 70)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "―― 死んで覚える王道RPG ――"
	subtitle.position = Vector2(52, 100)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	add_child(subtitle)

	_prompt = Label.new()
	_prompt.text = "ENTER キーで はじめる"
	_prompt.position = Vector2(90, 160)
	_prompt.add_theme_font_size_override("font_size", 10)
	_prompt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(_prompt)

	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var footer := Label.new()
	footer.text = "Bakagame Project ― v%s" % version
	footer.position = Vector2(80, 200)
	footer.add_theme_font_size_override("font_size", 7)
	footer.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	add_child(footer)


func _process(delta: float) -> void:
	_blink_timer += delta
	if _prompt:
		_prompt.visible = fmod(_blink_timer, 1.0) < 0.6

	if _started:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_started = true
		GameState.start_new_game()
		GameState.travel_to("res://scenes/Prologue.tscn", "start")
