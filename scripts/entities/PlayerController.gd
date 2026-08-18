class_name PlayerController
extends Node2D
## グリッド単位で移動する見下ろし型プレイヤー。マップ側が grid を渡してセットアップする。

signal moved(cell: Vector2i)
signal interact_pressed(facing_cell: Vector2i)

const MOVE_TIME := 0.11

var grid: TileGrid
var cell: Vector2i
var facing: Vector2i = Vector2i.DOWN
var input_locked: bool = false

var _moving: bool = false
var _body: ColorRect
var _facing_mark: ColorRect


func _ready() -> void:
	_body = ColorRect.new()
	_body.color = Color(0.3, 0.55, 0.95)
	_body.size = Vector2(12, 12)
	_body.position = Vector2(-6, -6)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	_facing_mark = ColorRect.new()
	_facing_mark.color = Color(0.95, 0.9, 0.3)
	_facing_mark.size = Vector2(4, 4)
	_facing_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_facing_mark)
	_update_facing_mark()


func setup(p_grid: TileGrid, start_cell: Vector2i) -> void:
	grid = p_grid
	cell = start_cell
	position = grid.cell_to_world(cell)


func _process(_delta: float) -> void:
	if _moving or input_locked or Dialogue.is_active() or BattleSystem.is_active():
		return

	if Input.is_action_just_pressed("ui_accept"):
		interact_pressed.emit(cell + facing)
		return

	var dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_right"):
		dir = Vector2i.RIGHT
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2i.UP

	if dir == Vector2i.ZERO:
		return

	facing = dir
	_update_facing_mark()
	_try_move(dir)


func _update_facing_mark() -> void:
	_facing_mark.position = Vector2(facing) * 7 - Vector2(2, 2)


func _try_move(dir: Vector2i) -> void:
	var target := cell + dir
	if grid.is_solid(target):
		return
	_moving = true
	cell = target
	var tw := create_tween()
	tw.tween_property(self, "position", grid.cell_to_world(cell), MOVE_TIME)
	await tw.finished
	_moving = false
	moved.emit(cell)
