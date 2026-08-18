class_name FollowerController
extends Node2D
## 主人公の後ろをついてくる仲間。
##
## 主人公が踏んだマスを順に辿るだけで、自分では経路探索をしない。
## 先頭から数えて i 番目の仲間は「主人公が i+1 歩前にいたマス」へ向かう。

var grid: TileGrid
var cell: Vector2i
var facing: Vector2i = Vector2i.DOWN

var _sprite: Sprite2D
var _tunic: Color
var _hair: Color


func setup(p_grid: TileGrid, start_cell: Vector2i, tunic: Color, hair: Color) -> void:
	grid = p_grid
	cell = start_cell
	_tunic = tunic
	_hair = hair
	position = grid.cell_to_world(cell)

	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)
	_update_sprite()


## 主人公の歩みに合わせて1マス進む。duration は主人公の移動時間に揃える。
func step_to(target: Vector2i, duration: float) -> void:
	if target == cell:
		return
	var delta := target - cell
	if absi(delta.x) + absi(delta.y) == 1:
		facing = delta
		_update_sprite()
	cell = target
	var tw := create_tween()
	tw.tween_property(self, "position", grid.cell_to_world(cell), duration)


func _update_sprite() -> void:
	var dir_name := "down"
	if facing == Vector2i.UP:
		dir_name = "up"
	elif facing == Vector2i.LEFT:
		dir_name = "left"
	elif facing == Vector2i.RIGHT:
		dir_name = "right"
	_sprite.texture = TileArt.character(dir_name, _tunic, _hair)
