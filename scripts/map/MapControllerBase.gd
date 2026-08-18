class_name MapControllerBase
extends Node2D
## 村・ダンジョンなど「1画面マップ」の共通処理。
## サブクラスは _get_layout() / _get_objects() などを上書きして地形とイベントを定義する。
## イベント種別(objects の "type"):
##   marker(スポーン/チェックポイント), door(扉/出口), npc, sign, chest, shop, trap_step

var grid: TileGrid
var player: PlayerController
var objects: Dictionary = {} # Vector2i -> Dictionary


func _get_layout() -> PackedStringArray:
	return PackedStringArray()


func _get_objects() -> Array:
	return []


func _get_floor_color() -> Color:
	return Color(0.5, 0.42, 0.28)


func _get_wall_color() -> Color:
	return Color(0.18, 0.16, 0.22)


func _on_ready_extra() -> void:
	pass # サブクラスが必要なら独自の初期化をここに書く


func _ready() -> void:
	var path := scene_file_path
	if GameState.current_scene_path != path:
		GameState.set_checkpoint(path, "start")
	_build_map()
	_setup_camera()
	_spawn_player()
	_on_ready_extra()


func _build_map() -> void:
	grid = TileGrid.new()
	add_child(grid)
	grid.build(_get_layout(), _get_floor_color(), _get_wall_color())

	objects.clear()
	for obj in _get_objects():
		var cell: Vector2i = obj["cell"]
		objects[cell] = obj
		if bool(obj.get("solid", false)):
			grid.set_solid(cell, true)
		if String(obj.get("type", "")) in ["chest", "npc", "shop", "sign"]:
			_spawn_marker_visual(cell, obj)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.position = Vector2.ZERO
	add_child(cam)
	cam.make_current()


func _spawn_marker_visual(cell: Vector2i, obj: Dictionary) -> void:
	var vis := ColorRect.new()
	vis.size = Vector2(10, 10)
	vis.position = grid.cell_to_world(cell) - Vector2(5, 5)
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match String(obj.get("type", "")):
		"chest":
			vis.color = Color(0.85, 0.7, 0.2)
		"npc":
			vis.color = Color(0.7, 0.5, 0.8)
		"shop":
			vis.color = Color(0.3, 0.8, 0.5)
		"sign":
			vis.color = Color(0.6, 0.6, 0.6)
		_:
			vis.color = Color(1, 1, 1)
	add_child(vis)


func _spawn_player() -> void:
	var spawn_cell := _find_marker_cell(GameState.checkpoint_spawn_id)
	player = PlayerController.new()
	add_child(player)
	player.setup(grid, spawn_cell)
	player.moved.connect(_on_player_moved)
	player.interact_pressed.connect(_on_player_interact)
	_on_player_moved(spawn_cell)


func _find_marker_cell(spawn_id: String) -> Vector2i:
	for cell in objects.keys():
		var obj: Dictionary = objects[cell]
		if String(obj.get("type", "")) == "marker" and String(obj.get("id", "")) == spawn_id:
			return cell
	for cell in objects.keys():
		if String(objects[cell].get("type", "")) == "marker":
			return cell
	return Vector2i.ZERO


func _on_player_moved(cell: Vector2i) -> void:
	if not objects.has(cell):
		return
	var obj: Dictionary = objects[cell]
	match String(obj.get("type", "")):
		"marker":
			if bool(obj.get("checkpoint", true)):
				GameState.set_checkpoint(scene_file_path, String(obj.get("id", "")))
		"door":
			GameState.travel_to(String(obj["target_scene"]), String(obj["target_spawn"]))
		"trap_step":
			await _trigger_trap_step(obj)
		_:
			pass


func _trigger_trap_step(obj: Dictionary) -> void:
	var req_flag := String(obj.get("requires_flag", ""))
	if req_flag != "" and not GameState.has_flag(req_flag):
		return
	var id := String(obj.get("id", "trap"))
	var kind := String(obj.get("kind", "instant_death"))
	if kind == "battle" and GameState.has_flag("defeated_" + id):
		return
	match kind:
		"instant_death":
			GameState.die(id, String(obj.get("message", "")))
		"battle":
			var enemy: Dictionary = obj.get("enemy", {})
			await BattleSystem.start_battle(enemy)
		_:
			pass


func _on_player_interact(cell: Vector2i) -> void:
	if not objects.has(cell):
		return
	var obj: Dictionary = objects[cell]
	match String(obj.get("type", "")):
		"npc", "sign":
			await _show_simple_npc(obj)
		"chest":
			await _open_chest(obj)
		"shop":
			await _open_shop(obj)
		_:
			pass


func _show_simple_npc(obj: Dictionary) -> void:
	var speaker := String(obj.get("name", "???"))
	var join_id := String(obj.get("join_member", ""))
	var lines: Array = obj.get("lines", [])
	if join_id != "" and PartyData.active_party.has(join_id):
		lines = obj.get("lines_after", lines)
	await Dialogue.say_lines(speaker, lines)
	if join_id != "" and not PartyData.active_party.has(join_id):
		PartyData.add_member(join_id)


func _open_chest(obj: Dictionary) -> void:
	var id := String(obj.get("id", "chest"))
	if GameState.has_flag("chest_opened_" + id):
		await Dialogue.say("", "(空っぽの宝箱だ)")
		return
	GameState.set_flag("chest_opened_" + id, true)

	var trap_id := String(obj.get("trap_id", id))
	var lines: Array = obj.get("open_lines", ["宝箱を開けた。"])
	if obj.has("hint_line") and GameState.has_died_from(trap_id):
		lines = [String(obj["hint_line"])] + lines
	await Dialogue.say_lines("", lines)

	var item := String(obj.get("loot_item", ""))
	if item != "":
		PartyData.add_item(item, int(obj.get("loot_amount", 1)))
		await Dialogue.say("", "%s を手に入れた!" % item)
	var gold := int(obj.get("loot_gold", 0))
	if gold > 0:
		PartyData.add_gold(gold)
		await Dialogue.say("", "%dゴールドを手に入れた!" % gold)

	if obj.has("flag_on_open"):
		GameState.set_flag(String(obj["flag_on_open"]), true)

	if bool(obj.get("collapse_after", false)):
		await Dialogue.say("", "……ミシッ、と足元が鳴った。")
		GameState.die(trap_id, String(obj.get("trap_message", "床が抜けた!")))


func _open_shop(obj: Dictionary) -> void:
	var wares: Array = obj.get("wares", [])
	var options: Array = []
	for w in wares:
		options.append("%s (%dG)" % [String(w["name"]), int(w["price"])])
	options.append("やめる")
	while true:
		var idx: int = await Dialogue.choice(String(obj.get("greeting", "何か買うか?")), options)
		if idx < 0 or idx >= wares.size():
			break
		var w: Dictionary = wares[idx]
		if PartyData.gold < int(w["price"]):
			await Dialogue.say(String(obj.get("name", "商人")), "ゴールドが足りないな。")
			continue
		PartyData.add_gold(-int(w["price"]))
		PartyData.add_item(String(w["item"]), int(w.get("amount", 1)))
		await Dialogue.say(String(obj.get("name", "商人")), "まいどあり!")
	await Dialogue.say(String(obj.get("name", "商人")), "またどうぞ。")
