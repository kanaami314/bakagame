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
}

## 人物の見た目(服・髪の色)。objects の "look" キーで指定する。
const LOOKS := {
	"villager": {"tunic": Color("4aa87a"), "hair": Color("5a4030")},
	"elder": {"tunic": Color("8a5fb0"), "hair": Color("d8d8e0")},
	"priest": {"tunic": Color("e8e8f0"), "hair": Color("c9a24b")},
	"merchant": {"tunic": Color("d98b3b"), "hair": Color("3a2a1e")},
	"innkeeper": {"tunic": Color("9a6a4a"), "hair": Color("4a3020")},
}

var grid: TileGrid
var player: PlayerController
var objects: Dictionary = {} # Vector2i -> Dictionary

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
	_setup_camera()
	_spawn_player()
	_build_prompt()
	_on_ready_extra()


func _build_map() -> void:
	grid = TileGrid.new()
	add_child(grid)
	grid.build(_get_layout(), _get_tileset())

	objects.clear()
	for obj in _get_objects():
		var cell: Vector2i = obj["cell"]
		objects[cell] = obj
		if bool(obj.get("solid", false)):
			grid.set_solid(cell, true)
		_spawn_object_visual(cell, obj)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.position = Vector2.ZERO
	add_child(cam)
	cam.make_current()


func _spawn_object_visual(cell: Vector2i, obj: Dictionary) -> void:
	var type := String(obj.get("type", ""))
	var tex: Texture2D = null
	match type:
		"chest":
			tex = TileArt.get_texture("chest")
		"sign":
			tex = TileArt.get_texture("sign")
		"npc", "shop", "inn":
			var look: Dictionary = LOOKS.get(String(obj.get("look", "villager")), LOOKS["villager"])
			tex = TileArt.character("down", look["tunic"], look["hair"])
		_:
			return

	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	spr.position = grid.cell_to_world(cell)
	add_child(spr)


func _spawn_player() -> void:
	var spawn_cell := _find_marker_cell(GameState.checkpoint_spawn_id)
	player = PlayerController.new()
	add_child(player)
	player.setup(grid, spawn_cell)
	player.moved.connect(_on_player_moved)
	player.interact_pressed.connect(_on_player_interact)
	_on_player_moved(spawn_cell)


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
		_:
			pass


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
