extends SceneTree
## マップ全体とドット絵一覧をPNGへ書き出す確認用ツール。
##
##   godot --headless --path . --script res://tools/render_preview.gd
##
## ゲームを起動しなくても見た目を確認できるよう、タイルとオブジェクトを
## CPU上で合成する(ヘッドレスでは描画サーバーを使えないため)。

const OUT_DIR := "user://preview"
const SCALE := 3


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_render("res://scripts/map/TownMap.gd", "town.png")
	_render("res://scripts/map/DungeonMap.gd", "dungeon.png")
	_render("res://scripts/map/ThroneRoomMap.gd", "throne_room.png")
	_render_sheet("sheet.png")
	print("OUTPUT DIR: ", ProjectSettings.globalize_path(OUT_DIR))
	quit()


func _render(script_path: String, out_name: String) -> void:
	var map = load(script_path).new()
	var layout: PackedStringArray = map._get_layout()
	var tileset: Dictionary = map._get_tileset()
	var objs: Array = map._get_objects()

	var w: int = layout[0].length() * 16
	var h: int = layout.size() * 16
	var canvas := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.BLACK)

	for y in layout.size():
		var row := layout[y]
		for x in row.length():
			var ch := row[x]
			if not tileset.has(ch):
				continue
			var def: Dictionary = tileset[ch]
			var under := String(def.get("under", ""))
			if under != "" and tileset.has(under):
				_blend(canvas, TileArt.get_image(String(tileset[under]["art"])), Vector2i(x * 16, y * 16))
			_blend(canvas, TileArt.get_image(String(def["art"])), Vector2i(x * 16, y * 16))

	for obj in objs:
		var cell: Vector2i = obj["cell"]
		var img: Image = null
		match String(obj.get("type", "")):
			"chest":
				img = TileArt.get_image("chest")
			"sign":
				img = TileArt.get_image("sign")
			"npc", "shop", "inn":
				img = TileArt.character_image(String(obj.get("look", "villager")), "down")
			_:
				continue
		_blend(canvas, img, cell * 16)

	# 主人公をスポーン地点に置いて見え方を確認する
	for obj in objs:
		if String(obj.get("type", "")) == "marker" and String(obj.get("id", "")) == "start":
			_blend(canvas, TileArt.character_image("hero", "down"), Vector2i(obj["cell"]) * 16)

	canvas.resize(w * SCALE, h * SCALE, Image.INTERPOLATE_NEAREST)
	canvas.save_png(OUT_DIR + "/" + out_name)
	print("saved ", out_name, " ", w, "x", h)


## 全スプライトを並べた確認用シート
func _render_sheet(out_name: String) -> void:
	var names := [
		"grass", "path", "floor", "wall_stone", "pillar", "tree",
		"house", "house_door", "roof", "chest", "sign",
		"castle_floor", "castle_wall", "carpet", "throne",
	]
	var cols := 6
	var rows: int = ceili(float(names.size() + 8) / float(cols))
	var canvas := Image.create_empty(cols * 20, rows * 20, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.1, 0.1, 0.14))

	var i := 0
	for n in names:
		_blend(canvas, TileArt.get_image(n), Vector2i((i % cols) * 20 + 2, (i / cols) * 20 + 2))
		i += 1
	for dir in ["down", "up", "left", "right"]:
		_blend(canvas, TileArt.character_image("hero", dir), Vector2i((i % cols) * 20 + 2, (i / cols) * 20 + 2))
		i += 1
	for look_id in ["priest", "king", "guard", "merchant"]:
		_blend(canvas, TileArt.character_image(look_id, "down"), Vector2i((i % cols) * 20 + 2, (i / cols) * 20 + 2))
		i += 1

	canvas.resize(canvas.get_width() * 4, canvas.get_height() * 4, Image.INTERPOLATE_NEAREST)
	canvas.save_png(OUT_DIR + "/" + out_name)
	print("saved ", out_name)


func _blend(dst: Image, src: Image, at: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)
