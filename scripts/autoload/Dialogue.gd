extends CanvasLayer
## どこからでも呼べる会話ウィンドウ。
## 使い方: await Dialogue.say("セレナ", "お待たせしました。")
##         var i := await Dialogue.choice("買いますか?", ["はい", "いいえ"])

const PANEL_POS := Vector2(8, 148)
const PANEL_SIZE := Vector2(304, 68)

var _border: ColorRect
var _panel: ColorRect
var _name_label: Label
var _text_label: Label
var _choice_root: Control
var _choice_labels: Array[Label] = []
var _choice_index := 0
var _choice_result := -1
var _waiting_advance := false
var _waiting_choice := false


func _ready() -> void:
	layer = 50
	_build_ui()
	_set_box_visible(false)


func _build_ui() -> void:
	_border = ColorRect.new()
	_border.color = Color(0.75, 0.68, 0.45)
	_border.position = PANEL_POS - Vector2(2, 2)
	_border.size = PANEL_SIZE + Vector2(4, 4)
	add_child(_border)

	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.05, 0.12, 0.95)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)

	_name_label = Label.new()
	_name_label.position = PANEL_POS + Vector2(6, 2)
	_name_label.add_theme_font_size_override("font_size", 9)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	add_child(_name_label)

	_text_label = Label.new()
	_text_label.position = PANEL_POS + Vector2(6, 16)
	_text_label.size = Vector2(PANEL_SIZE.x - 12, PANEL_SIZE.y - 20)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_label.add_theme_font_size_override("font_size", 9)
	_text_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	add_child(_text_label)

	_choice_root = Control.new()
	_choice_root.position = PANEL_POS + Vector2(150, 4)
	add_child(_choice_root)


func _set_box_visible(v: bool) -> void:
	_border.visible = v
	_panel.visible = v
	_name_label.visible = v
	_text_label.visible = v


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
	_choice_labels[_choice_index].add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_choice_index = wrapi(_choice_index + delta, 0, _choice_labels.size())
	_choice_labels[_choice_index].add_theme_color_override("font_color", Color(1, 0.9, 0.3))


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
	for c in _choice_labels:
		c.queue_free()
	_choice_labels.clear()
	for i in options.size():
		var lbl := Label.new()
		lbl.text = "・" + str(options[i])
		lbl.position = Vector2(0, i * 14)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		_choice_root.add_child(lbl)
		_choice_labels.append(lbl)
	_choice_index = 0
	_choice_labels[0].add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	_choice_result = -1
	_waiting_choice = true
	while _waiting_choice:
		await get_tree().process_frame
	_set_box_visible(false)
	return _choice_result
