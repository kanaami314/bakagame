extends CanvasLayer
## メニュー画面。マップ上でメニューキーを押すといつでも開ける。
## 持ち物・装備・ステータスを見られる。
##
## 画面は「一覧を選ぶ」の繰り返しなので、汎用の選択リストを1つ用意して
## 使い回している。階層は 主メニュー → 仲間 → 箇所 → 装備品 の最大4段。

const SCREEN_SIZE := Vector2(320, 224)
const FONT_SIZE := 10
const LINE_H := 14
const PAD := 6

const COLOR_FRAME := Color(0.75, 0.68, 0.45)
const COLOR_FILL := Color(0.05, 0.05, 0.12, 0.97)
const COLOR_TEXT := Color(0.88, 0.88, 0.92)
const COLOR_DIM := Color(0.55, 0.55, 0.62)
const COLOR_HILITE := Color(1.0, 0.9, 0.3)

const ROOT_ITEMS := ["もちもの", "そうび", "ステータス", "とじる"]

var _open := false
var _list_active := false
var _index := 0
var _choice := -1
var _details: Array = []
var _labels: Array[Label] = []
var _cursor: Label

var _frame: ColorRect
var _panel: ColorRect
var _title: Label
var _detail: Label
var _footer: Label


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_visible(false)


func _build_ui() -> void:
	_frame = ColorRect.new()
	_frame.color = COLOR_FRAME
	_frame.position = Vector2(6, 6)
	_frame.size = SCREEN_SIZE - Vector2(12, 12)
	add_child(_frame)

	_panel = ColorRect.new()
	_panel.color = COLOR_FILL
	_panel.position = Vector2(8, 8)
	_panel.size = SCREEN_SIZE - Vector2(16, 16)
	add_child(_panel)

	_title = Label.new()
	_title.position = Vector2(8 + PAD, 8 + 2)
	_title.add_theme_font_size_override("font_size", FONT_SIZE)
	_title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	add_child(_title)

	_cursor = Label.new()
	_cursor.text = ">"
	_cursor.add_theme_font_size_override("font_size", FONT_SIZE)
	_cursor.add_theme_color_override("font_color", COLOR_HILITE)
	add_child(_cursor)

	_detail = Label.new()
	_detail.position = Vector2(8 + PAD, 168)
	_detail.size = Vector2(SCREEN_SIZE.x - 16 - PAD * 2, 26)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail.add_theme_font_size_override("font_size", 9)
	_detail.add_theme_color_override("font_color", COLOR_DIM)
	add_child(_detail)

	_footer = Label.new()
	_footer.position = Vector2(8 + PAD, 198)
	_footer.add_theme_font_size_override("font_size", 8)
	_footer.add_theme_color_override("font_color", COLOR_DIM)
	_footer.text = "↑↓:選ぶ  Enter:決定  Esc:もどる"
	add_child(_footer)


func _set_visible(v: bool) -> void:
	_frame.visible = v
	_panel.visible = v
	_title.visible = v
	_cursor.visible = v
	_detail.visible = v
	_footer.visible = v
	for lbl in _labels:
		lbl.visible = v


func is_open() -> bool:
	return _open


func _input(event: InputEvent) -> void:
	if not _list_active:
		return
	if event.is_action_pressed("ui_down"):
		_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_choice = _index
		_list_active = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_choice = -1
		_list_active = false
		get_viewport().set_input_as_handled()


func _move(delta: int) -> void:
	if _labels.is_empty():
		return
	_index = wrapi(_index + delta, 0, _labels.size())
	_refresh_highlight()


func _refresh_highlight() -> void:
	for i in _labels.size():
		_labels[i].add_theme_color_override("font_color", COLOR_HILITE if i == _index else COLOR_TEXT)
	if not _labels.is_empty():
		_cursor.position = _labels[_index].position - Vector2(12, 0)
	_detail.text = String(_details[_index]) if _index < _details.size() else ""


## 一覧を出して1つ選ばせる。Escで抜けた場合は -1 を返す。
func _select(title: String, entries: Array, details: Array = []) -> int:
	_title.text = title
	_details = details
	for lbl in _labels:
		lbl.queue_free()
	_labels.clear()

	for i in entries.size():
		var lbl := Label.new()
		lbl.text = String(entries[i])
		lbl.position = Vector2(8 + PAD + 12, 8 + 20 + i * LINE_H)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_TEXT)
		add_child(lbl)
		_labels.append(lbl)

	_index = 0
	_refresh_highlight()
	_choice = -1
	_list_active = true
	while _list_active:
		await get_tree().process_frame
	return _choice


func open() -> void:
	if _open:
		return
	_open = true
	get_tree().paused = true
	_set_visible(true)
	await _root_loop()
	_set_visible(false)
	get_tree().paused = false
	_open = false


