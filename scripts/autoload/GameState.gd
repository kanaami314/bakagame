extends Node
## 死亡・リトライ・記憶(フラグ)・チェックポイントを管理するシングルトン。
##
## 設定上の建前: 死神が「死」を確定する前に、時空神の権能で直前のチェック
## ポイント時点の状態へ周囲ごと復元する。ただし主人公の記憶だけは保持される。
## 実装上は「シーンを再読み込みして部屋の状態を丸ごとリセットしつつ、
## GameState (このシングルトン) に貯めたフラグ/死亡回数だけは残す」ことで
## その建前をそのまま再現している。

const FADE_OUT_TIME := 0.35
const FADE_IN_TIME := 0.35
const DEATH_MESSAGE_HOLD := 0.9

var current_scene_path: String = ""
var checkpoint_spawn_id: String = "start"

var flags: Dictionary = {}
var death_count_total: int = 0
var death_log: Dictionary = {} # cause_id -> 回数

var _is_transitioning: bool = false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()


func _build_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)

	_fade_label = Label.new()
	_fade_label.set_anchors_preset(Control.PRESET_CENTER)
	_fade_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	_fade_label.add_theme_font_size_override("font_size", 14)
	_fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade_label.visible = false
	_fade_layer.add_child(_fade_label)


func set_checkpoint(scene_path: String, spawn_id: String) -> void:
	current_scene_path = scene_path
	checkpoint_spawn_id = spawn_id
	EventBus.checkpoint_set.emit(spawn_id)


## 主人公の死亡を記録し、チェックポイントまで高速リトライする。
## cause_id: どの罠/敵で死んだかを示す識別子(例: "chest_pitfall")。
##           以後 has_died_from(cause_id) で「経験済みか」を判定できる。
func die(cause_id: String, message: String = "") -> void:
	if _is_transitioning:
		return
	death_count_total += 1
	death_log[cause_id] = int(death_log.get(cause_id, 0)) + 1
	flags["died_" + cause_id] = true
	# 復元されるのは「チェックポイント時点の状態」なので、HP/MPも巻き戻る。
	# ここを巻き戻さないと、一度全滅した時点で以後どの戦闘も即敗北になり詰む。
	PartyData.heal_full_party()
	EventBus.player_died.emit(cause_id, message)
	_retry_sequence(message)


func has_died_from(cause_id: String) -> bool:
	return bool(flags.get("died_" + cause_id, false))


func death_count_for(cause_id: String) -> int:
	return int(death_log.get(cause_id, 0))


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))


func _retry_sequence(message: String) -> void:
	await _fade_and_switch(current_scene_path, message)
	EventBus.player_retried.emit()


## 通常の画面遷移(扉など)。死亡ではないのでメッセージは基本空。
func travel_to(scene_path: String, spawn_id: String) -> void:
	set_checkpoint(scene_path, spawn_id)
	await _fade_and_switch(scene_path, "")


func _fade_and_switch(target_scene: String, message: String) -> void:
	_is_transitioning = true
	get_tree().paused = true

	var tree := get_tree()

	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_OUT_TIME)
	await tw.finished

	if message != "":
		_fade_label.text = message
		_fade_label.visible = true
		await tree.create_timer(DEATH_MESSAGE_HOLD, true, false, true).timeout
	_fade_label.visible = false

	tree.paused = false
	tree.change_scene_to_file(target_scene)
	await tree.process_frame
	await tree.process_frame

	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, FADE_IN_TIME)
	await tw2.finished

	_is_transitioning = false


func start_new_game() -> void:
	flags.clear()
	death_count_total = 0
	death_log.clear()
	checkpoint_spawn_id = "start"
	PartyData.reset_to_default()
