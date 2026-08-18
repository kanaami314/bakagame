class_name MapControllerBase
extends Node2D
## 村・ダンジョンなど「1画面マップ」の共通処理。
## サブクラスは _get_layout() / _get_objects() などを上書きして地形とイベントを定義する。
## イベント種別(objects の "type"):
##   marker(スポーン/チェックポイント), door(扉/出口), npc, sign, chest, shop, inn, trap_step

const DEFAULT_TILESET := {
	".": {"art": "grass", "solid": false},
	",": {"art": "path", "solid": false},
	"#": {"art": "tree", "solid": true, "under": "."},
	"H": {"art": "house", "solid": true},
	"D": {"art": "house_door", "solid": true},
	"R": {"art": "roof", "solid": true},
	"_": {"art": "floor", "solid": false},
	"W": {"art": "wall_stone", "solid": true},
	"P": {"art": "pillar", "solid": true, "under": "_"},
	"F": {"art": "castle_floor", "solid": false},
	"C": {"art": "castle_wall", "solid": true},
	"c": {"art": "carpet", "solid": false, "under": "F"},
	"T": {"art": "throne", "solid": true, "under": "c"},
	"p": {"art": "pavement", "solid": false},
	"f": {"art": "fountain", "solid": true, "under": "p"},
	"+": {"art": "gate", "solid": true},
	"A": {"art": "roof_church", "solid": true},
}

## 仲間の見た目。TileArt.LOOKS のキー(look_id)を指す。
## objects 側は "look" キーで直接 look_id を指定する。
const MEMBER_LOOKS := {
	"serena": "priest",
}

var grid: TileGrid
var player: PlayerController
var objects: Dictionary = {} # Vector2i -> Dictionary

var followers: Array[FollowerController] = []
var _object_sprites: Dictionary = {} # Vector2i -> Sprite2D
## 主人公が直前に踏んだマスの履歴(新しい順)。仲間はこれを順に辿る。
var _trail: Array[Vector2i] = []

var _prompt_label: Label
var _busy: bool = false


func _get_layout() -> PackedStringArray:
	return PackedStringArray()


func _get_objects() -> Array:
	return []


func _get_tileset() -> Dictionary:
	return DEFAULT_TILESET


func _on_ready_extra() -> void:
	pass # サブクラスが必要なら独自の初期化をここに書く


func _ready() -> void:
	var path := scene_file_path
	if GameState.current_scene_path != path:
		GameState.set_checkpoint(path, "start")
	_build_map()
	_spawn_player()
	_attach_camera_to_player()
	_build_prompt()
	_on_ready_extra()


func _build_map() -> void:
	grid = TileGrid.new()
	add_child(grid)
	grid.build(_get_layout(), _get_tileset())

	objects.clear()
	for obj in _get_objects():
		# すでに仲間になった人物は、その場に立ったままにせず主人公に追従させる。
		var join_id := String(obj.get("join_member", ""))
		if join_id != "" and PartyData.active_party.has(join_id):
			continue
		var cell: Vector2i = obj["cell"]
		objects[cell] = obj
		if bool(obj.get("solid", false)):
			grid.set_solid(cell, true)
		_spawn_object_visual(cell, obj)


## カメラは主人公の子にして追従させ、マップ端で止まるよう上限を設ける。
## 画面に収まる小さなマップでは上限で固定されるため、結果的に従来どおり動かない。
func _attach_camera_to_player() -> void:
	var px := grid.pixel_size()
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = px.x
	cam.limit_bottom = px.y
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 12.0
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()


func _spawn_object_visual(cell: Vector2i, obj: Dictionary) -> void:
	var spr := Sprite2D.new()
	spr.centered = true
	spr.position = grid.cell_to_world(cell)

	match String(obj.get("type", "")):
		"chest":
			spr.texture = TileArt.get_texture("chest")
		"sign":
			spr.texture = TileArt.get_texture("sign")
		"npc", "shop", "inn":
			TileArt.apply_character_texture(spr, String(obj.get("look", "villager")), "down")
		_:
			spr.free()
			return

	add_child(spr)
	_object_sprites[cell] = spr


