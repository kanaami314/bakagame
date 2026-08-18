class_name TileGrid
extends Node2D
## ASCIIレイアウトからドット絵タイルを敷き詰めてマップを構築する。
##
## tileset は 文字 -> {"art": TileArtの名前, "solid": bool, "under": 下地に敷く文字}
## "under" を指定すると、木や柱のように「地面の上に立っている」タイルを表現できる。

const TILE_SIZE := 16

var solid: Dictionary = {} # Vector2i -> bool
var size: Vector2i = Vector2i.ZERO # マス単位のマップ全体の大きさ
var _sprites: Dictionary = {} # Vector2i -> Sprite2D


func build(layout: PackedStringArray, tileset: Dictionary) -> void:
	var width := 0
	for row in layout:
		width = maxi(width, row.length())
	size = Vector2i(width, layout.size())

	for y in layout.size():
		var row := layout[y]
		for x in row.length():
			var ch := row[x]
			if not tileset.has(ch):
				continue
			var cell := Vector2i(x, y)
			var def: Dictionary = tileset[ch]

			var under := String(def.get("under", ""))
			if under != "" and tileset.has(under):
				_place_sprite(cell, String(tileset[under].get("art", "")))

			_sprites[cell] = _place_sprite(cell, String(def.get("art", "")))
			if bool(def.get("solid", false)):
				solid[cell] = true


func _place_sprite(cell: Vector2i, art_name: String) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = TileArt.get_texture(art_name)
	spr.centered = false
	spr.position = Vector2(cell) * TILE_SIZE
	add_child(spr)
	return spr


func is_solid(cell: Vector2i) -> bool:
	return bool(solid.get(cell, false))


func set_solid(cell: Vector2i, value: bool) -> void:
	solid[cell] = value


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func pixel_size() -> Vector2i:
	return size * TILE_SIZE
