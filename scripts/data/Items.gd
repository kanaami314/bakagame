class_name Items
extends RefCounted
## アイテム定義の一覧。店の品揃えや装備の性能はここだけを見れば分かるようにする。
##
## ※ 品目・価格・性能は未承認のドラフトである。docs/王都ドラフト.md を参照。
##
## type:
##   consumable … 使うと無くなる
##   weapon / armor / accessory … 装備できる。equip_slot と同じ文字列を使う
## equippable: 装備できる仲間のID。空なら全員

const DATA := {
	# ---- 消耗品 ----
	"potion": {
		"name": "ポーション", "type": "consumable", "price": 10,
		"heal_hp": 15,
		"desc": "傷を癒す薬。HPを15回復する。",
	},
	"ether": {
		"name": "エーテル", "type": "consumable", "price": 30,
		"heal_mp": 8,
		"desc": "精神を静める薬。MPを8回復する。",
	},
	"antidote": {
		"name": "解毒草", "type": "consumable", "price": 8,
		"cure_poison": true,
		"desc": "毒を消す薬草。",
	},

	# ---- 武器 ----
	"traveler_sword": {
		"name": "旅人の剣", "type": "weapon", "price": 0,
		"atk": 2,
		"desc": "支給された使い古しの剣。無いよりはまし。",
	},
	"bronze_sword": {
		"name": "ブロンズソード", "type": "weapon", "price": 90,
		"atk": 6,
		"desc": "青銅の剣。王都の鍛冶で広く出回っている。",
	},
	"knight_sword": {
		"name": "騎士の剣", "type": "weapon", "price": 260,
		"atk": 12,
		"desc": "王国騎士団の制式剣。手入れが行き届いている。",
	},
	"oak_staff": {
		"name": "樫の杖", "type": "weapon", "price": 70,
		"atk": 3, "equippable": ["serena"],
		"desc": "神官が儀式に用いる杖。祈りを助ける。",
	},
	"silver_staff": {
		"name": "銀の杖", "type": "weapon", "price": 220,
		"atk": 6, "equippable": ["serena"],
		"desc": "銀を編んだ杖。七神への祈りをよく通す。",
	},

	# ---- 防具 ----
	"cloth_armor": {
		"name": "旅装", "type": "armor", "price": 0,
		"def": 1,
		"desc": "ただの旅の服。動きやすさだけが取り柄。",
	},
	"leather_armor": {
		"name": "革の鎧", "type": "armor", "price": 80,
		"def": 5,
		"desc": "なめし革の鎧。軽く、値段も手ごろ。",
	},
	"chain_mail": {
		"name": "鎖かたびら", "type": "armor", "price": 240,
		"def": 10,
		"desc": "鉄の輪を編んだ鎧。重いが頼りになる。",
	},
	"priest_robe": {
		"name": "神官衣", "type": "armor", "price": 100,
		"def": 4, "equippable": ["serena"],
		"desc": "七神教会の神官が纏う衣。清められている。",
	},

	# ---- アクセサリ ----
	"leather_band": {
		"name": "革の腕輪", "type": "accessory", "price": 60,
		"atk": 1, "def": 1,
		"desc": "腕を締める革の輪。少しだけ体が軽くなる。",
	},
	"seven_charm": {
		"name": "七神の護符", "type": "accessory", "price": 150,
		"def": 3,
		"desc": "七神を象った護符。旅の無事を願うもの。",
	},
}


static func get_item(item_id: String) -> Dictionary:
	return DATA.get(item_id, {})


static func item_name(item_id: String) -> String:
	return String(DATA.get(item_id, {}).get("name", item_id))


static func item_type(item_id: String) -> String:
	return String(DATA.get(item_id, {}).get("type", ""))


static func price(item_id: String) -> int:
	return int(DATA.get(item_id, {}).get("price", 0))


static func description(item_id: String) -> String:
	return String(DATA.get(item_id, {}).get("desc", ""))


static func is_equipment(item_id: String) -> bool:
	return item_type(item_id) in ["weapon", "armor", "accessory"]


## その仲間が装備できるか。equippable の指定が無ければ誰でも装備できる。
static func can_equip(item_id: String, member_id: String) -> bool:
	var item := get_item(item_id)
	if item.is_empty():
		return false
	if not item.has("equippable"):
		return true
	return (item["equippable"] as Array).has(member_id)


static func stat_of(item_id: String, stat: String) -> int:
	return int(DATA.get(item_id, {}).get(stat, 0))