func _spawn_player() -> void:
	var spawn_cell := _find_marker_cell(GameState.checkpoint_spawn_id)

	# 仲間を先に追加して、重なったときに主人公が手前へ描かれるようにする。
	for member_id in PartyData.active_party:
		_spawn_follower(member_id, spawn_cell)

	player = PlayerController.new()
	add_child(player)
	player.setup(grid, spawn_cell)
	player.moved.connect(_on_player_moved)
	player.interact_pressed.connect(_on_player_interact)
	player.step_started.connect(_on_player_step)
	PartyData.member_joined.connect(_on_member_joined)
	_on_player_moved(spawn_cell)


func _spawn_follower(member_id: String, at_cell: Vector2i) -> void:
	if not MEMBER_LOOKS.has(member_id):
		return # 主人公など、追従させない相手
	var f := FollowerController.new()
	add_child(f)
	f.setup(grid, at_cell, String(MEMBER_LOOKS[member_id]))
	followers.append(f)


## 仲間になった瞬間から追従を始める。立ち位置に残っていたNPCは消す。
func _on_member_joined(member_id: String) -> void:
	if player == null:
		return
	for cell in objects.keys():
		if String(objects[cell].get("join_member", "")) == member_id:
			if _object_sprites.has(cell):
				(_object_sprites[cell] as Sprite2D).queue_free()
				_object_sprites.erase(cell)
			grid.set_solid(cell, false)
			objects.erase(cell)
			break
	_spawn_follower(member_id, player.cell)


func _on_player_step(from_cell: Vector2i, duration: float) -> void:
	if followers.is_empty():
		return
	_trail.push_front(from_cell)
	if _trail.size() > followers.size():
		_trail.resize(followers.size())
	for i in followers.size():
		if i < _trail.size():
			followers[i].step_to(_trail[i], duration)


## 目の前の対象が何なのかを画面上部に出す。ドット絵だけでは伝わらない情報を補う。
func _build_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(320, 14)
	layer.add_child(bg)

	_prompt_label = Label.new()
	_prompt_label.position = Vector2(6, 1)
	_prompt_label.add_theme_font_size_override("font_size", 10)
	_prompt_label.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	layer.add_child(_prompt_label)

	bg.visible = false
	_prompt_label.visible = false
	_prompt_label.set_meta("bg", bg)


## メニューはマップ上でのみ開ける。会話・戦闘・場面演出の最中は開かない。
func _unhandled_input(event: InputEvent) -> void:
	if _busy or Menu.is_open() or Dialogue.is_active() or BattleSystem.is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Menu.open()


func _process(_delta: float) -> void:
	if _prompt_label == null or player == null:
		return
	var bg: ColorRect = _prompt_label.get_meta("bg")
	var text := ""
	if not (_busy or Dialogue.is_active() or BattleSystem.is_active()):
		text = _prompt_for(player.cell + player.facing)
	_prompt_label.text = text
	_prompt_label.visible = text != ""
	bg.visible = text != ""


func _prompt_for(cell: Vector2i) -> String:
	if not objects.has(cell):
		return ""
	var obj: Dictionary = objects[cell]
	var obj_name := String(obj.get("name", ""))
	match String(obj.get("type", "")):
		"npc":
			return "Enter: %s と話す" % obj_name
		"shop":
			return "Enter: %s で買い物" % obj_name
		"inn":
			return "Enter: %s に泊まる" % obj_name
		"sign":
			return "Enter: %s を読む" % obj_name
		"chest":
			if GameState.has_flag("chest_opened_" + String(obj.get("id", ""))):
				return "Enter: 空の宝箱を調べる"
			return "Enter: 宝箱を開ける"
		_:
			return ""


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
		"trigger":
			await _fire_trigger(obj)
		_:
			pass


