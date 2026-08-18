extends CanvasLayer
## パーティ全体で1コマンドを選ぶ簡易ターン制バトル。
## 使い方: var result := await BattleSystem.start_battle(enemy_dict)
## enemy_dict: {id,name,hp,max_hp,atk,def,intro,can_flee,gold_reward,lose_message,flee_blocked_message}

const COMMANDS := ["攻撃", "回復", "アイテム", "にげる"]

var _active := false
var _awaiting_command := false
var _command_index := 0
var _selected_command := -1
var _enemy: Dictionary = {}

var _bg: ColorRect
var _enemy_name_label: Label
var _enemy_hp_bar_bg: ColorRect
var _enemy_hp_bar: ColorRect
var _message_label: Label
var _party_labels: Array[Label] = []
var _command_labels: Array[Label] = []


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func is_active() -> bool:
	return _active


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.08, 0.03, 0.05, 0.97)
	_bg.size = Vector2(320, 224)
	add_child(_bg)

	_enemy_name_label = Label.new()
	_enemy_name_label.position = Vector2(16, 16)
	_enemy_name_label.add_theme_font_size_override("font_size", 11)
	_enemy_name_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.7))
	add_child(_enemy_name_label)

	_enemy_hp_bar_bg = ColorRect.new()
	_enemy_hp_bar_bg.position = Vector2(16, 34)
	_enemy_hp_bar_bg.size = Vector2(120, 6)
	_enemy_hp_bar_bg.color = Color(0.2, 0.05, 0.05)
	add_child(_enemy_hp_bar_bg)

	_enemy_hp_bar = ColorRect.new()
	_enemy_hp_bar.position = Vector2(16, 34)
	_enemy_hp_bar.size = Vector2(120, 6)
	_enemy_hp_bar.color = Color(0.8, 0.2, 0.25)
	add_child(_enemy_hp_bar)

	_message_label = Label.new()
	_message_label.position = Vector2(16, 88)
	_message_label.size = Vector2(288, 40)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.add_theme_font_size_override("font_size", 9)
	_message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(_message_label)

	for i in 4:
		var lbl := Label.new()
		lbl.position = Vector2(16, 132 + i * 12)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		add_child(lbl)
		_party_labels.append(lbl)

	for i in COMMANDS.size():
		var lbl := Label.new()
		lbl.position = Vector2(190, 132 + i * 14)
		lbl.text = COMMANDS[i]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		add_child(lbl)
		_command_labels.append(lbl)