func _root_loop() -> void:
	while true:
		var entries: Array = ROOT_ITEMS.duplicate()
		entries[3] = "とじる  （所持金 %dG）" % PartyData.gold
		var choice: int = await _select("メニュー", entries)
		match choice:
			0:
				await _show_inventory()
			1:
				await _equip_flow()
			2:
				await _show_status()
			_:
				return # とじる または Esc


func _show_inventory() -> void:
	while true:
		var ids: Array = PartyData.inventory.keys()
		ids.sort()
		if ids.is_empty():
			if await _select("もちもの", ["（何も持っていない）"]) < 0:
				return
			return
		var entries: Array = []
		var details: Array = []
		for item_id in ids:
			entries.append("%s ×%d" % [Items.item_name(item_id), int(PartyData.inventory[item_id])])
			details.append(Items.description(item_id))
		if await _select("もちもの", entries, details) < 0:
			return


func _equip_flow() -> void:
	while true:
		var member_id: String = await _pick_member("そうび")
		if member_id == "":
			return
		while true:
			var slot: String = await _pick_slot(member_id)
			if slot == "":
				break
			await _pick_equipment(member_id, slot)


func _pick_member(title: String) -> String:
	var entries: Array = []
	for id in PartyData.active_party:
		entries.append(String(PartyData.members[id]["name"]))
	var choice: int = await _select(title, entries)
	if choice < 0 or choice >= PartyData.active_party.size():
		return ""
	return PartyData.active_party[choice]


func _pick_slot(member_id: String) -> String:
	var member_name := String(PartyData.members[member_id]["name"])
	var entries: Array = []
	for slot in PartyData.EQUIP_SLOTS:
		var item_id := PartyData.equipped(member_id, slot)
		var shown := Items.item_name(item_id) if item_id != "" else "（なし）"
		entries.append("%s : %s" % [PartyData.SLOT_LABELS[slot], shown])
	var title := "%s  こうげき %d / まもり %d" % [
		member_name, PartyData.total_atk(member_id), PartyData.total_def(member_id)
	]
	var choice: int = await _select(title, entries)
	if choice < 0 or choice >= PartyData.EQUIP_SLOTS.size():
		return ""
	return String(PartyData.EQUIP_SLOTS[choice])


func _pick_equipment(member_id: String, slot: String) -> void:
	var candidates: Array = PartyData.equippable_items(member_id, slot)
	var entries: Array = []
	var details: Array = []
	var current := PartyData.equipped(member_id, slot)

	if current != "":
		entries.append("はずす")
		details.append("%s をはずして持ち物へ戻す。" % Items.item_name(current))

	for item_id in candidates:
		var diff := _compare_text(member_id, slot, item_id)
		entries.append("%s%s" % [Items.item_name(item_id), diff])
		details.append(Items.description(item_id))

	if entries.is_empty():
		await _select(PartyData.SLOT_LABELS[slot], ["（つけられる物がない）"])
		return

	var choice: int = await _select(PartyData.SLOT_LABELS[slot], entries, details)
	if choice < 0:
		return
	if current != "" and choice == 0:
		PartyData.unequip(member_id, slot)
		return
	var offset := 1 if current != "" else 0
	PartyData.equip(member_id, String(candidates[choice - offset]))


## 今つけている物との差を「(こうげき +4)」のように表す。
func _compare_text(member_id: String, slot: String, item_id: String) -> String:
	var current := PartyData.equipped(member_id, slot)
	var parts: Array = []
	for stat in ["atk", "def"]:
		var diff := Items.stat_of(item_id, stat) - (Items.stat_of(current, stat) if current != "" else 0)
		if diff != 0:
			var label := "こうげき" if stat == "atk" else "まもり"
			parts.append("%s %s%d" % [label, "+" if diff > 0 else "", diff])
	if parts.is_empty():
		return ""
	return "  (%s)" % ", ".join(parts)


func _show_status() -> void:
	while true:
		var member_id: String = await _pick_member("ステータス")
		if member_id == "":
			return
		var m: Dictionary = PartyData.members[member_id]
		var entries: Array = [
			"レベル      %d" % int(m["level"]),
			"HP          %d / %d" % [int(m["hp"]), int(m["max_hp"])],
			"MP          %d / %d" % [int(m["mp"]), int(m["max_mp"])],
			"こうげき    %d  (素 %d)" % [PartyData.total_atk(member_id), int(m["atk"])],
			"まもり      %d  (素 %d)" % [PartyData.total_def(member_id), int(m["def"])],
		]
		for slot in PartyData.EQUIP_SLOTS:
			var item_id := PartyData.equipped(member_id, slot)
			entries.append("%s        %s" % [
				PartyData.SLOT_LABELS[slot],
				Items.item_name(item_id) if item_id != "" else "（なし）"
			])
		await _select(String(m["name"]), entries)
