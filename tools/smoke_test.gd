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

	print("=== RESULT: %s (失敗 %d件) ===" % ["PASSED" if _fail_count == 0 else "FAILED", _fail_count])
	_done = true
