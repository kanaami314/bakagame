extends MapControllerBase
## 第1章: 試練の遺跡。初見殺し2種(宝箱の落とし穴/帰り道の待ち伏せ)を体験できる最小ダンジョン。

## 宝物庫(北)と入口(南)を、幅1マスの関門(10,7)だけでつないでいる。
## こうしないと帰り道の待ち伏せを横から回避できてしまい、初見殺しが成立しない。
const LAYOUT: PackedStringArray = [
	"WWWWWWWWWWWWWWWWWWWW",
	"W__________________W",
	"W__________________W",
	"W__P____________P__W",
	"W__________________W",
	"W__________________W",
	"WWWWWWWWWW_WWWWWWWWW",
	"W__________________W",
	"WWWWWWWWWW_WWWWWWWWW",
	"W__________________W",
	"W____P_______P_____W",
	"W__________________W",
	"W__________________W",
	"WWWWWWWWWW_WWWWWWWWW",
]

const OBJECTS: Array = [
	{"type": "marker", "cell": Vector2i(10, 12), "id": "start"},
	{"type": "door", "cell": Vector2i(10, 13), "target_scene": "res://scenes/maps/Town.tscn", "target_spawn": "from_dungeon"},
	{
		"type": "sign", "cell": Vector2i(12, 10), "name": "古い石碑", "solid": true,
		"lines": [
			"《この先、強敵の気配あり。油断するな》",
			"――遺跡の見張りが遺したという文字が刻まれている。",
		],
	},
	{
		"type": "chest", "cell": Vector2i(5, 5), "id": "chest_pitfall", "trap_id": "chest_pitfall",
		"solid": true,
		"open_lines": ["粗末な木箱だ。", "蓋を開けると、中は空っぽだった。"],
		"hint_line": "(……この箱、前に開けたときは床が抜けた気がする)",
		"collapse_after": true,
		"trap_message": "突然、足元の床が抜けた!",
	},
	{
		"type": "chest", "cell": Vector2i(10, 2), "id": "dungeon_treasure", "solid": true,
		"open_lines": ["古びた宝箱だ。鍵はかかっていない。"],
		"loot_item": "名もなき紋章", "loot_amount": 1, "loot_gold": 30,
		"flag_on_open": "dungeon_treasure_taken",
	},
	{
		"type": "trap_step", "cell": Vector2i(10, 7), "id": "corridor_ambush", "kind": "battle",
		"requires_flag": "dungeon_treasure_taken",
		"enemy": {
			"id": "ambush_brute", "name": "待ち伏せの魔物",
			"hp": 40, "max_hp": 40, "atk": 9, "def": 2,
			"gold_reward": 25, "can_flee": false,
			"intro": "帰り道――背後の暗がりから、何かが飛び出してきた!",
			"flee_blocked_message": "退路を断たれている! 逃げられない!",
			"lose_message": "……気づけば、目の前が暗くなっていた。",
		},
	},
]


func _get_layout() -> PackedStringArray:
	return LAYOUT


func _get_objects() -> Array:
	return OBJECTS
