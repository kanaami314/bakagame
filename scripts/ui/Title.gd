extends Node2D
## タイトル画面。
##
## 文字は必ず画面の中央に置きたいので、ラベルの左端を目分量で決め打ちせず、
## 画面幅いっぱいのラベルに中央揃えを指定する。日本語は文字幅がフォントに
## 依存するため、座標を手で計算すると必ずずれる。

const SCREEN_SIZE := Vector2(320, 224)

var _started := false
var _blink_timer := 0.0
var _prompt: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08)
	bg.size = SCREEN_SIZE
	add_child(bg)

	_add_centered("勇者よ、常識を疑え。", 62, 18, Color(0.95, 0.85, 0.5))
	_add_centered("―― 死んで覚える王道RPG ――", 96, 10, Color(0.8, 0.8, 0.85))
	_prompt = _add_centered("ENTER キーで はじめる", 154, 10, Color(0.9, 0.9, 0.9))

	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	_add_centered("Bakagame Project ― v%s" % version, 200, 7, Color(0.45, 0.45, 0.5))


## 画面幅いっぱいのラベルを作り、その中で文字を中央へ寄せる。
func _add_centered(text: String, y: float, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(SCREEN_SIZE.x, font_size + 6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl


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
