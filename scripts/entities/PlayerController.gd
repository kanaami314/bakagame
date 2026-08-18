class_name PlayerController
extends Node2D
## グリッド単位で移動する見下ろし型プレイヤー。マップ側が grid を渡してセットアップする。

signal moved(cell: Vector2i)
signal interact_pressed(facing_cell: Vector2i)

const MOVE_TIME := 0.11
const TUNIC := Color("3f6fc4")
const HAIR := Color("caa14a")

var grid: TileGrid
var cell: Vector2i
var facing: Vector2i = Vector2i.DOWN
var input_locked: bool = false

var _moving: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)
	_update_sprite()


func setup(p_grid: TileGrid, start_cell: Vector2i) -> void:
	grid = p_grid
	cell = start_cell
	position = grid.cell_to_world(cell)


## 決定キーだけはイベントとして受け取る。
##
## Input.is_action_just_pressed() はグローバルな入力状態の問い合わせなので、
## 会話ウィンドウが set_input_as_handled() で消費したキーもそのまま拾えてしまう。
## その結果、会話の最終行を閉じた同じ押下でもう一度話しかけてしまい、
## 会話から永久に抜け出せなくなる。_unhandled_input なら消費済みのキーは届かない。
func _unhandled_input(event: InputEvent) -> void:
	if _moving or input_locked or Dialogue.is_active() or BattleSystem.is_active():
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		interact_pressed.emit(cell + facing)


func _process(_delta: float) -> void:
	if _moving or input_locked or Dialogue.is_active() or BattleSystem.is_active():
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
	_update_sprite()
	_try_move(dir)


func _update_sprite() -> void:
	var dir_name := "down"
	if facing == Vector2i.UP:
		dir_name = "up"
	elif facing == Vector2i.LEFT:
		dir_name = "left"
	elif facing == Vector2i.RIGHT:
		dir_name = "right"
	_sprite.texture = TileArt.character(dir_name, TUNIC, HAIR)


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
