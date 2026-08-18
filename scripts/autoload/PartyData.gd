extends Node
## パーティ(仲間)のステータス・所持品を保持するシングルトン。
## MVPでは主人公とセレナのみ扱う。カイル/リリアは後の章で追加予定。

signal member_joined(member_id: String)
signal gold_changed(new_gold: int)
signal party_hp_changed()

var gold: int = 50
var inventory: Dictionary = {} # item_id -> 個数

var members: Dictionary = {}
var active_party: Array[String] = []

const DEFAULT_MEMBERS := {
	"hero": {
		"name": "勇者",
		"level": 1,
		"hp": 30, "max_hp": 30,
		"mp": 5, "max_mp": 5,
		"atk": 8, "def": 4,
		"skills": ["attack", "guard"],
	},
	"serena": {
		"name": "セレナ",
		"level": 1,
		"hp": 20, "max_hp": 20,
		"mp": 15, "max_mp": 15,
		"atk": 3, "def": 3,
		"skills": ["attack", "heal", "guard"],
	},
}


func _ready() -> void:
	reset_to_default()


func reset_to_default() -> void:
	gold = 50
	inventory = {"potion": 2}
	members.clear()
	for id in DEFAULT_MEMBERS.keys():
		members[id] = DEFAULT_MEMBERS[id].duplicate(true)
	active_party = ["hero"]


func set_hero_name(new_name: String) -> void:
	if members.has("hero"):
		members["hero"]["name"] = new_name


func hero_name() -> String:
	return String(members.get("hero", {}).get("name", "勇者"))


func add_member(member_id: String) -> void:
	if not active_party.has(member_id):
		active_party.append(member_id)
		member_joined.emit(member_id)


func get_active_members() -> Array:
	var result := []
	for id in active_party:
		if members.has(id):
			result.append(members[id])
	return result


func is_party_wiped() -> bool:
	for id in active_party:
		if members.has(id) and int(members[id].get("hp", 0)) > 0:
			return false
	return true


func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	gold_changed.emit(gold)


func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount


func remove_item(item_id: String, amount: int = 1) -> bool:
	var have := int(inventory.get(item_id, 0))
	if have < amount:
		return false
	inventory[item_id] = have - amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true


func heal_full_party() -> void:
	for id in active_party:
		if members.has(id):
			members[id]["hp"] = members[id]["max_hp"]
			members[id]["mp"] = members[id]["max_mp"]
	party_hp_changed.emit()
