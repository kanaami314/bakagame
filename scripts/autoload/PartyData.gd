extends Node
## パーティ(仲間)のステータス・所持品を保持するシングルトン。
## MVPでは主人公とセレナのみ扱う。カイル/リリアは後の章で追加予定。

signal member_joined(member_id: String)
signal gold_changed(new_gold: int)
signal party_hp_changed()
signal equipment_changed(member_id: String)

const EQUIP_SLOTS := ["weapon", "armor", "accessory"]
const SLOT_LABELS := {"weapon": "武器", "armor": "防具", "accessory": "装飾品"}

var gold: int = 50
var inventory: Dictionary = {} # item_id -> 個数

var members: Dictionary = {}
var active_party: Array[String] = []
## member_id -> {weapon/armor/accessory: item_id}。空文字は未装備。
var equipment: Dictionary = {}

## atk / def は装備を含まない素の値。実際の値は total_atk / total_def で求める。
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

const DEFAULT_EQUIPMENT := {
	"hero": {"weapon": "traveler_sword", "armor": "cloth_armor", "accessory": ""},
	"serena": {"weapon": "oak_staff", "armor": "priest_robe", "accessory": ""},
}


func _ready() -> void:
	reset_to_default()


func reset_to_default() -> void:
	gold = 50
	inventory = {"potion": 2}
	members.clear()
	for id in DEFAULT_MEMBERS.keys():
		members[id] = DEFAULT_MEMBERS[id].duplicate(true)
	equipment.clear()
	for id in DEFAULT_EQUIPMENT.keys():
		equipment[id] = DEFAULT_EQUIPMENT[id].duplicate(true)
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


## ---------------- 装備 ----------------

func equipped(member_id: String, slot: String) -> String:
	return String(equipment.get(member_id, {}).get(slot, ""))


## 装備している品の合計値。stat は "atk" か "def"。
func equip_bonus(member_id: String, stat: String) -> int:
	var total := 0
	for slot in EQUIP_SLOTS:
		var item_id := equipped(member_id, slot)
		if item_id != "":
			total += Items.stat_of(item_id, stat)
	return total


func total_atk(member_id: String) -> int:
	return int(members.get(member_id, {}).get("atk", 0)) + equip_bonus(member_id, "atk")


func total_def(member_id: String) -> int:
	return int(members.get(member_id, {}).get("def", 0)) + equip_bonus(member_id, "def")


## 持ち物の装備品を身につける。外した品は持ち物へ戻る。
func equip(member_id: String, item_id: String) -> bool:
	if not Items.is_equipment(item_id) or not Items.can_equip(item_id, member_id):
		return false
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	var slot := Items.item_type(item_id)
	var previous := equipped(member_id, slot)
	remove_item(item_id, 1)
	if previous != "":
		add_item(previous, 1)
	if not equipment.has(member_id):
		equipment[member_id] = {}
	equipment[member_id][slot] = item_id
	equipment_changed.emit(member_id)
	return true


func unequip(member_id: String, slot: String) -> bool:
	var item_id := equipped(member_id, slot)
	if item_id == "":
		return false
	equipment[member_id][slot] = ""
	add_item(item_id, 1)
	equipment_changed.emit(member_id)
	return true


## 持ち物のうち、その仲間がその箇所に装備できるものを列挙する。
func equippable_items(member_id: String, slot: String) -> Array:
	var result: Array = []
	for item_id in inventory.keys():
		if Items.item_type(item_id) == slot and Items.can_equip(item_id, member_id):
			result.append(item_id)
	result.sort()
	return result


func heal_full_party() -> void:
	for id in active_party:
		if members.has(id):
			members[id]["hp"] = members[id]["max_hp"]
			members[id]["mp"] = members[id]["max_mp"]
	party_hp_changed.emit()
