extends CanvasLayer
## 名前入力ウィンドウ。
## 使い方: var name := await NameEntry.ask("そなたの名を聞かせてくれ", "勇者")
##
## 文字を1文字ずつ選ばせる旧来の方式ではなく LineEdit を使う。
## 日本語入力(IME)を自前で作るのは現実的でないため。

const MAX_LENGTH := 8
const PANEL_POS := Vector2(60, 84)
const PANEL_SIZE := Vector2(200, 56)

var _border: ColorRect
var _panel: ColorRect
var _prompt: Label
var _hint: Label
var _edit: LineEdit

var _waiting := false
var _result := ""
var _default := ""


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_visible(false)


func _build_ui() -> void:
	_border = ColorRect.new()
	_border.color = Color(0.75, 0.68, 0.45)
	_border.position = PANEL_POS - Vector2(2, 2)
	_border.size = PANEL_SIZE + Vector2(4, 4)
	add_child(_border)

	_panel = ColorRect.new()
	_panel.color = Color(0.05, 0.05, 0.12, 0.98)
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)

	_prompt = Label.new()
	_prompt.position = PANEL_POS + Vector2(8, 5)
	_prompt.size = Vector2(PANEL_SIZE.x - 16, 14)
	_prompt.add_theme_font_size_override("font_size", 9)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	add_child(_prompt)

	_edit = LineEdit.new()
	_edit.position = PANEL_POS + Vector2(8, 22)
	_edit.size = Vector2(PANEL_SIZE.x - 16, 16)
	_edit.max_length = MAX_LENGTH
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.add_theme_font_size_override("font_size", 11)
	_edit.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_edit.add_theme_color_override("caret_color", Color(1, 0.9, 0.3))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.2)
	style.border_color = Color(0.5, 0.46, 0.34)
	style.set_border_width_all(1)
	_edit.add_theme_stylebox_override("normal", style)
	_edit.add_theme_stylebox_override("focus", style)
	_edit.text_submitted.connect(_on_submitted)
	add_child(_edit)

	_hint = Label.new()
	_hint.position = PANEL_POS + Vector2(8, 41)
	_hint.size = Vector2(PANEL_SIZE.x - 16, 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72))
	_hint.text = "名前を入力して Enter"
	add_child(_hint)


func _set_visible(v: bool) -> void:
	_border.visible = v
	_panel.visible = v
	_prompt.visible = v
	_edit.visible = v
	_hint.visible = v


func is_active() -> bool:
	return _waiting


func ask(prompt: String, default_name: String) -> String:
	_default = default_name
	_prompt.text = prompt
	_edit.text = default_name
	_set_visible(true)
	_edit.grab_focus()
	_edit.select_all()
	_waiting = true
	while _waiting:
		await get_tree().process_frame
	_set_visible(false)
	_edit.release_focus()
	return _result


func _on_submitted(text: String) -> void:
	if not _waiting:
		return
	var trimmed := text.strip_edges()
	_result = trimmed if trimmed != "" else _default
	_waiting = false
