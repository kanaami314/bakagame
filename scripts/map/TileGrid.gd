class_name TileGrid
extends Node2D
## ASCIIレイアウトからプレースホルダー描画つきのグリッドマップを構築する。
## '#' = 壁, '.' = 床, ' ' = 何も置かない(空白)。

const TILE_SIZE := 16

var solid: Dictionary = {} # Vector2i -> bool
var _tile_rects: Dictionary = {} # Vector2i -> ColorRect
var wall_color := Color(0.18, 0.16, 0.22)
var floor_color := Color(0.5, 0.42, 0.28)


func build(layout: PackedStringArray, p_floor_color: Color, p_wall_color: Color) -> void:
	floor_color = p_floor_color
	wall_color = p_wall_color
	for y in layout.size():
		var row := layout[y]
		for x in row.length():
			var ch := row[x]
			if ch == " ":
				continue
			var cell := Vector2i(x, y)
			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(cell) * TILE_SIZE
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if ch == "#":
				rect.color = wall_color
				solid[cell] = true
			else:
				rect.color = floor_color
			add_child(rect)
			_tile_rects[cell] = rect


func is_solid(cell: Vector2i) -> bool:
	return bool(solid.get(cell, false))


func set_solid(cell: Vector2i, value: bool) -> void:
	solid[cell] = value


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func tint_cell(cell: Vector2i, color: Color) -> void:
	if _tile_rects.has(cell):
		(_tile_rects[cell] as ColorRect).color = color


func reset_cell_color(cell: Vector2i) -> void:
	if not _tile_rects.has(cell):
		return
	var is_wall := is_solid(cell)
	(_tile_rects[cell] as ColorRect).color = wall_color if is_wall else floor_color