## 特定のマスを踏んだときに物語上の場面を起こす。中身はサブクラスが _run_trigger で書く。
func _fire_trigger(obj: Dictionary) -> void:
	var id := String(obj.get("id", ""))
	var flag := "trigger_fired_" + id
	if bool(obj.get("once", true)) and GameState.has_flag(flag):
		return
	GameState.set_flag(flag, true)
	_busy = true
	player.input_locked = true
	await _run_trigger(id)
	# 場面転換を伴う場合はここへ戻らないこともある
	if is_instance_valid(player):
		player.input_locked = false
	_busy = false


func _run_trigger(_id: String) -> void:
	pass # サブクラスが実装する


func _trigger_trap_step(obj: Dictionary) -> void:
	var req_flag := String(obj.get("requires_flag", ""))
	if req_flag != "" and not GameState.has_flag(req_flag):
		return
	var id := String(obj.get("id", "trap"))
	var cleared_flag := "trap_cleared_" + id
	if GameState.has_flag(cleared_flag):
		return

	_busy = true
	match String(obj.get("kind", "instant_death")):
		"instant_death":
			GameState.die(id, String(obj.get("message", "")))
		"battle":
			var result: String = await BattleSystem.start_battle(obj.get("enemy", {}))
			# 一度突破した待ち伏せが毎回復活すると、二度と引き返せなくなってしまう。
			if result == "win" or result == "flee":
				GameState.set_flag(cleared_flag, true)
		_:
			pass
	_busy = false


func _on_player_interact(cell: Vector2i) -> void:
	if _busy or not objects.has(cell):
		return
	var obj: Dictionary = objects[cell]
	_busy = true
	match String(obj.get("type", "")):
		"npc", "sign":
			await _show_simple_npc(obj)
		"chest":
			await _open_chest(obj)
		"shop":
			await _open_shop(obj)
		"inn":
			await _use_inn(obj)
		_:
			pass
	_busy = false


func _show_simple_npc(obj: Dictionary) -> void:
	var speaker := String(obj.get("name", "???"))
	var join_id := String(obj.get("join_member", ""))
	var lines: Array = obj.get("lines", [])
	if join_id != "" and PartyData.active_party.has(join_id):
		lines = obj.get("lines_after", lines)
	await Dialogue.say_lines(speaker, lines)
	if join_id != "" and not PartyData.active_party.has(join_id):
		PartyData.add_member(join_id)
		await Dialogue.say("", "%s が仲間に加わった!" % speaker)


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
	var shop_name := String(obj.get("name", "商人"))
	var wares: Array = obj.get("wares", [])
	while true:
		var options: Array = []
		for w in wares:
			options.append("%s (%dG)" % [String(w["name"]), int(w["price"])])
		options.append("やめる")
		var prompt := "%s  所持金: %dG" % [String(obj.get("greeting", "何か買うか?")), PartyData.gold]
		var idx: int = await Dialogue.choice(prompt, options)
		if idx < 0 or idx >= wares.size():
			break
		var w: Dictionary = wares[idx]
		if PartyData.gold < int(w["price"]):
			await Dialogue.say(shop_name, "ゴールドが足りないな。")
			continue
		PartyData.add_gold(-int(w["price"]))
		PartyData.add_item(String(w["item"]), int(w.get("amount", 1)))
		await Dialogue.say(shop_name, "まいどあり!")
	await Dialogue.say(shop_name, "またどうぞ。")


func _use_inn(obj: Dictionary) -> void:
	var inn_name := String(obj.get("name", "宿屋"))
	var price := int(obj.get("price", 5))
	var idx: int = await Dialogue.choice(
		"%s 一泊%dG だよ。泊まるかい?  所持金: %dG" % [inn_name, price, PartyData.gold],
		["泊まる", "やめる"]
	)
	if idx != 0:
		await Dialogue.say(inn_name, "また来ておくれ。")
		return
	if PartyData.gold < price:
		await Dialogue.say(inn_name, "……お代が足りないねぇ。")
		return
	PartyData.add_gold(-price)
	PartyData.heal_full_party()
	await Dialogue.say("", "ぐっすり眠った。HPとMPが全回復した!")
