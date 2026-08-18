extends CanvasLayer
## どこからでも呼べる会話ウィンドウ。
## 使い方: await Dialogue.say("セレナ", "お待たせしました。")
##         var i := await Dialogue.choice("買いますか?", ["はい", "いいえ"])
##
## 選択肢は会話ウィンドウの中ではなく、その上に出る独立したウィンドウに描く。
## 同じ枠内に重ねると本文と選択肢が確実に重なってしまうため。

const SCREEN_SIZE := Vector2(320, 224)

const PANEL_POS := Vector2(8, 148)
const PANEL_SIZE := Vector2(304, 68)
const TEXT_SIZE := 9

const CHOICE_FONT_SIZE := 10
const CHOICE_ITEM_H := 13
const CHOICE_PAD := 5
const CHOICE_CURSOR_W := 11
const CHOICE_GAP := 8 # 会話ウィンドウとの間隔(枠同士が接しない程度に空ける)

const COLOR_FRAME := Color(0.75, 0.68, 0.45)
const COLOR_FILL := Color(0.05, 0.05, 0.12, 0.96)
const COLOR_TEXT := Color(0.92, 0.92, 0.95)
const COLOR_DIM := Color(0.72, 0.72, 0.78)
const COLOR_HILITE := Color(1.0, 0.9, 0.3)

var _border: ColorRect
var _panel: ColorRect
var _name_label: Label
var _text_label: Label

var _choice_border: ColorRect
var _choice_panel: ColorRect
var _choice_root: Control
var _choice_cursor: Label
var _choice_labels: Array[Label] = []

var _choice_index := 0
var _choice_item_h := float(CHOICE_ITEM_H)
var _choice_result := -1
var _waiting_advance := false
var _waiting_choice := false


func _ready() -> void:
	layer = 50
	_build_ui()
	_set_box_visible(false)
	_set_choice_visible(false)


func _build_ui() -> void:
	_border = ColorRect.new()
	_border.color = COLOR_FRAME
	_border.position = PANEL_POS - Vector2(2, 2)
	_border.size = PANEL_SIZE + Vector2(4, 4)
	add_child(_border)

	_panel = ColorRect.new()
	_panel.color = COLOR_FILL
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)

	_name_label = Label.new()
	_name_label.position = PANEL_POS + Vector2(6, 2)
	_name_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	add_child(_name_label)

	_text_label = Label.new()
	_text_label.position = PANEL_POS + Vector2(6, 16)
	_text_label.size = Vector2(PANEL_SIZE.x - 12, PANEL_SIZE.y - 20)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_text_label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(_text_label)

	# 会話ウィンドウより後に追加して、必ず手前へ描かれるようにする。
	_choice_border = ColorRect.new()
	_choice_border.color = COLOR_FRAME
	add_child(_choice_border)

	_choice_panel = ColorRect.new()
	_choice_panel.color = COLOR_FILL
	add_child(_choice_panel)

	_choice_root = Control.new()
	add_child(_choice_root)

	_choice_cursor = Label.new()
	_choice_cursor.text = ">"
	_choice_cursor.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
	_choice_cursor.add_theme_color_override("font_color", COLOR_HILITE)
	_choice_root.add_child(_choice_cursor)


func _set_box_visible(v: bool) -> void:
	_border.visible = v
	_panel.visible = v
	_name_label.visible = v
	_text_label.visible = v


func _set_choice_visible(v: bool) -> void:
	_choice_border.visible = v
	_choice_panel.visible = v
	_choice_root.visible = v


func is_active() -> bool:
	return _waiting_advance or _waiting_choice


func _input(event: InputEvent) -> void:
	if _waiting_advance and event.is_action_pressed("ui_accept"):
		_waiting_advance = false
		get_viewport().set_input_as_handled()
	elif _waiting_choice:
		if event.is_action_pressed("ui_down"):
			_move_choice(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_choice(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_choice_result = _choice_index
			_waiting_choice = false
			get_viewport().set_input_as_handled()


func _move_choice(delta: int) -> void:
	if _choice_labels.is_empty():
		return
	_choice_index = wrapi(_choice_index + delta, 0, _choice_labels.size())
	_refresh_choice_highlight()


func _refresh_choice_highlight() -> void:
	for i in _choice_labels.size():
		var col := COLOR_HILITE if i == _choice_index else COLOR_DIM
		_choice_labels[i].add_theme_color_override("font_color", col)
	_choice_cursor.position = Vector2(CHOICE_PAD, CHOICE_PAD + _choice_index * _choice_item_h)


func say(speaker: String, text: String) -> void:
	_set_box_visible(true)
	_name_label.text = speaker
	_text_label.text = text
	_waiting_advance = true
	EventBus.dialogue_started.emit(speaker, text)
	while _waiting_advance:
		await get_tree().process_frame
	_set_box_visible(false)
	EventBus.dialogue_ended.emit()


func say_lines(speaker: String, lines: Array) -> void:
	for line in lines:
		await say(speaker, str(line))


func choice(prompt: String, options: Array) -> int:
	_set_box_visible(true)
	_name_label.text = ""
	_text_label.text = prompt
	_layout_choices(options)
	_set_choice_visible(true)

	_choice_index = 0
	_refresh_choice_highlight()
	_choice_result = -1
	_waiting_choice = true
	while _waiting_choice:
		await get_tree().process_frame

	_set_choice_visible(false)
	_set_box_visible(false)
	return _choice_result


## 選択肢ウィンドウを会話ウィンドウの真上へ、右端を揃えて配置する。
func _layout_choices(options: Array) -> void:
	for lbl in _choice_labels:
		_choice_root.remove_child(lbl)
		lbl.queue_free()
	_choice_labels.clear()

	# 日本語はフォントのフォールバックで描画されるため、Font から直接測ると
	# 実際の描画幅とずれる。ラベル自身に必要な大きさを測らせる。
	var widest := 0.0
	var item_h := float(CHOICE_ITEM_H)
	for i in options.size():
		var lbl := Label.new()
		lbl.text = str(options[i])
		lbl.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		_choice_root.add_child(lbl)
		_choice_labels.append(lbl)
		var min_size := lbl.get_minimum_size()
		widest = maxf(widest, min_size.x)
		item_h = maxf(item_h, min_size.y)

	var panel_size := Vector2(
		widest + CHOICE_PAD * 2 + CHOICE_CURSOR_W,
		options.size() * item_h + CHOICE_PAD * 2
	)
	var pos := Vector2(
		PANEL_POS.x + PANEL_SIZE.x - panel_size.x,
		PANEL_POS.y - panel_size.y - CHOICE_GAP
	)
	# 画面外へはみ出さないように寄せる
	pos.x = clampf(pos.x, 4.0, SCREEN_SIZE.x - panel_size.x - 4.0)
	pos.y = maxf(pos.y, 4.0)

	_choice_panel.position = pos
	_choice_panel.size = panel_size
	_choice_border.position = pos - Vector2(2, 2)
	_choice_border.size = panel_size + Vector2(4, 4)
	_choice_root.position = pos
	_choice_item_h = item_h

	for i in _choice_labels.size():
		_choice_labels[i].position = Vector2(CHOICE_PAD + CHOICE_CURSOR_W, CHOICE_PAD + i * item_h)
