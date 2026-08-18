extends SceneTree
## マップとイベントの回帰テスト。GUIなしで実行できる。
##
##   godot --headless --path . --script res://tools/smoke_test.gd
##
## 罠を増やすたびに「進めなくなる/戻れなくなる」詰みが混入しやすいので、
## 経路が塞がっていないことと死亡後に復帰できることをここで担保する。
## --script 実行時はオートロードのベア識別子解決が効かないため /root/Name で取得する。

var _done := false
var _frames := 0
var _fail_count := 0
var PartyData: Node
var GameState: Node


func _initialize() -> void:
	print("=== SMOKE TEST START ===")
	_run()


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 900:
		print("!!! TIMEOUT !!!")
		return true
	return _done


## 決定キーの押下と離しを1回ぶん流し込む。
func _press_accept() -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = "ui_accept"
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await process_frame
	await process_frame


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  OK   ", label)
	else:
		print("  FAIL ", label)
		_fail_count += 1


func _run() -> void:
	PartyData = root.get_node("PartyData")
	GameState = root.get_node("GameState")

	# --- 関門の形状: 北の宝物庫へ行くには (10,7) を必ず踏む ---
	var dg = load("res://scenes/maps/Dungeon.tscn").instantiate()
	root.add_child(dg)
	current_scene = dg
	await process_frame

	for wall_row in [6, 8]:
		var gaps: Array = []
		for x in 20:
			if not dg.grid.is_solid(Vector2i(x, wall_row)):
				gaps.append(x)
		_check(gaps == [10], "row %d の通行可能マスは x=10 のみ (実際: %s)" % [wall_row, gaps])
	_check(not dg.grid.is_solid(Vector2i(10, 7)), "待ち伏せ地点(10,7)は通行可能")
	_check(dg.objects.has(Vector2i(10, 7)), "待ち伏せイベントが(10,7)に存在")

	# --- バグ1: 撃破済みの待ち伏せが再発火しないこと ---
	GameState.set_flag("dungeon_treasure_taken", true)
	GameState.set_flag("trap_cleared_corridor_ambush", true)
	var battle = root.get_node("BattleSystem")
	await dg._trigger_trap_step(dg.objects[Vector2i(10, 7)])
	_check(not battle.is_active(), "突破済みの待ち伏せは再戦にならない")

	# --- バグ2: 死亡からの復元でHPが戻ること ---
	PartyData.reset_to_default()
	PartyData.add_member("serena")
	for id in PartyData.active_party:
		PartyData.members[id]["hp"] = 0
	_check(PartyData.is_party_wiped(), "前提: 全滅状態を作れた")

	GameState.set_checkpoint("res://scenes/maps/Dungeon.tscn", "start")
	GameState.die("smoke_test", "テスト死亡")
	_check(not PartyData.is_party_wiped(), "死亡後、パーティが全滅状態のままではない")
	for id in PartyData.active_party:
		var m: Dictionary = PartyData.members[id]
		_check(int(m["hp"]) == int(m["max_hp"]), "%s のHPが全快している (%d/%d)" % [m["name"], m["hp"], m["max_hp"]])
	_check(GameState.has_died_from("smoke_test"), "死因が記憶に残っている")

	for i in 200:
		await process_frame
	_check(current_scene != null and current_scene.name == "DungeonMap", "チェックポイントのシーンへ復帰した")

	# --- 村: NPCが道を塞いでいないこと ---
	var town = load("res://scenes/maps/Town.tscn").instantiate()
	root.add_child(town)
	current_scene = town
	await process_frame
	# y=13 は村の南端(木の壁)。出口は北の (10,0) なので y=0..12 が通れればよい。
	var blocked: Array = []
	for y in 13:
		if town.grid.is_solid(Vector2i(10, y)):
			blocked.append(y)
	_check(blocked.is_empty(), "村の道(x=10, y=0..12)が塞がれていない (塞がり: %s)" % [blocked])
	_check(town.objects.has(Vector2i(10, 0)), "北の出口が(10,0)に存在")

	var spawn: Vector2i = town._find_marker_cell("from_dungeon")
	_check(spawn == Vector2i(10, 2), "遺跡からの帰還地点が正しい (実際: %s)" % [spawn])

	# --- 会話がEnter1回ぶんの押下で閉じ、同じ押下で再開しないこと ---
	# 会話ウィンドウとプレイヤーが同じ押下を二重に消費すると、最終行を閉じた
	# 瞬間に話しかけ直してしまい会話から抜け出せなくなる。
	Input.use_accumulated_input = false
	var dialogue := root.get_node("Dialogue")
	var elder_cell := Vector2i(5, 6)
	var elder_lines: int = (town.objects[elder_cell]["lines"] as Array).size()

	town.player.cell = elder_cell + Vector2i.DOWN
	town.player.position = town.grid.cell_to_world(town.player.cell)
	town.player.facing = Vector2i.UP
	await process_frame

	await _press_accept()
	_check(dialogue.is_active(), "Enterで会話が始まる")

	for i in elder_lines:
		await _press_accept()
	_check(not dialogue.is_active(), "最終行のEnterで会話が閉じる(同じ押下で再開しない)")

	for i in 10:
		await process_frame
	_check(not dialogue.is_active(), "閉じたあと会話が勝手に再開しない")

	# --- 選択肢ウィンドウが会話ウィンドウと重ならないこと ---
	var opts := ["ポーション (10G)", "ポーション5個セット (45G)", "やめる"]
	dialogue.choice("いらっしゃい。何か買っていくかい?  所持金: 50G", opts)
	await process_frame
	await process_frame

	var msg_rect := Rect2(dialogue.PANEL_POS, dialogue.PANEL_SIZE)
	var opt_rect := Rect2(dialogue._choice_border.position, dialogue._choice_border.size)
	var screen := Rect2(Vector2.ZERO, dialogue.SCREEN_SIZE)
	_check(not msg_rect.intersects(opt_rect),
		"選択肢が会話ウィンドウと重ならない (会話 %s / 選択肢 %s)" % [msg_rect, opt_rect])

	var msg_frame_top: float = dialogue.PANEL_POS.y - 2.0
	var gap: float = msg_frame_top - (opt_rect.position.y + opt_rect.size.y)
	_check(gap >= 2.0, "選択肢と会話ウィンドウの枠が接していない (隙間 %.1fpx)" % gap)
	_check(screen.encloses(opt_rect), "選択肢ウィンドウが画面内に収まる (%s)" % [opt_rect])

	var longest := 0.0
	for lbl in dialogue._choice_labels:
		longest = maxf(longest, lbl.position.x + lbl.get_minimum_size().x)
	_check(longest <= opt_rect.size.x,
		"選択肢の文字が枠からはみ出さない (文字端 %.1f / 枠幅 %.1f)" % [longest, opt_rect.size.x])

	await _press_accept()
	_check(not dialogue.is_active(), "選択肢がEnterで確定して閉じる")

	# --- 仲間の追従 ---
	# 先に作った村は別状態なので、独立した状態から作り直して確認する。
	town.free()
	PartyData.reset_to_default()
	town = load("res://scenes/maps/Town.tscn").instantiate()
	root.add_child(town)
	current_scene = town
	await process_frame

	var serena_cell := Vector2i(14, 4)
	_check(town.followers.is_empty(), "加入前は追従する仲間がいない")
	_check(town.objects.has(serena_cell), "加入前はセレナが村に立っている")

	PartyData.add_member("serena")
	await process_frame
	_check(town.followers.size() == 1, "加入で追従する仲間が1人になる")
	_check(not town.objects.has(serena_cell), "加入後は立っていたセレナが消える")
	_check(not town.grid.is_solid(serena_cell), "セレナが立っていたマスを通れる")

	var serena: FollowerController = town.followers[0]
	_check(serena.cell == town.player.cell, "加入直後は主人公と同じマスにいる")

	# 主人公が1歩進むと、仲間は主人公が直前にいたマスへ入る
	var before: Vector2i = town.player.cell
	town.player._try_move(Vector2i.DOWN)
	await process_frame
	_check(town.player.cell == before + Vector2i.DOWN, "主人公が1歩進んだ")
	_check(serena.cell == before, "仲間が主人公の直前のマスへ移動する (実際: %s)" % [serena.cell])

	var before2: Vector2i = town.player.cell
	town.player._try_move(Vector2i.LEFT)
	await process_frame
	_check(serena.cell == before2, "続けて進んでも1歩後ろを保つ (実際: %s)" % [serena.cell])

	# 場面が変わっても追従が引き継がれる
	town.free()
	var town2 = load("res://scenes/maps/Town.tscn").instantiate()
	root.add_child(town2)
	current_scene = town2
	await process_frame
	_check(town2.followers.size() == 1, "場面が変わっても仲間が追従している")
	_check(not town2.objects.has(serena_cell), "場面が変わってもセレナは村に立っていない")

	print("=== RESULT: %s (失敗 %d件) ===" % ["PASSED" if _fail_count == 0 else "FAILED", _fail_count])
	_done = true