func _input(event: InputEvent) -> void:
	if not _awaiting_command:
		return
	if event.is_action_pressed("ui_down"):
		_move_command(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_command(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_selected_command = _command_index
		_awaiting_command = false
		get_viewport().set_input_as_handled()


func _move_command(delta: int) -> void:
	_command_labels[_command_index].add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_command_index = wrapi(_command_index + delta, 0, COMMANDS.size())
	_command_labels[_command_index].add_theme_color_override("font_color", Color(1, 0.9, 0.3))


func _refresh_party_labels() -> void:
	var members := PartyData.get_active_members()
	for i in _party_labels.size():
		if i < members.size():
			var m: Dictionary = members[i]
			_party_labels[i].text = "%s  HP %d/%d  MP %d/%d" % [m["name"], m["hp"], m["max_hp"], m["mp"], m["max_mp"]]
			_party_labels[i].visible = true
		else:
			_party_labels[i].visible = false


func _refresh_enemy_bar() -> void:
	var ratio := 0.0
	if float(_enemy.get("max_hp", 1)) > 0:
		ratio = clampf(float(_enemy.get("hp", 0)) / float(_enemy.get("max_hp", 1)), 0.0, 1.0)
	_enemy_hp_bar.size = Vector2(120 * ratio, 6)


func _log(text: String) -> void:
	_message_label.text = text


func _wait_message(text: String, hold: float = 0.9) -> void:
	_log(text)
	await get_tree().create_timer(hold).timeout


func start_battle(enemy_data: Dictionary) -> String:
	_active = true
	_enemy = enemy_data.duplicate(true)
	get_tree().paused = true
	visible = true
	_enemy_name_label.text = String(_enemy.get("name", "謎の敵"))
	_refresh_party_labels()
	_refresh_enemy_bar()
	EventBus.battle_started.emit(String(_enemy.get("id", "")))

	if String(_enemy.get("intro", "")) != "":
		await _wait_message(String(_enemy["intro"]), 1.3)

	var result := ""
	while result == "":
		result = await _player_phase()
		if result != "":
			break
		result = await _enemy_phase()

	visible = false
	get_tree().paused = false
	_active = false
	EventBus.battle_ended.emit(result)

	if result == "lose":
		GameState.die(String(_enemy.get("id", "battle")) + "_battle", String(_enemy.get("lose_message", "意識が遠のいていく……")))

	return result


func _player_phase() -> String:
	_command_index = 0
	for lbl in _command_labels:
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_command_labels[0].add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	_selected_command = -1
	_awaiting_command = true
	_log("コマンドを選べ。")
	while _awaiting_command:
		await get_tree().process_frame

	match _selected_command:
		0:
			await _do_attack()
		1:
			await _do_heal()
		2:
			await _do_item()
		3:
			return await _do_flee()

	if float(_enemy.get("hp", 0)) <= 0.0:
		await _wait_message("%s を倒した!" % String(_enemy.get("name", "敵")), 1.1)
		var reward := int(_enemy.get("gold_reward", 0))
		if reward > 0:
			PartyData.add_gold(reward)
			await _wait_message("%dゴールドを手に入れた。" % reward, 0.9)
		GameState.set_flag("defeated_" + String(_enemy.get("id", "")), true)
		return "win"
	return ""


func _do_attack() -> void:
	var total := 0
	for m in PartyData.get_active_members():
		if int(m.get("hp", 0)) <= 0:
			continue
		total += max(1, int(m.get("atk", 1)) - int(_enemy.get("def", 0)))
	_enemy["hp"] = max(0, int(_enemy.get("hp", 0)) - total)
	_refresh_enemy_bar()
	await _wait_message("全員で攻撃! %d のダメージ!" % total, 1.0)


func _do_heal() -> void:
	if not (PartyData.members.has("serena") and PartyData.active_party.has("serena")):
		await _wait_message("回復できる仲間がいない。", 1.0)
		return
	var serena: Dictionary = PartyData.members["serena"]
	if int(serena.get("mp", 0)) < 3 or int(serena.get("hp", 0)) <= 0:
		await _wait_message("セレナのMPが足りない。", 1.0)
		return
	var target_id := _most_wounded_member_id()
	if target_id == "":
		await _wait_message("誰も傷ついていない。", 1.0)
		return
	serena["mp"] = int(serena.get("mp", 0)) - 3
	var target: Dictionary = PartyData.members[target_id]
	target["hp"] = min(int(target.get("max_hp", 0)), int(target.get("hp", 0)) + 12)
	_refresh_party_labels()
	await _wait_message("セレナの祈り。%s のHPが回復した。" % String(target.get("name", "")), 1.0)


func _do_item() -> void:
	if not PartyData.remove_item("potion", 1):
		await _wait_message("ポーションを持っていない。", 1.0)
		return
	var target_id := _most_wounded_member_id()
	if target_id == "":
		target_id = PartyData.active_party[0]
	var target: Dictionary = PartyData.members[target_id]
	target["hp"] = min(int(target.get("max_hp", 0)), int(target.get("hp", 0)) + 15)
	_refresh_party_labels()
	await _wait_message("ポーションを使った。%s のHPが回復した。" % String(target.get("name", "")), 1.0)


func _do_flee() -> String:
	if not bool(_enemy.get("can_flee", true)):
		await _wait_message(String(_enemy.get("flee_blocked_message", "逃げられない!回り込まれている!")), 1.1)
		return ""
	if randf() < 0.75:
		await _wait_message("うまく逃げ切った。", 0.9)
		return "flee"
	await _wait_message("逃げられなかった!", 0.9)
	return ""


func _most_wounded_member_id() -> String:
	var best_id := ""
	var best_missing := 0
	for id in PartyData.active_party:
		var m: Dictionary = PartyData.members.get(id, {})
		if m.is_empty() or int(m.get("hp", 0)) <= 0:
			continue
		var missing: int = int(m.get("max_hp", 0)) - int(m.get("hp", 0))
		if missing > best_missing:
			best_missing = missing
			best_id = id
	return best_id


func _enemy_phase() -> String:
	if float(_enemy.get("hp", 0)) <= 0.0:
		return ""
	var alive_ids: Array[String] = []
	for id in PartyData.active_party:
		var m: Dictionary = PartyData.members.get(id, {})
		if not m.is_empty() and int(m.get("hp", 0)) > 0:
			alive_ids.append(id)
	if alive_ids.is_empty():
		return "lose"

	var target_id: String = alive_ids[randi() % alive_ids.size()]
	var target: Dictionary = PartyData.members[target_id]
	var dmg: int = max(1, int(_enemy.get("atk", 1)) - int(target.get("def", 0)))
	target["hp"] = max(0, int(target.get("hp", 0)) - dmg)
	_refresh_party_labels()
	await _wait_message("%s の攻撃! %s に %d のダメージ!" % [String(_enemy.get("name", "敵")), String(target.get("name", "")), dmg], 1.0)

	if PartyData.is_party_wiped():
		await _wait_message("……目の前が暗くなっていく。", 1.0)
		return "lose"
	return ""
