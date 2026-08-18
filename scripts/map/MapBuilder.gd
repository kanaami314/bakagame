class_name MapBuilder
extends RefCounted
## 広いマップのレイアウトを組み立てる。
##
## 60×42のような大きさになると、文字列を手書きすると桁数のずれに気づけない。
## 区画や建物を矩形で置いていく形にして、間違いが起きにくいようにする。

var _w: int
var _h: int
var _cells: Array[PackedStringArray] = []


func _init(width: int, height: int, fill: String) -> void:
	_w = width
	_h = height
	for y in height:
		var row := PackedStringArray()
		row.resize(width)
		row.fill(fill)
		_cells.append(row)


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _w and y < _h


func set_cell(x: int, y: int, ch: String) -> void:
	if in_bounds(x, y):
		_cells[y][x] = ch


func get_cell(x: int, y: int) -> String:
	return _cells[y][x] if in_bounds(x, y) else ""


func fill_rect(x: int, y: int, w: int, h: int, ch: String) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			set_cell(xx, yy, ch)


## 矩形の輪郭だけを塗る
func rect_outline(x: int, y: int, w: int, h: int, ch: String) -> void:
	for xx in range(x, x + w):
		set_cell(xx, y, ch)
		set_cell(xx, y + h - 1, ch)
	for yy in range(y, y + h):
		set_cell(x, yy, ch)
		set_cell(x + w - 1, yy, ch)


func border(ch: String) -> void:
	rect_outline(0, 0, _w, _h, ch)


func hline(x1: int, x2: int, y: int, ch: String) -> void:
	for x in range(mini(x1, x2), maxi(x1, x2) + 1):
		set_cell(x, y, ch)


func vline(x: int, y1: int, y2: int, ch: String) -> void:
	for y in range(mini(y1, y2), maxi(y1, y2) + 1):
		set_cell(x, y, ch)


## 建物を1棟置く。上段が屋根、下段が壁になり、扉を1つ開ける。
## door_offset は建物の左端から数えた扉の位置。
func building(x: int, y: int, w: int, roof_h: int, wall_h: int, door_offset: int) -> void:
	fill_rect(x, y, w, roof_h, "R")
	fill_rect(x, y + roof_h, w, wall_h, "H")
	set_cell(x + door_offset, y + roof_h + wall_h - 1, "D")


func to_layout() -> PackedStringArray:
	var out := PackedStringArray()
	for row in _cells:
		out.append("".join(row))
	return out
